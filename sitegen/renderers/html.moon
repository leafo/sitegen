import Renderer from require "sitegen.renderer"

cosmo = require "cosmo"

import extend from require "moon"

import
  fill_ignoring_pre
  throw_error
  flatten_args
  pass_error
  from require "sitegen.common"

-- template_helpers can yield if they decide to change the
-- entire source. This triggers the render to happen again
-- with the updated tpl_scope.
-- see indexer
render_until_complete = (tpl_scope, render_fn, reset_fn) ->
  out = nil
  while true
    reset_fn!
    co = coroutine.create ->
      out = render_fn!
      nil

    success, altered_source = assert coroutine.resume co
    pass_error altered_source

    if altered_source
      tpl_scope.render_source = altered_source
    else
      break
  out

-- reads the raw content, runs cosmo on the result
class HTMLRenderer extends Renderer
  source_ext: "html"
  ext: "html"

  -- all of these receive the page as the first argument, not the renderer instance
  cosmo_helpers: {
    render: (args) => -- render another page in current scope
      name = assert unpack(args), "missing template name for render"

      templates = @site\Templates!
      templates.search_dir = "."
      templates.defaults = {}

      assert(templates\find_by_name(args[1]), "failed to find template: #{name}") @

    markdown: (args) =>
      md = @site\get_renderer "sitegen.renderers.markdown"
      md\render @, assert args[1], "missing markdown string"

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

    query_pages: (query) =>
      import query_pages from require "sitegen.query"
      for page in *query_pages @site.pages, query
        -- cosmo helpers should already be available from parent scope
        cosmo.yield page\get_tpl_scope!
      nil

    query_page: (query) =>
      import query_pages from require "sitegen.query"
      res = query_pages @site.pages, query
      assert #res == 1, "expected to find one page for `query_page`, found #{#res}"
      cosmo.yield res[1]\get_tpl_scope!
      nil

    url_for: (query) =>
      import query_pages from require "sitegen.query"
      res = query_pages @site.pages, query
      if #res == 0
        error "failed to find any pages matching: #{require("moon").dump query}"
      elseif #res > 1
        error "found more than 1 page matching: #{require("moon").dump query}"
      else
        "#{@tpl_scope.root}/#{res[1]\url_for!}"
  }

  helpers: (page) =>
    extend {},
      { k, ((...) -> v page, ...) for k,v in pairs @cosmo_helpers},
      page.tpl_scope

  render: (page, html_source) =>
    cosmo_scope = @helpers page
    old_render_source = page.tpl_scope.render_source
    page.tpl_scope.render_source = html_source

    -- stack size is remembered so re-renders don't continue to grow the
    -- template stack
    init_stack = #page.template_stack

    out = render_until_complete page.tpl_scope,
      (-> fill_ignoring_pre page.tpl_scope.render_source, cosmo_scope),
      (-> while #page.template_stack > init_stack do page.template_stack\pop!)

    page.tpl_scope.render_source = old_render_source
    out

  load: (source) =>
    content_fn, meta = super source
    ((page) -> @render page, content_fn!), meta

