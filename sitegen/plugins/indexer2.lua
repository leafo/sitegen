local Plugin
Plugin = require("sitegen.plugin").Plugin
local min_depth = 1
local max_depth = 9
local slugify
slugify = require("sitegen.common").slugify
local Indexer2Plugin
do
  local _class_0
  local _parent_0 = Plugin
  local _base_0 = {
    events = {
      ["page.content_rendered"] = function(self, e, page, content)
        local replace_html
        replace_html = require("web_sanitize.query.scan_html").replace_html
        content = replace_html(content, function(stack)
          local el = stack:current()
          local depth = el.tag:match("h(%d+)")
          if not (depth) then
            return 
          end
          depth = tonumber(depth)
          if not (depth >= min_depth and depth <= max_depth) then
            return 
          end
          return el:replace_atributes({
            id = slugify(el:inner_text())
          })
        end)
        page._content = content
      end
    }
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Indexer2Plugin",
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
  Indexer2Plugin = _class_0
  return _class_0
end
