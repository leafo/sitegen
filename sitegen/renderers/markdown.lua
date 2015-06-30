local Renderer
Renderer = require("sitegen.renderer").Renderer
local amp_temp = tostring(os.time()) .. "amp" .. tostring(os.time())
local MarkdownRenderer
do
  local _parent_0 = Renderer
  local _base_0 = {
    source_ext = "md",
    ext = "html",
    pre_render = { },
    render = function(self, text, page)
      local discount = require("discount")
      local header
      text, header = self:parse_header(text)
      local _list_0 = self.pre_render
      for _index_0 = 1, #_list_0 do
        local filter = _list_0[_index_0]
        text = filter(text, page)
      end
      text = text:gsub("%$", amp_temp)
      text = assert(discount(text))
      text = text:gsub(amp_temp, "$")
      return text, header
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "MarkdownRenderer",
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
  MarkdownRenderer = _class_0
  return _class_0
end
