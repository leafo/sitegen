cosmo = require "cosmo"
html = require "sitegen.html"
moonscript = require "moonscript.base"

import extend from require "moon"

import
  Path
  fill_ignoring_pre
  throw_error
  flatten_args
  from require "sitegen.common"

class Templates
  defaults: require "sitegen.default.templates"
  base_helpers: {
    render: (args) => -- render another page in current scope
      name = unpack args
      @site\Templates"."\fill name, @tpl_scope

    markdown: (args) =>
      MarkdownRenderer = require "sitegen.renderers.markdown"
      MarkdownRenderer\render args[1] or ""

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

  new: (@dir, _io) =>
    @template_cache = {}
    @plugin_helpers = {}
    @base_helpers = extend @plugin_helpers, @base_helpers
    @io = _io or io

  fill: (name, context) =>
    tpl = @get_template name
    tpl context

  -- load an html (cosmo) template
  load_html: (name) =>
    file = @io.open Path.join @dir, name .. ".html"
    return if not file
    with cosmo.f file\read "*a"
      file\close!

  -- load a moonscript template
  load_moon: (name) =>
    file = @io.open Path.join @dir, name .. ".moon"
    return if not file
    fn = moonscript.loadstring file\read"*a", name
    file\close!

    (scope) ->
      tpl_fn = loadstring string.dump fn -- copy function
      source_env = getfenv tpl_fn

      setfenv tpl_fn, { :scope }

      html.build tpl_fn

  -- load a markdown template
  load_md: (name) =>
    file = @io.open Path.join @dir, name .. ".md"
    return if not file

    MarkdownRenderer = require "sitegen.renderers.markdown"
    html = MarkdownRenderer\render file\read"*a"
    file\close!

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
