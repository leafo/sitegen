local Renderer
do
  local _obj_0 = require("sitegen.renderer")
  Renderer = _obj_0.Renderer
end
local convert_pattern
do
  local _obj_0 = require("sitegen.common")
  convert_pattern = _obj_0.convert_pattern
end
local HTMLRenderer
do
  local _parent_0 = Renderer
  local _base_0 = {
    ext = "html",
    pattern = convert_pattern("*.html")
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "HTMLRenderer",
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
  HTMLRenderer = _class_0
  return _class_0
end