
html = require "sitegen.html"

describe "html", ->
  it "should render some html", ->
    out = html.build ->
      div { "hello world", class: "yeah" }
   
    assert.same '<div class="yeah">hello world</div>', out
