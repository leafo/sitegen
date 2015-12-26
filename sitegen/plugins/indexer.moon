import Plugin from require "sitegen.plugin"

import slugify from require "sitegen.common"
import insert from table

class IndexerPlugin extends Plugin
  tpl_helpers: { "index" }

  events: {
    "page.content_rendered": (e, page, content) =>
      return if @current_index[page] -- already added index
      return unless page.meta.index
      body, @current_index[page] = @parse_headers content, page.meta.index
      page\set_content body
  }

  new: (@site) =>
    super @site
    @current_index = {}

  index_for_page: (page) =>
    page\render!
    @current_index[page]

  -- renders index from within template
  index: (page) =>
    unless @current_index[page]
      assert page.tpl_scope.render_source,
        "attempting to render index with no body available (are you in cosmo?)"

      body, @current_index[page] = @parse_headers page.tpl_scope.render_source, page.meta.index
      coroutine.yield body

    @render_index @current_index[page]

  parse_headers: (content, opts) =>
    opts = {} unless type(opts) == "table"

    min_depth = opts.min_depth or 1
    max_depth = opts.max_depth or 9
    link_headers = opts.link_headers

    headers = {}
    current = headers

    push_header = (i, header) ->
      i = tonumber i

      if not current.depth
        current.depth = i
      else
        if i > current.depth
          current = parent: current, depth: i
        else
          while i < current.depth and current.parent
            insert current.parent, current
            current = current.parent

          current.depth = i if i < current.depth

      insert current, header

    import replace_html from require "web_sanitize.query.scan_html"

    out = replace_html content, (stack) ->
      el = stack\current!
      depth = el.tag\match "h(%d+)"
      return unless depth
      depth = tonumber depth
      return unless depth >= min_depth and depth <= max_depth

      title = el\inner_text!
      html_content = el\inner_html!
      slug = slugify title

      push_header depth, {
        :title
        :slug
        :html_content
      }

      -- add hierarchy to slug now that tree is built
      if current.parent
        last_parent = current.parent[#current.parent]
        item = current[#current]
        item.slug = "#{last_parent.slug}/#{item.slug}"
        slug = item.slug

      if link_headers
        html = require "sitegen.html"
        el\replace_inner_html html.build ->
          a {
            name: slug
            href: "##{slug}"
            raw el\inner_html!
          }
      else
        el\replace_attributes {
          id: slug
        }

    -- clean up
    while current.parent
      insert current.parent, current
      current = current.parent

    out, headers

  render_index: (headers) =>
    html = require "sitegen.html"
    html.build ->
      render = (headers) ->
        ul for item in *headers
          if item.depth
            render item
          else
            {:title, :slug, :html_content} = item

            li {
              a {
                href: "##{slug}"
                raw html_content
              }
            }


      render headers



