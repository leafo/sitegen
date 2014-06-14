local Renderer
do
  local _obj_0 = require("sitegen.renderer")
  Renderer = _obj_0.Renderer
end
local moonscript = require("moonscript.base")
local convert_pattern
do
  local _obj_0 = require("sitegen.common")
  convert_pattern = _obj_0.convert_pattern
end
local insert
do
  local _obj_0 = table
  insert = _obj_0.insert
end
local MoonRenderer
do
  local _parent_0 = Renderer
  local _base_0 = {
    ext = "html",
    pattern = convert_pattern("*.moon"),
    render = function(self, text, page)
      local scopes = { }
      local meta = { }
      local context = setmetatable({ }, {
        __index = function(self, key)
          for i = #scopes, 1, -1 do
            local val = scopes[i][key]
            if val then
              return val
            end
          end
        end
      })
      local base_scope = setmetatable({
        _context = function()
          return context
        end,
        set = function(name, value)
          meta[name] = value
        end,
        get = function(name)
          return meta[name]
        end,
        format = function(name)
          local formatter
          if type(name) == "string" then
            formatter = require(name)
          else
            formatter = name
          end
          return insert(scopes, formatter.make_context(page, context))
        end
      }, {
        __index = _G
      })
      insert(scopes, base_scope)
      context.format("sitegen.formatters.default")
      local fn = moonscript.loadstring(text)
      setfenv(fn, context)
      fn()
      return context.render(), meta
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "MoonRenderer",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  MoonRenderer = _class_0
  return _class_0
end
