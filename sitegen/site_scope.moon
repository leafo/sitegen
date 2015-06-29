lfs = require "lfs"

Path = require "sitegen.path"

import
  OrderSet
  flatten_args
  convert_pattern
  from require "sitegen.common"

-- visible from init
class SiteScope
  new: (@site) =>
    @files = OrderSet!
    @meta = {}
    @copy_files = OrderSet!

    @builds = {}
    @filters = {}

  set: (name, value) => self[name] = value
  get: (name) => self[name]

  disable: (thing) =>
    @site[thing .. "_disabled"] = true

  add_renderer: (renderer) =>
    if type(renderer) == "string"
      renderer = require renderer

    table.insert @site.renderers, 1, (assert renderer, "nil renderer")

  add: (...) =>
    files, options = flatten_args ...
    for fname in *files
      continue if @files\has fname
      @files\add fname
      @meta[fname] = options if next(options)

  build: (tool, input, ...) =>
    table.insert @builds, {tool, input, {...}}

  copy: (...) =>
    files = flatten_args ...
    @copy_files\add fname for fname in *files

  filter: (pattern, fn) =>
    table.insert @filters, {pattern, fn}

  search: (pattern, dir=".", enter_dirs=false) =>
    pattern = convert_pattern pattern
    root_dir = @site.io.full_path dir

    search = (dir) ->
      for fname in lfs.dir dir
        continue if fname\match "^%." -- no hidden files

        full_path = Path.join dir, fname

        if enter_dirs and "directory" == lfs.attributes full_path, "mode"
          search full_path
          continue

        if fname\match pattern
          if full_path\match"^%./"
            full_path = full_path\sub 3

          relative = @site.io.strip_prefix full_path

          unless @files\has relative
            @files\add relative

    search root_dir

  dump_files: =>
    print "added files:"
    for path in @files\each!
      print " * " .. path
    print!
    print "copy files:"
    for path in @copy_files\each!
      print " * " .. path

{
  :SiteScope
}
