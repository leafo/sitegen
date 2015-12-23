import Plugin from require "sitegen.plugin"

min_depth = 1
max_depth = 9

import slugify from require "sitegen.common"

class Indexer2Plugin extends Plugin
  events: {
    "page.content_rendered": (e, page, content) =>
      import replace_html from require "web_sanitize.query.scan_html"

      content = replace_html content, (stack) ->
        el = stack\current!
        depth = el.tag\match "h(%d+)"
        return unless depth
        depth = tonumber depth
        return unless depth >= min_depth and depth <= max_depth

        el\replace_atributes {
          id: slugify el\inner_text!
        }

      page._content = content
  }

