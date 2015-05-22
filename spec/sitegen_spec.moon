
Site = require "sitegen.site"
import SiteFile from require "sitegen.site_file"

Path = require "sitegen.path"

describe "sitegen", ->
  it "should load sitegen", ->
    sitegen = require "sitegen"

  describe "with path", ->
    local path, site

    before_each ->
      Path.rmdir "spec/temp_site"
      Path.mkdir "spec/temp_site"
      path = Path\relative_to "spec/temp_site"

      site_file = SiteFile rel_path: "spec/temp_site"
      site = Site site_file

    it "should build an empty site", ->
      -- 


