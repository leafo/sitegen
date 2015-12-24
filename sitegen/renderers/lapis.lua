local Renderer
Renderer = require("sitegen.renderer").Renderer
local moonscript = require("moonscript.base")
local LapisRenderer
do
  local _class_0
  local _parent_0 = Renderer
  local _base_0 = {
    source_ext = "moon",
    ext = "html",
    load = function(self, source, fname)
      local chunk_name
      if fname then
        chunk_name = "@" .. tostring(fname)
      end
      local fn = assert(moonscript.loadstring(source, chunk_name))
      local widget = fn()
      return (function(page)
        local w = widget({
          page = page,
          site = page.site
        })
        w:include_helper(page.tpl_scope)
        return w:render_to_string()
      end), widget.options
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "LapisRenderer",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  LapisRenderer = _class_0
  return _class_0
end
