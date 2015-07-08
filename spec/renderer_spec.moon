factory = require "spec.factory"

describe "renderers", ->
  render_for_site = (site, renderer, str, meta={}, page) ->
    page or= factory.Page(:site)
    page.render_fn, page.meta = renderer\load str
    page.meta.template = false
    for k,v in pairs meta
      page.meta[k] = v
    page\render!

  describe "renderers.html", ->
    local site, renderer

    before_each ->
      HTMLRenderer = require "sitegen.renderers.html"
      site = factory.Site!
      renderer = HTMLRenderer site

    render = (...) -> render_for_site site, renderer, ...

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

      it "renders url_for", ->
        factory.Page(:site, meta: {id: "cool"})
        p = factory.Page {
          :site
          target: "www/other_cool.html"
          meta: {id: "other_cool"}
        }

        assert.same "./other_cool.html",
          render '$url_for{id = "other_cool"}'

        -- does relative url correctly
        assert.same "../../other_cool.html",
          render '$url_for{id = "other_cool"}', {}, factory.Page {
            :site
            target: "www/yeah/good/stuff.html"
          }

  describe "renderers.markdown", ->
    local site, renderer

    before_each ->
      MarkdownRenderer = require "sitegen.renderers.markdown"
      site = factory.Site!
      renderer = MarkdownRenderer site

    render = (...) -> render_for_site site, renderer, ...

    it "renders preserves cosmo", ->
      assert.same "<p>yes</p>\n",
        render '$if{"val"}[[yes]]', { val: "yes" }

