import extend from require "moon"

Path = require "sitegen.path"

class Templates
  defaults: require "sitegen.default.templates"

  new: (@site) =>
    @io = assert @site.io, "site missing io"
    @template_cache = {}
    @search_dir = nil -- allow overriding the search directory

  templates_path: (subpath) =>
    search_dir = @search_dir or @site.config.template_dir
    Path.join search_dir, subpath

  find_by_name: (name) =>
    if @template_cache[name]
      return @template_cache[name]

    for renderer in *@site.renderers
      continue unless renderer.source_ext
      fname = @templates_path "#{name}.#{renderer.source_ext}"
      if @io.exists fname
        @template_cache[name] = renderer\load @io.read_file(fname), fname
        break

    if default = not @template_cache[name] and @defaults[name]
      HTMLRenderer = require "sitegen.renderers.html"
      @template_cache[name] = HTMLRenderer\load(default, "default.template(#{name})")

    @template_cache[name]

{
  :Templates
}
