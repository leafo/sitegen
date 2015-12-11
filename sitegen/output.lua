local colors = require("ansicolors")
local Logger
do
  local _class_0
  local _base_0 = {
    _flatten = function(self, ...)
      return table.concat((function(...)
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = {
          ...
        }
        for _index_0 = 1, #_list_0 do
          local p = _list_0[_index_0]
          _accum_0[_len_0] = tostring(p)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(...), " ")
    end,
    plain = function(self, ...)
      return self:print(self:_flatten(...))
    end,
    notice = function(self, prefix, ...)
      return self:print(colors("%{bright}%{yellow}" .. tostring(prefix) .. ":%{reset} ") .. self:_flatten(...))
    end,
    positive = function(self, prefix, ...)
      return self:print(colors("%{bright}%{green}" .. tostring(prefix) .. ":%{reset} ") .. self:_flatten(...))
    end,
    negative = function(self, prefix, ...)
      return self:print(colors("%{bright}%{red}" .. tostring(prefix) .. ":%{reset} ") .. self:_flatten(...))
    end,
    warn = function(self, ...)
      return self:notice("Warning", ...)
    end,
    error = function(self, ...)
      return self:negative("Error", ...)
    end,
    render = function(self, source, dest)
      return self:positive("rendered", tostring(source) .. " -> " .. tostring(dest))
    end,
    build = function(self, ...)
      return self:positive("built", ...)
    end,
    print = function(self, ...)
      if self.opts.silent then
        return 
      end
      return print(...)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.opts = opts
    end,
    __base = _base_0,
    __name = "Logger"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Logger = _class_0
end
return {
  Logger = Logger
}
