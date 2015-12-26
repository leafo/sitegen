
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
    assert.same [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#second-header">Second header</a></li></ul></ul><h1 id="first-header">First header</h1><h2 id="second-header">Second header</h2>]], flatten_html page._inner_content

