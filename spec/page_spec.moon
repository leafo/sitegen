query = require "sitegen.query"
factory = require "spec.factory"

describe "page", ->
  describe "with site & pages", ->
    local site
    before_each ->
      site = factory.Site!

      factory.Page {
        :site
        meta: {
          is_a: {"blog_post", "article"}
        }
      }

      factory.Page {
        :site
        meta: {
          is_a: "article"
          tags: {"cool"}
        }
      }

      factory.Page { :site }

    it "queries with empty result", ->
      pages = site\query_pages { tag: "hello" }
      assert.same {}, pages

    it "queries all with empty query", ->
      pages = site\query_pages { }
      assert.same 3, #pages

    it "queries raw", ->
      pages = site\query_pages { is_a: "article" }
      assert.same 1, #pages

    it "queries filter contains", ->
      pages = site\query_pages { is_a: query.filter.contains "article" }
      assert.same 2, #pages

    it "queries filter contains", ->
      pages = site\query_pages { tags: query.filter.contains "cool" }
      assert.same 1, #pages
