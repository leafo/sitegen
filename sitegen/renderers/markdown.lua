local Renderer
Renderer = require("sitegen.renderer").Renderer
local amp_temp = "0000sitegen_markdown00amp0000"
local MarkdownRenderer
do
  local _parent_0 = require("sitegen.renderers.html")
  local _base_0 = {
    source_ext = "md",
    ext = "html",
    pre_render = { },
    render = function(self, page, md_source)
      local discount = require("discount")
      local _list_0 = self.pre_render
      for _index_0 = 1, #_list_0 do
        local filter = _list_0[_index_0]
        md_source = filter(md_source, page)
      end
      md_source = md_source:gsub("%$", amp_temp)
      local html_source = assert(discount(md_source))
      html_source = html_source:gsub(amp_temp, "$")
      return _parent_0.render(self, page, html_source)
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
