import Renderer from require "sitegen.renderer"

moonscript = require "moonscript.base"

import insert from table

class MoonRenderer extends Renderer
  source_ext: "moon"
  ext: "html"

  load: (source) =>
    content_fn, meta = super source

    render = (page) ->
      scopes = {}
      fn = assert moonscript.loadstring content_fn!

      context = setmetatable {}, {
        __index: (key) =>
          for i=#scopes,1,-1
            val = scopes[i][key]
            return val if val
      }

      base_scope = setmetatable {
        _context: -> context
        self: page.tpl_scope

        page: page
        site: page.site

        -- appends a scope to __index of the context
        format: (formatter) ->
          if type(formatter) == "string"
            formatter = require formatter

          insert scopes, formatter.make_context page, context
      }, __index: _G

      insert scopes, base_scope
      context.format "sitegen.formatters.default"

      setfenv fn, context
      fn!
      context.render!

    render, meta

