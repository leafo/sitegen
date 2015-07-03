Site = require "sitegen.site"

import Page from require "sitegen.page"
import SiteFile from require "sitegen.site_file"

describe "page", ->
  create_page = (t={}) ->
    t.meta or= {}
    t.source or= "some_page.md"
    t.target or= "www/some_page.html"
    t.render_fn or= ->
    setmetatable t, Page

  describe "with site & pages", ->
    local site
    before_each ->
      site = Site SiteFile {
        rel_path: "."
      }

      site.pages = {
        create_page!
        create_page!
      }

    it "queries with empty result", ->
      pages = site\query_pages { tag: "hello" }
      assert.same {}, pages


    it "queries all with empty query", ->
      pages = site\query_pages { }
      assert.same 2, #pages


