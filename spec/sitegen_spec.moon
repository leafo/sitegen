
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
      (assert path.write_file_safe ...)

    read = (...) ->
      (assert path.read_file ...)

    it "should build an empty site", ->
      site\init_from_fn =>
      site\write!
      assert.same {
        ".sitegen_cache"
        "www/.gitignore"
      }, get_files prefix

    it "builds site with html renderer", ->
      write "test.html", "hello I an html file"
      site\init_from_fn =>
        add "test.html"

      site\write!

      assert.same {
        ".sitegen_cache"
        "test.html"
        "www/.gitignore"
        "www/test.html"
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


    it "builds site with moon renderer", ->
      write "index.moon", [[write "hello world!"]]

      site\init_from_fn =>
        @title = "The title"
        add "index.moon"

      site\write!

      assert.same [[<!DOCTYPE HTML>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>The title</title>
  
  
</head>
<body>
  hello world!
</body>
</html>
]], read "www/index.html"

      assert.same {
        ".sitegen_cache"
        "index.moon"
        "www/.gitignore"
        "www/index.html"
      }, get_files prefix


    it "builds site with lapis renderer", ->
      write "hello.moon", [[
import Widget from require "lapis.html"

class Thinger extends Widget
  @options: {
    title: "cool stuff"
  }

  content: =>
    div class: "hi", "Hello world"
    div @title
]]

      site\init_from_fn =>
        add_renderer "sitegen.renderers.lapis"
        add "hello.moon"

      site\write!

      assert.same {
        ".sitegen_cache"
        "hello.moon"
        "www/.gitignore"
        "www/hello.html"
      }, get_files prefix

      assert.same [[<!DOCTYPE HTML>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>cool stuff</title>
  
  
</head>
<body>
  <div class="hi">Hello world</div><div>cool stuff</div>
</body>
</html>
]], read "www/hello.html"

    it "builds site moon template", ->
      write "index.moon", [[write "this is the inside"]]
      write "templates/web.moon", [[
write "TEMPLATE TOP"
write @body
write "TEMPLATE BOTTOM"]]

      site\init_from_fn =>
        @title = "The title"
        add "index.moon", template: "web"

      site\write!
      assert.same [[
TEMPLATE TOP
this is the inside
TEMPLATE BOTTOM]], read "www/index.html"

    it "builds site with markdown helper", ->
      write "index.html", [==[$markdown{[[hello *world*]]}]==]
      site\init_from_fn =>
        add "index.html", template: false

      site\write!

      read "www/index.html"
      assert.same "<p>hello <em>world</em></p>\n", read "www/index.html"

    it "builds site with user vars", ->
      write "index.html", [[hello $world and $something{color = 'blue'}]]

      site\init_from_fn =>
        @world = "777"
        @something = (page, arg) ->
          "HELLO(color:#{arg.color})(target:#{page.target})"

        add "index.html", template: false

      site\write!
      assert.same "hello 777 and HELLO(color:blue)(target:www/index.html)", read "www/index.html"


