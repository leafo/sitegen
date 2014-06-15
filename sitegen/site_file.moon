lfs = require "lfs"

import Path from require "sitegen.common"
Site = require "sitegen.site"

import extend, run_with_scope from require "moon"

moonscript = require "moonscript.base"

import
  Path
  throw_error
  trim
  escape_patt
  from require "sitegen.common"

import bright_yellow from require "sitegen.output"

-- does two things:
-- 1) finds the sitefile, looking up starting from the current dir
-- 2) lets us open files relative to where the sitefile is
class SiteFile
  new: (@name="site.moon") =>
    dir = lfs.currentdir!
    depth = 0
    while dir
      path = Path.join dir, name
      if Path.exists path
        @file_path = path
        @set_rel_path depth
        return
      dir = Path.up dir
      depth += 1

    throw_error "failed to find sitefile: " .. name

  -- convert from shell relative to sitefile relative
  relativeize: (path) =>
    exec = (cmd) ->
      p = io.popen cmd
      with trim p\read "*a"
        p\close!

    rel_path = if @rel_path == "" then "." else @rel_path

    @prefix = @prefix or exec("realpath " .. rel_path) .. "/"
    realpath = exec "realpath " .. path
    realpath\gsub "^" .. escape_patt(@prefix), ""

  -- set relative path to depth folders above current
  -- add it to package.path
  set_rel_path: (depth) =>
    @rel_path = ("../")\rep depth
    @make_io!
    package.path = @rel_path .. "?.lua;" .. package.path
    --  TODO: regenerate moonpath?
    package.moonpath = @rel_path .. "?.moon;" .. package.moonpath

  make_io: =>
    -- performs operations relative to sitefile
    @io = {
      -- load a file relative to the sitepath
      open: (fname, ...) ->
        io.open @io.real_path(fname), ...

      real_path: (fname) ->
        Path.join(@rel_path, fname)
    }

  get_site: =>
    print bright_yellow"Using:", Path.join @rel_path, @name

    fn = moonscript.loadfile @file_path
    -- sitefiles have \write! on the bottom, disable it
    site = nil
    sitegen = require "sitegen"

    run_with_scope fn, {
      sitegen: extend {
        create_site: (fn) ->
          site = sitegen.create_site fn, Site self
          site.write = ->
          site
      }, sitegen
    }

    site.write = nil -- restore default write
    site

{
  :SiteFile
}
