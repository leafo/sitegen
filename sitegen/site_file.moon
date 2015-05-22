lfs = require "lfs"

import Path from require "sitegen.common"
Site = require "sitegen.site"

import extend, run_with_scope from require "moon"

moonscript = require "moonscript.base"

Path = require "sitegen.path"

import
  throw_error
  trim
  escape_patt
  from require "sitegen.common"

import Logger from require "sitegen.output"

-- does two things:
-- 1) finds the sitefile, looking up starting from the current dir
-- 2) lets us open files relative to where the sitefile is
class SiteFile
  @master: nil -- the global sitefile of the current process

  new: (opts={}) =>
    @name = opts.name or "site.moon"
    @logger = Logger opts.logger_opts

    if opts.rel_path
      @rel_path = opts.rel_path
      @file_path = Path.join @rel_path, @name
      @make_io!
    else
      @find_root!

  find_root: =>
    dir = lfs.currentdir!
    depth = 0
    while dir
      path = Path.join dir, @name
      if Path.exists path
        @file_path = path
        @set_rel_path depth
        return
      dir = Path.up dir
      depth += 1

    throw_error "failed to find sitefile `#{@name}`"

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
    @io = Path\relative_to @rel_path

  get_site: =>
    @logger\notice "using", Path.join @rel_path, @name

    fn = assert moonscript.loadfile @file_path
    sitegen = require "sitegen"

    -- stub out write to not run during load for legacy
    old_write = Site.write

    local site_ref, site

    Site.__base.write = (site) ->
      site_ref = site
      site

    with old_master = @@master
      @@master = @
      site = run_with_scope fn, {
        -- for legacy pages that doesn't reference module
        sitegen: require "sitegen"
      }
      @@master = old_master

    Site.__base.write = old_write
    assert site, "Failed to load site from sitefile, make sure site is returned"

{
  :SiteFile
}
