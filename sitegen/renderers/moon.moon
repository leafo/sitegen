import Renderer from require "sitegen.renderer"

moonscript = require "moonscript"

import convert_pattern from require "sitegen.common"
import insert from table

class MoonRenderer extends Renderer
  ext: "html"
  pattern: convert_pattern "*.moon"

  -- this does some crazy chaining
  render: (text, page) =>
    scopes = {}
    meta = {}

    context = setmetatable {}, {
      __index: (key) =>
        for i=#scopes,1,-1
          val = scopes[i][key]
          return val if val
    }

    base_scope = setmetatable {
      _context: -> context

      set: (name, value) -> meta[name] = value
      get: (name) -> meta[name]

      -- appends a scope to __index of the context
      format: (name) ->
        formatter = if type(name) == "string"
          require name
        else
          name

        insert scopes, formatter.make_context page, context
    }, __index: _G

    insert scopes, base_scope
    context.format "sitegen.formatters.default"

    fn = moonscript.loadstring text
    setfenv fn, context
    fn!
    context.render!, meta

