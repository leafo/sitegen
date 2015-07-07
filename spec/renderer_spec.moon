factory = require "spec.factory"

describe "renderers", ->
  describe "renderers.html", ->
    local site, renderer

    before_each ->
      HTMLRenderer = require "sitegen.renderers.html"
      site = factory.Site!
      renderer = HTMLRenderer site

    render = (str, meta={}) ->
      page = factory.Page(:site)
      page.render_fn, page.meta = renderer\load str
      page.meta.template = false
      for k,v in pairs meta
        page.meta[k] = v
      page\render!

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




