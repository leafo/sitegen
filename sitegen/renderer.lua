local Renderer
do
  local _class_0
  local _base_0 = {
    extract_header = function(self, text)
      local extract_header
      extract_header = require("sitegen.header").extract_header
      return extract_header(text)
    end,
    can_load = function(self, fname)
      if not (self.source_ext) then
        return nil
      end
      local convert_pattern
      convert_pattern = require("sitegen.common").convert_pattern
      local pattern = convert_pattern("*." .. tostring(self.source_ext) .. "$")
      return not not fname:match(pattern)
    end,
    load = function(self, source)
      local content, meta = self:extract_header(source)
      return (function()
        return content
      end), meta
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
    end,
    __base = _base_0,
    __name = "Renderer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Renderer = _class_0
end
return {
  Renderer = Renderer
}
