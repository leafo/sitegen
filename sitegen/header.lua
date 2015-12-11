local trim_leading_white
trim_leading_white = require("sitegen.common").trim_leading_white
local get_yaml
get_yaml = function()
  local yaml
  pcall(function()
    yaml = require("yaml")
  end)
  get_yaml = function()
    return yaml
  end
  return yaml
end
local parse_yaml_header
parse_yaml_header = function(text)
  local s, e = text:find("\n%s*%-%-\n")
  if s then
    local header = text:sub(1, s - 1)
    text = text:sub(e)
    header = trim_leading_white(header)
    header = get_yaml().load(header)
    return text, header
  end
  return nil, "no header found"
end
local parse_moonscript_header
parse_moonscript_header = function(text)
  if text:match("^%s*{") then
    local build_grammar
    build_grammar = require("moonscript.parse").build_grammar
    local V, Cp, Ct
    do
      local _obj_0 = require("lpeg")
      V, Cp, Ct = _obj_0.V, _obj_0.Cp, _obj_0.Ct
    end
    local g = assert(build_grammar(V("TableLit") * Cp()))
    local _, pos = assert(g:match(text))
    if type(pos) == "number" then
      local loadstring
      loadstring = require("moonscript.base").loadstring
      local fn = assert(loadstring(text:sub(1, pos - 1)))
      return text:sub(pos), fn()
    end
  end
end
local extract_header
extract_header = function(text)
  if get_yaml() then
    local remaining, header = parse_yaml_header(text)
    if remaining then
      return remaining, header
    end
  end
  local remaining, header = parse_moonscript_header(text)
  if remaining then
    return remaining, header
  end
  return text, { }
end
return {
  extract_header = extract_header
}
