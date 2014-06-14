local yaml = require("yaml")
local trim_leading_white
do
  local _obj_0 = require("sitegen.common")
  trim_leading_white = _obj_0.trim_leading_white
end
local parse_header
parse_header = function(header)
  header = trim_leading_white(header)
  return yaml.load(header)
end
local extract_header
extract_header = function(text)
  local header
  local s, e = text:find("%-%-\n")
  if s then
    header = parse_header(text:sub(1, s - 1))
    text = text:sub(e)
  end
  return text, header or { }
end
return {
  extract_header = extract_header,
  parse_header = parse_header,
  trim_front = trim_front
}
