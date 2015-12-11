
describe "html", ->
  it "renders some html", ->
    html = require "sitegen.html"
    out = html.build ->
      div { "hello world", class: "yeah" }

    assert.same '<div class="yeah">hello world</div>', out

  describe "with sorted attributes", ->
    local html

    setup ->
      package.loaded.html = nil
      html = require "sitegen.html"
      html.sort_attributes true

    teardown ->
      package.loaded.html = nil

    it "renders some html with attributes", ->
      out = html.build ->
        div class: "yeah", good: "world", id: "okay", one: "two", three: "yeah"
      assert.same [[<div class="yeah" good="world" id="okay" one="two" three="yeah"></div>]], out

    it "renders nested html", ->
      out = html.build ->
        div {
          class: "cool"
          -> span "yeah"
        }

      assert.same [[<div class="cool"><span>yeah</span></div>]], out

    it "renders nested cdata", ->
      out = html.build ->
        cdata "good ol cdata"

      assert.same [=[<![CDATA[good ol cdata]]>]=], out

    it "renders text", ->
      out = html.build ->
        text "Great's going > <"

      assert.same [[Great's going > <]], out

    it "renders select", ->
      out = html.build ->
        tag["select"] {
          option "one"
          option "two"
          option "three"
        }

      assert.same [[<select><option>one</option>
<option>two</option>
<option>three</option></select>]], out




