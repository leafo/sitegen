
factory = require "spec.factory"

HTMLRenderer = require "sitegen.renderers.html"

import trim from require "sitegen.common"

flatten_html = (html) ->
  trim (html\gsub "%>%s+%<", "><")

describe "sitegen.plugins.indexer", ->
  it "indexes a page when using $index", ->
    page = factory.Page {
      render_fn: HTMLRenderer\load [[
        $index
        <h1>First header</h1>
        <h2>Second header</h2>
        <h3>Third header</h3>
        <h2>Another first header</h3>
      ]]
    }

    page\render!
    assert.same [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#first-header/second-header">Second header</a></li><ul><li><a href="#first-header/second-header/third-header">Third header</a></li></ul><li><a href="#first-header/another-first-header">Another first header</h3></a></li></ul></ul><h1 id="first-header">First header</h1><h2 id="first-header/second-header">Second header</h2><h3 id="first-header/second-header/third-header">Third header</h3><h2 id="first-header/another-first-header">Another first header</h3>]],
      flatten_html page._inner_content

  it "indexes a page when passing index: true", ->
    page = factory.Page {
      meta: {
        index: true
      }
      render_fn: -> [[
        <h2>First header</h2>
        <h3>Second header</h3>
        <h2>another header</h2>
      ]]
    }

    page\render!
    assert.same [[<h2 id="first-header">First header</h2><h3 id="first-header/second-header">Second header</h3><h2 id="another-header">another header</h2>]],
      flatten_html page._inner_content

  it "indexes page with anchors instead of id", ->
    page = factory.Page {
      meta: {
        index: {
          link_headers: true
        }
      }
      render_fn: HTMLRenderer\load [[
        $index
        <h1>First header</h1>
        <h2>Second header</h2>
      ]]
    }

    page\render!

    valid = {v, true for v in *{
      [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#first-header/second-header">Second header</a></li></ul></ul><h1><a href="#first-header" name="first-header">First header</a></h1><h2><a href="#first-header/second-header" name="first-header/second-header">Second header</a></h2>]]
      [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#first-header/second-header">Second header</a></li></ul></ul><h1><a name="first-header" href="#first-header">First header</a></h1><h2><a href="#first-header/second-header" name="first-header/second-header">Second header</a></h2>]]

      [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#first-header/second-header">Second header</a></li></ul></ul><h1><a href="#first-header" name="first-header">First header</a></h1><h2><a href="#first-header/second-header" name="first-header/second-header">Second header</a></h2>]]
      [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#first-header/second-header">Second header</a></li></ul></ul><h1><a name="first-header" href="#first-header">First header</a></h1><h2><a name="first-header/second-header" href="#first-header/second-header">Second header</a></h2>]]
    }}

    assert.true valid[flatten_html page._inner_content]


  it "indexes with custom slugify", ->
    page = factory.Page {
      meta: {
        index: {
          slugify: (header) ->
            header.title\gsub("%W", "")\upper!
        }
      }
      render_fn: -> [[
        <h1>First header</h1>
        <h2>Second header</h2>
      ]]
    }

    page\render!
    assert.same [[<h1 id="FIRSTHEADER">First header</h1><h2 id="FIRSTHEADER/SECONDHEADER">Second header</h2>]],
      flatten_html page._inner_content


describe "sitegen.plugins.syntaxhighlight", ->
  local site, sh
  before_each ->
    site = factory.Site {}
    sh = require("sitegen.plugins.syntaxhighlight")

  it "syntax highlights some code", ->
    plugin = sh site
    out = flatten_html plugin\filter [[
```lua
print("hello world")
```]]

    assert.same [[<pre class="highlight lang_lua"><code><span class="sh_function">print</span><span class="sh_operator">(</span><span class="sh_string">&quot;hello world&quot;</span><span class="sh_operator">)</span></code></pre>]], out


  it "doesnt highlight code inside of a cosmo template", ->
    plugin = sh site
    out = flatten_html plugin\filter [=[
```lua
print 5
```

$hello{[[
  ```lua
  print thing
  ```
]]}]=]

    assert.same [=[<pre class="highlight lang_lua"><code><span class="sh_function">print</span><span class="sh_number">5</span></code></pre>

$hello{[[
  ```lua
  print thing
  ```
]]}]=], out

  it "uses custom highlighter in place of default output", ->
    plugin = sh site
    plugin.custom_highlighters = {
      moon: (code, page) =>
        "<div>#{@highlight "moon", code}</div>"
    }

    out = flatten_html plugin\filter [[
```moon
print 5
```]]

    assert.same [[<div><span class="sh_function">print</span><span class="sh_number">5</span></div>]], out

  it "highlights when called on the class", ->
    assert.same [[<span class="sh_function">print</span> <span class="sh_number">5</span>]],
      sh\highlight "moon", "print 5"

  it "resolves language aliases to lexers", ->
    for {alias, lang, code} in *{
      {"js", "javascript", "var x = 1"}
      {"scss", "sass", ".a { b { color: red; } }"}
    }
      out = sh\highlight alias, code
      assert.same sh\highlight(lang, code), out
      assert.truthy out\match "sh_"

describe "sitegen.site plugins", ->
  it "highlights with syntaxhighlight by default", ->
    site = factory.Site {}
    plugin = site\get_plugin "sitegen.plugins.pygments"
    assert.falsy plugin

    _, out = site.events\pipe "renderer.markdown.pre_render", {}, [[
```lua
print 5
```]]

    assert.same [[<pre class="highlight lang_lua"><code><span class="sh_function">print</span><span class="sh_number">5</span></code></pre>]],
      flatten_html out

  it "replaces syntaxhighlight with pygments", ->
    site = factory.Site {}
    assert.truthy site\remove_plugin "sitegen.plugins.syntaxhighlight"
    plugin = site\get_plugin "sitegen.plugins.syntaxhighlight"
    assert.falsy plugin

    -- a custom highlighter avoids needing pygmentize installed
    pygments = site\add_plugin "sitegen.plugins.pygments"
    pygments.custom_highlighters = {
      lua: (code) => "<pygments>#{code}</pygments>"
    }

    _, out = site.events\pipe "renderer.markdown.pre_render", {}, [[
```lua
print 5
```]]

    assert.same [[<pygments>print 5
</pygments>]], out

  it "removes nothing for a plugin that isn't added", ->
    site = factory.Site {}
    removed = site\remove_plugin "sitegen.plugins.tupfile"
    assert.falsy removed

describe "sitegen.plugins.pygments", ->
  it "caches custom highlighter output", ->
    site = factory.Site {}
    plugin = site\add_plugin "sitegen.plugins.pygments"

    calls = 0
    plugin.custom_highlighters = {
      cached: (code, page) =>
        calls += 1
        "<div>#{code}</div>"
    }

    for i=1,2
      assert.same "<div>cache me\n</div>", plugin\filter "```cached\ncache me\n```"

    assert.same 1, calls

describe "sitegen.highlight_plugin", ->
  it "keeps custom highlighters separate for each plugin", ->
    import HighlightPlugin from require "sitegen.highlight_plugin"
    pygments = require "sitegen.plugins.pygments"
    syntaxhighlight = require "sitegen.plugins.syntaxhighlight"

    assert.not.equal pygments.custom_highlighters, syntaxhighlight.custom_highlighters
    assert.not.equal HighlightPlugin.custom_highlighters, pygments.custom_highlighters

  describe "warn_unused_custom_highlighters", ->
    import HighlightPlugin from require "sitegen.highlight_plugin"
    local pygments, site, warnings

    before_each ->
      pygments = require "sitegen.plugins.pygments"
      pygments.custom_highlighters.cool_lang = (code) => code

      site = factory.Site {}
      warnings = {}
      site.logger = { warn: (msg) => table.insert warnings, msg }

    after_each ->
      pygments.custom_highlighters.cool_lang = nil

    it "warns about highlighters on a plugin that isn't loaded", ->
      HighlightPlugin\warn_unused_custom_highlighters site
      assert.same {
        "PygmentsPlugin.custom_highlighters has highlighters for cool_lang but the plugin isn't loaded, they will not be used"
      }, warnings

    it "doesn't warn when the plugin is loaded", ->
      site\add_plugin "sitegen.plugins.pygments"
      HighlightPlugin\warn_unused_custom_highlighters site
      assert.same {}, warnings
