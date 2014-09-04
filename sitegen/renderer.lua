local Renderer
do
  local _base_0 = {
    render = function()
      return error("must provide render method")
    end,
    can_render = function(self, fname)
      return nil ~= fname:match(self.pattern)
    end,
    parse_header = function(self, text)
      local extract_header
      extract_header = require("sitegen.header").extract_header
      return extract_header(text)
    end,
    render = function(self, text, site)
      return self:parse_header(text)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, pattern)
      self.pattern = pattern
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
