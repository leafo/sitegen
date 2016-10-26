local Renderer
Renderer = require("sitegen.renderer").Renderer
local dollar_temp = "0000sitegen_markdown00dollar0000"
local simple_string
simple_string = function(delim)
  local P
  P = require("lpeg").P
  local inner = P("\\" .. tostring(delim)) + "\\\\" + (1 - P(delim))
  inner = inner ^ 0
  return P(delim) * inner * P(delim)
end
local escape_cosmo
escape_cosmo = function(str)
  local escapes = { }
  local P, R, Cmt, Cs
  do
    local _obj_0 = require("lpeg")
    P, R, Cmt, Cs = _obj_0.P, _obj_0.R, _obj_0.Cmt, _obj_0.Cs
  end
  local counter = 0
  local cosmo_inner = simple_string("'") + (P(1) - "}")
  local alphanum = R("az", "AZ", "09", "__")
  local cosmo = P("$") * alphanum ^ 1 * (P("{") * cosmo_inner ^ 0 * P("}")) ^ -1 / function(tpl)
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
  local _class_0
  local _parent_0 = require("sitegen.renderers.html")
  local _base_0 = {
    source_ext = "md",
    ext = "html",
    render = function(self, page, md_source)
      local discount = require("discount")
      md_source = page:pipe("renderer.markdown.pre_render", md_source)
      local escapes
      md_source, escapes = escape_cosmo(md_source)
      local html_source = assert(discount(md_source))
      html_source = unescape_cosmo(html_source, escapes)
      return _class_0.__parent.__base.render(self, page, html_source)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "MarkdownRenderer",
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
  local self = _class_0
  self.escape_cosmo = escape_cosmo
  self.unescape_cosmo = unescape_cosmo
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  MarkdownRenderer = _class_0
  return _class_0
end
