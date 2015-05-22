
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

  table.sort files
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
      assert path.write_file_safe ...

    it "should build an empty site", ->
      site\init_from_fn =>
      site\write!
      assert.same {
        ".sitegen_cache"
        "www/.gitignore"
      }, get_files prefix

    it "should build with a markdown file", ->
      write "test.md", "hello I an *markdown*"
      write "inside/other.md", "more markdown"

      site\init_from_fn =>
        add "test.md"
        add "inside/other.md"

      site\write!

      assert.same {
        ".sitegen_cache"
        "inside/other.md"
        "test.md"
        "www/.gitignore"
        "www/inside/other.html"
        "www/test.html"
      }, get_files prefix


    it "should build many markdown files", ->
      write "hello.md", "hello I an *markdown*"
      write "world.md", "and I am world"

      site\init_from_fn =>
        search "*.md"

      site\write!

      assert.same {
        ".sitegen_cache"
        "hello.md"
        "world.md"
        "www/.gitignore"
        "www/hello.html"
        "www/world.html"
      }, get_files prefix


