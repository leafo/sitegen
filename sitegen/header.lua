local trim_leading_white
trim_leading_white = require("sitegen.common").trim_leading_white
local load_header_table
load_header_table = function(code)
  local loadstring
  loadstring = require("moonscript.base").loadstring
  local fn = assert(loadstring(code))
  return fn()
end
local match_header_grammar
match_header_grammar = function(text, build_grammar)
  local V, Cp
  do
    local _obj_0 = require("lpeg")
    V, Cp = _obj_0.V, _obj_0.Cp
  end
  local g = assert(build_grammar(V("TableLit") * Cp()))
  local _, pos = assert(g:match(text))
  if type(pos) == "number" then
    return text:sub(pos), load_header_table(text:sub(1, pos - 1))
  end
end
local match_header_scan
match_header_scan = function(text, parse)
  local init = 1
  while true do
    local brace = text:find("}", init, true)
    if not (brace) then
      error("failed to parse moonscript header")
    end
    local prefix = text:sub(1, brace)
    local tree = parse.string(prefix)
    if tree and #tree == 1 and type(tree[1]) == "table" and tree[1][1] == "table" then
      return text:sub(brace + 1), load_header_table(prefix)
    end
    init = brace + 1
  end
end
local parse_moonscript_header
parse_moonscript_header = function(text)
  if text:match("^%s*{") then
    local parse = require("moonscript.parse")
    if parse.build_grammar then
      return match_header_grammar(text, parse.build_grammar)
    else
      return match_header_scan(text, parse)
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
