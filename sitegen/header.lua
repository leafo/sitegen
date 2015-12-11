local trim_leading_white
trim_leading_white = require("sitegen.common").trim_leading_white
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
  local remaining, header = parse_moonscript_header(text)
  if remaining then
    return remaining, header
  end
  return text, { }
end
return {
  extract_header = extract_header
}
