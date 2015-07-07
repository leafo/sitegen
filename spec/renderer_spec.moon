factory = require "spec.factory"

describe "renderers", ->
  describe "renderers.html", ->
    local site, renderer

    before_each ->
      HTMLRenderer = require "sitegen.renderers.html"
      site = factory.Site!
      renderer = HTMLRenderer site


    it "renders basic string", ->
      page = factory.Page(:site)
      page.render_fn, page.meta = renderer\load "hello!"

      assert.same {}, page.meta

      page.meta.template = false
      assert.same "hello!", page\render!

