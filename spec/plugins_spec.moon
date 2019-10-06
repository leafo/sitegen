
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
  it "syntax highlights some code", ->
    site = factory.Site {}

    sh = require("sitegen.plugins.syntaxhighlight")
    plugin = sh site
    out = flatten_html plugin\filter [[
```lua
print("hello world")
```]]

    assert.same [[<pre class="highlight lang_lua"><code><span class="sh_function">print</span><span class="sh_operator">(</span><span class="sh_string">&quot;hello world&quot;</span><span class="sh_operator">)</span></code></pre>]], out

