local Plugin
Plugin = require("sitegen.plugin").Plugin
local min_depth = 1
local max_depth = 9
local slugify
slugify = require("sitegen.common").slugify
local insert
insert = table.insert
local Indexer2Plugin
do
  local _class_0
  local _parent_0 = Plugin
  local _base_0 = {
    events = {
      ["page.content_rendered"] = function(self, e, page, content)
        return page:set_content(self:parse_headers(content))
      end
    },
    parse_headers = function(self, content)
      local headers = { }
      local current = headers
      local push_header
      push_header = function(i, ...)
        i = tonumber(i)
        if not current.depth then
          current.depth = i
        else
          if i > current.depth then
            current = {
              parent = current,
              depth = i
            }
          else
            while i < current.depth and current.parent do
              insert(current.parent, current)
              current = current.parent
            end
            if i < current.depth then
              current.depth = i
            end
          end
        end
        return insert(current, {
          ...
        })
      end
      local replace_html
      replace_html = require("web_sanitize.query.scan_html").replace_html
      local out = replace_html(content, function(stack)
        local el = stack:current()
        local depth = el.tag:match("h(%d+)")
        if not (depth) then
          return 
        end
        depth = tonumber(depth)
        if not (depth >= min_depth and depth <= max_depth) then
          return 
        end
        local text = el:inner_text()
        local slug = slugify(text)
        el:replace_atributes({
          id = slug
        })
        return push_header(depth, text, slug)
      end)
      while current.parent do
        insert(current.parent, current)
        current = current.parent
      end
      return out, headers
    end
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
