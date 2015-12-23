import Plugin from require "sitegen.plugin"

min_depth = 1
max_depth = 9

import slugify from require "sitegen.common"
import insert from table

class Indexer2Plugin extends Plugin
  events: {
    "page.content_rendered": (e, page, content) =>
      page\set_content @parse_headers content
  }

  parse_headers: (content) =>
    headers = {}
    current = headers

    push_header = (i, ...) ->
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

      insert current, {...}

    import replace_html from require "web_sanitize.query.scan_html"

    out = replace_html content, (stack) ->
      el = stack\current!
      depth = el.tag\match "h(%d+)"
      return unless depth
      depth = tonumber depth
      return unless depth >= min_depth and depth <= max_depth

      text = el\inner_text!
      slug = slugify text

      el\replace_atributes {
        id: slug
      }

      push_header depth, text, slug

    -- clean up
    while current.parent
      insert current.parent, current
      current = current.parent

    -- print @render_index headers
    out, headers
  
  render_index: (headers) =>
    html = require "sitegen.html"
    html.build ->
      render = (headers) ->
        ul for item in *headers
          if item.depth
            render item
          else
            {title, slug} = item

            li {
              a {
                title
                href: "##{slug}"
              }
            }


      render headers



