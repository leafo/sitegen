local split, Path
do
  local _obj_0 = require("sitegen.common")
  split, Path = _obj_0.split, _obj_0.Path
end
local SiteFile
SiteFile = require("sitegen.site_file").SiteFile
local log
log = function(...)
  return print("->", ...)
end
local get_site
get_site = function()
  return SiteFile():get_site()
end
local annotate
annotate = function(obj, verbs)
  return setmetatable({ }, {
    __newindex = function(self, name, value)
      obj[name] = value
    end,
    __index = function(self, name)
      local fn = obj[name]
      if not type(fn) == "function" then
        return fn
      end
      if verbs[name] then
        return function(...)
          fn(...)
          local first = ...
          return log(verbs[name], first)
        end
      else
        return fn
      end
    end
  })
end
Path = annotate(Path, {
  mkdir = "made directory",
  write_file = "wrote"
})
local wrap_text
wrap_text = function(text, indent, max_width)
  if indent == nil then
    indent = 0
  end
  if max_width == nil then
    max_width = 80
  end
  local width = max_width - indent
  local words = split(text, " ")
  local pos = 1
  local lines = { }
  while pos <= #words do
    local line_len = 0
    local line = { }
    while true do
      local word = words[pos]
      if word == nil then
        break
      end
      if #word > width then
        error("can't wrap text, words too long")
      end
      if line_len + #word > width then
        break
      end
      pos = pos + 1
      table.insert(line, word)
      line_len = line_len + #word + 1
    end
    table.insert(lines, table.concat(line, " "))
  end
  return table.concat(lines, "\n" .. (" "):rep(indent))
end
local columnize
columnize = function(rows, indent, padding)
  if indent == nil then
    indent = 2
  end
  if padding == nil then
    padding = 4
  end
  local max = 0
  for _index_0 = 1, #rows do
    local row = rows[_index_0]
    max = math.max(max, #row[1])
  end
  local left_width = indent + padding + max
  local formatted
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #rows do
      local row = rows[_index_0]
      local padd = (max - #row[1]) + padding
      local _value_0 = table.concat({
        (" "):rep(indent),
        row[1],
        (" "):rep(padd),
        wrap_text(row[2], left_width)
      })
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    formatted = _accum_0
  end
  return table.concat(formatted, "\n")
end
return {
  log = log,
  Path = Path,
  annotate = annotate,
  get_site = get_site,
  columnize = columnize
}
