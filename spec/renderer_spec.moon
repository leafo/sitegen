factory = require "spec.factory"

describe "renderers", ->
  render_for_site = (site, renderer, str, meta={}, page) ->
    page or= factory.Page(:site)
    page.render_fn, page.meta = renderer\load str
    page.meta.template = false
    for k,v in pairs meta
      page.meta[k] = v
    page\render!

  describe "renderers.moon", ->
    local site, renderer

    render = (...) -> render_for_site site, renderer, ...

    before_each ->
      MoonRenderer = require "sitegen.renderers.moon"
      site = factory.Site!
      renderer = MoonRenderer site

    it "renders some raw text", ->
      assert.same 'what the heck', render "write 'what the heck'"

    it "renders with html helper from default formatter", ->
      assert.same '<div color="blue">you smell</div>', render [[
html ->
  div { color: "blue", "you smell" }
]]

  describe "renderers.html", ->
    local site, renderer

    before_each ->
      HTMLRenderer = require "sitegen.renderers.html"
      site = factory.Site!
      renderer = HTMLRenderer site

    render = (...) -> render_for_site site, renderer, ...

    it "renders basic string", ->
      assert.same "hello!", render "hello!"

    describe "cosmo helpers", ->
      it "renders if", ->
        assert.same "we have a val set",
          render '$if{"val"}[[we have a val set]]$if{"nope"}[[nope]]', {
          val: "yes"
        }

      it "renders unless", ->
        assert.same "nope",
          render '$unless{"val"}[[we have a val set]]$unless{"nope"}[[nope]]', {
          val: "yes"
        }

      it "renders each", ->
        assert.same "thing: 1, thing: 2, thing: 3, ",
          render '$each{{1,2,3}, "thing"}[[thing: $thing, ]]'

      it "renders eq", ->
        assert.same "no yes ",
          render '$eq{1,2}[[yes]][[no]] $eq{2,2}[[yes]][[no]] $eq{1,2}[[yes]]'

      it "renders markdown via helper", ->
        out = render [==[<h2>All Guides</h2>
$markdown{[[
* [Getting Started]($root/reference/getting_started.html)
  * [Getting Started With MoonScript]($root/reference/moon_getting_started.html)
  * [Getting Started With Lua]($root/reference/lua_getting_started.html)
]]}]==]

        assert.same out, [[<h2>All Guides</h2>
<ul>
<li><a href="./reference/getting_started.html">Getting Started</a>

<ul>
<li><a href="./reference/moon_getting_started.html">Getting Started With MoonScript</a></li>
<li><a href="./reference/lua_getting_started.html">Getting Started With Lua</a></li>
</ul>
</li>
</ul>

]]


      it "renders url_for", ->
        factory.Page(:site, meta: {id: "cool"})
        p = factory.Page {
          :site
          target: "www/other_cool.html"
          meta: {id: "other_cool"}
        }

        assert.same "./other_cool.html",
          render '$url_for{id = "other_cool"}'

        -- does relative url correctly
        assert.same "../../other_cool.html",
          render '$url_for{id = "other_cool"}', {}, factory.Page {
            :site
            target: "www/yeah/good/stuff.html"
          }

      it "renders query_pages", ->
        factory.Page(:site, meta: {type: "1", title: "Interesting page title"})
        factory.Page(:site, meta: {type: "1", title: "Another page title"})
        factory.Page(:site, meta: {type: "3", title: "Not interesting post"})

        assert.same "Interesting page title,Another page title,",
          render '$query_pages{type = "1"}[[$title,]]'

      it "renders query_pages", ->
        factory.Page(:site, meta: {id: "1", title: "A"})
        factory.Page(:site, meta: {id: "2", title: "B"})
        factory.Page(:site, meta: {id: "3", title: "C"})

        assert.same "B", render '$query_pages{id = "2"}[[$title]]'

      it "renders a user var", ->
        site.user_vars.hello = "zone"
        site.user_vars.world = (page, arg) ->
          page.target\gsub "%d+", "XX"

        assert.same "hello: zone, world: www/some_page_XX.html", render "hello: $hello, world: $world{}"

      it "renders comsmo with complex markup", ->
        site.user_vars.thing = (page, arg) ->
          assert.same {
            markup: [[


              Hello world
              ```lua
              world
              ```
            ]]
          }, arg
          "ok"

        assert.same "ok", render [=[$thing{
            markup = [[
              Hello world
              ```lua
              world
              ```
            ]]
          }]=]


  describe "renderers.markdown", ->
    local site, renderer
    before_each ->
      MarkdownRenderer = require "sitegen.renderers.markdown"
      site = factory.Site!
      renderer = MarkdownRenderer site

    render = (...) -> render_for_site site, renderer, ...

    it "renders preserves cosmo", ->
      assert.same "<p>yes</p>\n",
        render '$if{"val"}[[yes]]', { val: "yes" }

    for {str} in *{
      {"hello $one zone"}
      {"hello $one{} zone"}
      {"hello $one{1,2,3,4,5,6} zone"}
      {"hello $one{'be string aware }'} zone"}
      {[[hello $one{yes = "no", 5} zone]]}

      {[[hello $one{"be string aware }"} zone]]}
      {'hello $one{one = [[a } here]]} zone'}

      {[[hello $one{
        color = {
          5, blue = 'okay'
        }
      } zone]]}
    }
      import escape_cosmo, unescape_cosmo from require "sitegen.renderers.markdown"

      it "escapes and unescapes cosmo", ->
        escaped = escape_cosmo str
        assert.same escaped,
          "hello 0000sitegen_markdown00dollar0000.1 zone"
        assert.same str, (unescape_cosmo escape_cosmo str)

