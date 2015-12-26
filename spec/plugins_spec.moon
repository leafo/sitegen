
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
      ]]
    }

    page\render!
    assert.same [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#second-header">Second header</a></li></ul></ul><h1 id="first-header">First header</h1><h2 id="second-header">Second header</h2>]], flatten_html page._inner_content

  it "indexes a page when passing index: true", ->
    page = factory.Page {
      meta: {
        index: true
      }
      render_fn: -> [[
        <h1>First header</h1>
        <h2>Second header</h2>
      ]]
    }

    page\render!
    assert.same [[<h1 id="first-header">First header</h1><h2 id="second-header">Second header</h2>]],
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
    assert.same [[<ul><li><a href="#first-header">First header</a></li><ul><li><a href="#second-header">Second header</a></li></ul></ul><h1><a name="first-header" href="#first-header">First header</a></h1><h2><a name="second-header" href="#second-header">Second header</a></h2>]],
      flatten_html page._inner_content
