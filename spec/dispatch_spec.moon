import Dispatch from require "sitegen.dispatch"

describe "sitegen.dispatch", ->
  describe "structure", ->
    local d, default_structure
    before_each ->
      d = Dispatch!

      d\on "page", 1
      d\on "page", 2
      d\on "page.flour", 3
      d\on "page.flour.zone", 4

      default_structure = {
        page: {
          1
          2
          flour: {
            3
            zone: {
              4
            }
          }
        }
      }

    it "should create a dispatch", ->
      assert.same default_structure, d.callbacks

    it "matches callbacks", ->
      assert.same {1,2}, d\callbacks_for "page"
      assert.same {1,2}, d\callbacks_for "page.dirt"
      assert.same {1,2,3}, d\callbacks_for "page.flour"
      assert.same {1,2,3}, d\callbacks_for "page.flour.more"
      assert.same {1,2,3,4}, d\callbacks_for "page.flour.zone"
      assert.same {1,2,3,4}, d\callbacks_for "page.flour.zone.dad"

    describe "off", ->
      it "removes entire tree", ->
        d\off "page"
        assert.same {}, d.callbacks

      it "removes subset", ->
        d\off "page.flour"
        assert.same {
          page: {
            1
            2
          }
        }, d.callbacks

      it "removes nothing", ->
        d\off "page.wowza"
        assert.same default_structure, d.callbacks

  describe "callbacks", ->
    it "runs two callbacks", ->
      out = {}

      d = Dispatch!
      d\on "cool", ->
        table.insert out, "one"

      d\on "cool", ->
        table.insert out, "two"

      d\trigger "cool"

      assert.same {"one", "two"}, out

    it "runs two cancels second callback", ->
      out = {}

      d = Dispatch!
      d\on "cool", =>
        @cancel = true
        table.insert out, "one"

      d\on "cool", =>
        table.insert out, "two"

      d\trigger "cool"

      assert.same {"one"}, out

  describe "pipe", ->
    it "pipes with no callbacks", ->
      d = Dispatch!
      assert.same {
        "yeah"
        4
      }, {
        d\pipe "hello.world", "yeah", 4
      }

    it "pipes with one callback", ->
      d = Dispatch!
      d\on "add", (e, number) ->
        number + 5
      assert.same {7}, { d\pipe "add", 2 }

    it "pipes with two callbacks, multi args", ->
      d = Dispatch!

      d\on "double", (e, number, string) ->
        number + 5, string .. "a"

      d\on "double", (e, number, string) ->
        number + 2, string .. "b"

      assert.same {
        8, "helloab"
      }, { d\pipe "double", 1, "hello" }

    it "pipes with two callbacks, multi args, cancels after first", ->
      d = Dispatch!

      d\on "double", (e, number, string) ->
        e.cancel = true
        number + 5, string .. "a"

      d\on "double", (e, number, string) ->
        number + 2, string .. "b"

      assert.same {
        6, "helloa"
      }, { d\pipe "double", 1, "hello" }

