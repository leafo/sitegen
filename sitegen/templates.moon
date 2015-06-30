cosmo = require "cosmo"
html = require "sitegen.html"
moonscript = require "moonscript.base"

import extend from require "moon"

Path = require "sitegen.path"

import
  fill_ignoring_pre
  throw_error
  flatten_args
  from require "sitegen.common"

class Templates
  defaults: require "sitegen.default.templates"

  new: (@site) =>
    @io = assert @site.io, "site missing io"
    @template_cache = {}

  templates_path: (subpath) =>
    Path.join @site.config.template_dir, subpath

  find_by_name: (name) =>
    if @template_cache[name]
      return @template_cache[name]

    for renderer in *@site.renderers
      continue unless renderer.source_ext
      fname = @templates_path "#{name}.#{renderer.source_ext}"
      if @io.exists fname
        @template_cache[name] = renderer\load @io.read_file fname
        break

    -- TODO: load default here

    @template_cache[name]

{
  :Templates
}
