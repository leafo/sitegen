
Site = require "sitegen.site"
import SiteFile from require "sitegen.site_file"

Path = require "sitegen.path"

import escape_patt from require "sitegen.common"

get_files = (path, prefix=path) ->
  files = Path.read_exec "find", path, "-type", "f"
  files = [f for f in files\gmatch "[^\n]+"]

  if prefix
    files = for file in *files
      file\gsub "^#{escape_patt prefix}/?", ""

  files

describe "sitegen", ->
  it "should load sitegen", ->
    sitegen = require "sitegen"

  describe "with path", ->
    local prefix, path, site

    before_each ->
      prefix = "spec/temp_site"
      Path.rmdir prefix
      Path.mkdir prefix
      path = Path\relative_to prefix

      sitefile = SiteFile rel_path: prefix
      site = Site sitefile

    write = (...) ->
      path.write_file ...

    it "should build an empty site", ->
      site\init_from_fn =>
      site\write!
      assert.same {".sitegen_cache"}, get_files prefix

    it "should build with a markdown file #ddd", ->
      print!
      write "test.md", "hello I an *markdown*"

      site\init_from_fn =>
        add "test.md"

      site\write!

