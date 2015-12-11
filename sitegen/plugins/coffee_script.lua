local Plugin
Plugin = require("sitegen.plugin").Plugin
local html = require("sitegen.html")
local unpack
unpack = require("sitegen.common").unpack
local CoffeeScriptPlugin
do
  local _class_0
  local _parent_0 = Plugin
  local _base_0 = {
    tpl_helpers = {
      "render_coffee"
    },
    compile_coffee = function(self, fname)
      local p = io.popen(("coffee -c -p %s"):format(fname))
      return p:read("*a")
    end,
    render_coffee = function(self, page, arg)
      local fname = unpack(arg)
      return html.build(function()
        return script({
          type = "text/javascript",
          raw(self:compile_coffee(fname))
        })
      end)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "CoffeeScriptPlugin",
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
  CoffeeScriptPlugin = _class_0
  return _class_0
end
