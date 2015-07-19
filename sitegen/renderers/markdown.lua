local Renderer
Renderer = require("sitegen.renderer").Renderer
local dollar_temp = "0000sitegen_markdown00dollar0000"
local escape_cosmo
escape_cosmo = function(str)
  local escapes = { }
  local P, R, Cmt, Cs
  do
    local _obj_0 = require("lpeg")
    P, R, Cmt, Cs = _obj_0.P, _obj_0.R, _obj_0.Cmt, _obj_0.Cs
  end
  local counter = 0
  local alphanum = R("az", "AZ", "09", "__")
  local cosmo = P("$") * alphanum ^ 1 * (P("{") * (P(1) - "}") ^ 0 * P("}")) ^ -1 / function(tpl)
    counter = counter + 1
    local key = tostring(dollar_temp) .. "." .. tostring(counter)
    escapes[key] = tpl
    return key
  end
  local patt = Cs((cosmo + P(1)) ^ 0 * P(-1))
  str = patt:match(str) or str, escapes
  return str, escapes
end
local unescape_cosmo
unescape_cosmo = function(str, escapes)
  local P, R, Cmt, Cs
  do
    local _obj_0 = require("lpeg")
    P, R, Cmt, Cs = _obj_0.P, _obj_0.R, _obj_0.Cmt, _obj_0.Cs
  end
  local escape_patt = P(dollar_temp) * P(".") * R("09") ^ 1 / function(key)
    return escapes[key] or error("bad key for unescape_cosmo")
  end
  local patt = Cs((escape_patt + P(1)) ^ 0 * P(-1))
  return assert(patt:match(str))
end
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
      local escapes
      md_source, escapes = escape_cosmo(md_source)
      local html_source = assert(discount(md_source))
      html_source = unescape_cosmo(html_source, escapes)
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
