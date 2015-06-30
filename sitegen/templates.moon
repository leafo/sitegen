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

  -- helpers receive page as first argument
  base_helpers: {
    render: (args) => -- render another page in current scope
      name = unpack args
      @site\Templates"."\fill name, @tpl_scope

    markdown: (args) =>
      MarkdownRenderer = require "sitegen.renderers.markdown"
      res = MarkdownRenderer\render args[1] or ""
      fill_ignoring_pre res, @tpl_scope

    wrap: (args) =>
      tpl_name = unpack args
      throw_error "missing template name" if not tpl_name
      @template_stack\push tpl_name
      ""

    neq: (args) =>
      if args[1] != args[2]
        cosmo.yield {}
      else
        cosmo.yield _template: 2
      nil

    eq: (args) =>
      if args[1] == args[2]
        cosmo.yield {}
      else
        cosmo.yield _template: 2
      nil

    if: (args) =>
      if @tpl_scope[args[1]]
        cosmo.yield {}
      nil

    each: (args) =>
      list, name = unpack args
      if list
        list = flatten_args list
        for item in *list
          cosmo.yield { [(name)]: item }
      nil

    is_page: (args) =>
      page_pattern = unpack args
      cosmo.yield {} if @source\match page_pattern
      nil
  }

  new: (@site) =>
    @io = assert @site.io, "site missing io"

    @template_cache = {}
    @plugin_helpers = {}
    @base_helpers = extend @plugin_helpers, @base_helpers

  fill: (name, context) =>

    tpl = @get_template name
    tpl context

  templates_path: (subpath) =>
    Path.join @site.config.template_dir, subpath

  -- load an html (cosmo) template
  load_html: (name) =>
    full_name = @templates_path name .. ".html"

    return unless @io.exists full_name
    cosmo.f @io.read_file full_name

  -- load a moonscript template
  load_moon: (name) =>
    full_name = @templates_path name .. ".moon"
    return unless @io.exists full_name

    fn = moonscript.loadstring @io.read_file(full_name), name

    (scope) ->
      tpl_fn = loadstring string.dump fn -- copy function
      source_env = getfenv tpl_fn

      setfenv tpl_fn, { :scope }

      html.build tpl_fn

  -- load a markdown template
  load_md: (name) =>
    full_name = @templates_path name .. ".md"
    return unless @io.exists full_name

    MarkdownRenderer = require "sitegen.renderers.markdown"
    html = MarkdownRenderer\render @io.read_file full_name

    (scope) ->
      fill_ignoring_pre html, scope

  get_template: (name) =>
    if not @template_cache[name]
      local tpl

      -- look up exact file name
      base, ext = name\match "^(.-)%.([^/]*)$"
      if ext
        fn = self["load_"..ext]
        tpl = fn and fn self, base

      if not tpl
        for kind in *{"html", "moon", "md"}
          tpl = self["load_"..kind] self, name
          break if tpl

      if tpl
        @template_cache[name] = tpl
      else
        -- still don't have it? load default
        @template_cache[name] = if @defaults[name]
          cosmo.f @defaults[name]
        else
          throw_error "can't find template: " .. name

    @template_cache[name]

{
  :Templates
}
