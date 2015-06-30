import Renderer from require "sitegen.renderer"

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
render_until_complete = (tpl_scope, render_fn) ->
  out = nil
  while true
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

  -- all of these receive the page as the first argument
  cosmo_helpers: {
    render: (args) => -- render another page in current scope
      name = unpack args
      @site\Templates"."\fill name, @tpl_scope

    markdown: (args) =>
      MarkdownRenderer = require "sitegen.renderers.markdown"
      res = MarkdownRenderer\render args[1] or ""
      fill_ignoring_pre res, @tpl_scope

    -- TODO: render_until_complete will cause stack to be pushed multiple
    -- times
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

  helpers: (page) =>
    cosmo = { k, ((...) -> v page, ...) for k,v in pairs @cosmo_helpers}
    extend {}, cosmo, page.tpl_scope

  load: (source, site) =>
    content_fn, meta = super source, site

    render = (page) ->
      cosmo_scope = @helpers page
      page.tpl_scope.render_source = content_fn!

      out = render_until_complete page.tpl_scope, ->
        fill_ignoring_pre page.tpl_scope.render_source, cosmo_scope

      page.tpl_scope.render_source = nil

      out

    render, meta

