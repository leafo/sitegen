local Renderer
Renderer = require("sitegen.renderer").Renderer
local moonscript = require("moonscript.base")
local insert
insert = table.insert
local setfenv
setfenv = require("sitegen.common").setfenv
local MoonRenderer
do
  local _class_0
  local _parent_0 = Renderer
  local _base_0 = {
    source_ext = "moon",
    ext = "html",
    load = function(self, source)
      local content_fn, meta = _class_0.__parent.__base.load(self, source)
      local render
      render = function(page)
        local scopes = { }
        local fn = assert(moonscript.loadstring(content_fn()))
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
          self = page.tpl_scope,
          page = page,
          site = page.site,
          format = function(formatter)
            if type(formatter) == "string" then
              formatter = require(formatter)
            end
            return insert(scopes, formatter.make_context(page, context))
          end
        }, {
          __index = _G
        })
        insert(scopes, base_scope)
        context.format("sitegen.formatters.default")
        setfenv(fn, context)
        fn()
        return context.render()
      end
      return render, meta
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "MoonRenderer",
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
  MoonRenderer = _class_0
  return _class_0
end
