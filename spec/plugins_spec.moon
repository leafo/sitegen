
factory = require "spec.factory"

HTMLRenderer = require "sitegen.renderers.html"

import trim from require "sitegen.common"

flatten_html = (html) ->
  trim (html\gsub "%>%s+%<", "><")

describe "sitegen.plugins.indexer", ->
  it "should index a page", ->
    page = factory.Page {
      render_fn: HTMLRenderer\load [[
        $index
        <h1>First header</h1>
        <h2>Second header</h2>
      ]]
    }

    page\render!
    assert.same [[<ul><li><a href="#first_header">First header</a></li><ul><li><a href="#second_header">Second header</a></li></ul></ul><h1><a name="first_header"></a>First header</h1><h2><a name="second_header"></a>Second header</h2>]], flatten_html page._inner_content

describe "sitegen.plugins.indexer2", ->
  it "should index a page #ddd", ->
    page = factory.Page {
      render_fn: (page) ->
        [[
          <h1>First header</h1>
          <h2>Second header</h2>
        ]]
    }

    page.site\add_plugin "sitegen.plugins.indexer2"
    page\render!
    assert.same [[<h1 id="first_header">First header</h1><h2 id="second_header">Second header</h2>]], flatten_html page._inner_content

