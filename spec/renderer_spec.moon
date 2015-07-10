factory = require "spec.factory"

describe "renderers", ->
  render_for_site = (site, renderer, str, meta={}, page) ->
    page or= factory.Page(:site)
    page.render_fn, page.meta = renderer\load str
    page.meta.template = false
    for k,v in pairs meta
      page.meta[k] = v
    page\render!

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

      it "renders each", ->
        assert.same "thing: 1, thing: 2, thing: 3, ",
          render '$each{{1,2,3}, "thing"}[[thing: $thing, ]]'

      it "renders eq", ->
        assert.same "no yes ",
          render '$eq{1,2}[[yes]][[no]] $eq{2,2}[[yes]][[no]] $eq{1,2}[[yes]]'

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

