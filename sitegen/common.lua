local socket = nil
pcall(function()
  socket = require("socket")
end)
local unpack = unpack or table.unpack
local timed_call
timed_call = function(fn)
  local start = socket and socket.gettime()
  local res = {
    fn()
  }
  return socket and (socket.gettime() - start), unpack(res)
end
local throw_error
throw_error = function(...)
  if coroutine.running() then
    return coroutine.yield({
      "error",
      ...
    })
  else
    return error(...)
  end
end
local pass_error
pass_error = function(obj, ...)
  if type(obj) == "table" and obj[1] == "error" then
    throw_error(unpack(obj, 2))
  end
  return obj, ...
end
local catch_error
catch_error = function(fn)
  local Logger
  Logger = require("sitegen.output").Logger
  local co = coroutine.create(function()
    return fn() and nil
  end)
  local status, res = coroutine.resume(co)
  if not status then
    error(debug.traceback(co, res))
  end
  if res then
    Logger():error(res[2])
    os.exit(1)
  end
  return false
end
local error_context
error_context = function(context, fn)
  local co = coroutine.create(function()
    return fn() and nil
  end)
  local status, res = coroutine.resume(co)
  if not status then
    error(debug.traceback(co, res))
  end
  if type(res) == "table" and res[1] == "error" then
    return throw_error(tostring(context) .. ": " .. tostring(res[2]))
  end
end
local get_local
get_local = function(name, level)
  if level == nil then
    level = 4
  end
  local locals = { }
  local names = { }
  local i = 1
  local info = debug.getinfo(level)
  print("capturing scope for ", info.name or info.short_src)
  while true do
    local lname, value = debug.getlocal(level, i)
    if not lname then
      break
    end
    print("->", lname, value)
    table.insert(names, lname)
    locals[lname] = value
    i = i + 1
  end
  print("locals:", table.concat(names, ", "))
  if name then
    return locals[name]
  end
end
local punct = "[%^$()%.%[%]*+%-?]"
local escape_patt
escape_patt = function(str)
  return (str:gsub(punct, function(p)
    return "%" .. p
  end))
end
local split
split = function(str, delim)
  str = str .. delim
  local _accum_0 = { }
  local _len_0 = 1
  for part in str:gmatch("(.-)" .. escape_patt(delim)) do
    _accum_0[_len_0] = part
    _len_0 = _len_0 + 1
  end
  return _accum_0
end
local trim_leading_white
trim_leading_white = function(str, leading)
  assert(type(str) == "string", "Expecting string for trim_leading_white")
  local lines = split(str, "\n")
  if #lines > 0 then
    if not (leading) then
      for _index_0 = 1, #lines do
        local _continue_0 = false
        repeat
          do
            local line = lines[_index_0]
            if line:match("^%s*$") then
              _continue_0 = true
              break
            end
            leading = line:match("^(%s*)")
            break
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end
    if not (leading) then
      return str
    end
    for i, line in ipairs(lines) do
      lines[i] = line:match("^" .. leading .. "(.*)$") or line
    end
    if lines[#lines]:match("^%s*$") then
      lines[#lines] = nil
    end
  end
  return table.concat(lines, "\n")
end
local make_list
make_list = function(item)
  return type(item) == "table" and item or {
    item
  }
end
local bound_fn
bound_fn = function(cls, fn_name)
  return function(...)
    return cls[fn_name](cls, ...)
  end
end
local convert_pattern
convert_pattern = function(patt)
  patt = patt:gsub("([.])", function(item)
    return "%" .. item
  end)
  return patt:gsub("[*]", ".*")
end
local slugify
slugify = function(text)
  local html = require("sitegen.html")
  text = html.strip_tags(text)
  text = text:gsub("[&+]", " and ")
  return (text:gsub("[%s_]+", "-"):gsub("[^%w%-]+", ""):gsub("-+", "-")):lower()
end
local flatten_args
flatten_args = function(...)
  local accum = { }
  local options = { }
  local flatten
  flatten = function(tbl)
    for k, v in pairs(tbl) do
      if type(k) == "number" then
        if type(v) == "table" then
          flatten(v)
        else
          table.insert(accum, v)
        end
      else
        options[k] = v
      end
    end
  end
  flatten({
    ...
  })
  return accum, options
end
local trim
trim = function(str)
  str = tostring(str)
  if #str > 200 then
    return str:gsub("^%s+", ""):reverse():gsub("^%s+", ""):reverse()
  else
    return str:match("^%s*(.-)%s*$")
  end
end
local OrderSet
do
  local _class_0
  local _base_0 = {
    add = function(self, item)
      if self.list[item] == nil then
        table.insert(self.list, item)
        self.set[item] = #self.list
      end
    end,
    has = function(self, item)
      return self.set[item] ~= nil
    end,
    each = function(self)
      return coroutine.wrap(function()
        local _list_0 = self.list
        for _index_0 = 1, #_list_0 do
          local item = _list_0[_index_0]
          coroutine.yield(item)
        end
      end)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, items)
      self.list = { }
      self.set = { }
      if items then
        for _index_0 = 1, #items do
          local item = items[_index_0]
          self:add(item)
        end
      end
    end,
    __base = _base_0,
    __name = "OrderSet"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  OrderSet = _class_0
end
local Stack
do
  local _class_0
  local _base_0 = {
    push = function(self, item)
      self[#self + 1] = item
    end,
    pop = function(self, item)
      local len = #self
      do
        local _with_0 = self[len]
        self[len] = nil
        return _with_0
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Stack"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Stack = _class_0
end
local count_lines
count_lines = function(text)
  local P, Ct
  do
    local _obj_0 = require("lpeg")
    P, Ct = _obj_0.P, _obj_0.Ct
  end
  local newline = (P("\r") ^ -1 * P("\n"))
  local pattern = Ct((newline / 1 + P(1)) ^ 0)
  return #pattern:match(text)
end
local highlight_line
highlight_line = function(lines, line_no, context, highlight_color, line_offset)
  if context == nil then
    context = 2
  end
  if highlight_color == nil then
    highlight_color = "%{bright}%{red}"
  end
  if line_offset == nil then
    line_offset = 0
  end
  assert(line_no, "missing line no")
  local P, Cs, Ct
  do
    local _obj_0 = require("lpeg")
    P, Cs, Ct = _obj_0.P, _obj_0.Cs, _obj_0.Ct
  end
  local end_of_line = (P("\r") ^ -1 * P("\n")) + -1
  local starting_line_no = math.max(1, line_no - context)
  local num_lines = math.min(line_no - 1, context) + context + 1
  local line = (P(1) - end_of_line) ^ 0 * end_of_line
  local pattern = P("")
  for k = 1, starting_line_no - 1 do
    pattern = pattern * line
  end
  for i = 1, num_lines do
    pattern = pattern * (P(-1) + line / function(l)
      return {
        starting_line_no + i - 1,
        l
      }
    end)
  end
  local colors = require("ansicolors")
  local preview = Ct(pattern):match(lines)
  local max_len = 0
  for _index_0 = 1, #preview do
    local tuple = preview[_index_0]
    max_len = math.max(max_len, #tostring(tuple[1]))
  end
  local parts
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #preview do
      local _des_0 = preview[_index_0]
      local ln, lt
      ln, lt = _des_0[1], _des_0[2]
      local display_ln = ln + line_offset
      lt = tostring(lt:gsub("%s+$", "")) .. "\n"
      local spacer = (" "):rep(2 + max_len - #tostring(display_ln))
      local _value_0
      if line_no == ln then
        _value_0 = colors(tostring(highlight_color) .. tostring(display_ln) .. "%{reset}" .. tostring(spacer) .. tostring(lt))
      else
        _value_0 = colors("%{yellow}" .. tostring(display_ln) .. "%{reset}" .. tostring(spacer) .. tostring(lt))
      end
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    parts = _accum_0
  end
  return table.concat(parts)
end
local render_cosmo
render_cosmo = function(template, context, line_offset)
  local cosmo = require("sitegen.cosmo")
  local success, output_or_err
  if _VERSION == "Lua 5.1" and not jit then
    local s, render_fn = pcall(function()
      return cosmo.f(template)
    end)
    success, output_or_err = s, s and render_fn(context) or render_fn
  else
    success, output_or_err = pcall(function()
      return cosmo.f(template)(context)
    end)
  end
  if success then
    return output_or_err
  end
  local error_fragment
  local error_preview
  if type(output_or_err) == "string" then
    local line, position = output_or_err:match("syntax error in template at line (%d+) position (%d)")
    if line then
      error_preview = highlight_line(template, tonumber(line), 5, nil, line_offset)
    end
  end
  return throw_error("cosmo failed: " .. tostring(output_or_err) .. tostring(error_preview and "\n" .. tostring(error_preview) or ""))
end
local fill_ignoring_pre
fill_ignoring_pre = function(text, context)
  local P, R, S, V, Ct, C
  do
    local _obj_0 = require("lpeg")
    P, R, S, V, Ct, C = _obj_0.P, _obj_0.R, _obj_0.S, _obj_0.V, _obj_0.Ct, _obj_0.C
  end
  local string_patt
  string_patt = function(delim)
    delim = P(delim)
    return delim * (1 - delim) ^ 0 * delim
  end
  local strings = string_patt("'") + string_patt('"')
  local open = P("<code") * (strings + (1 - P(">"))) ^ 0 * ">"
  local close = P("</code>")
  local Code = V("Code")
  local code = P({
    Code,
    Code = open * (Code + (1 - close)) ^ 0 * close
  })
  code = code / function(text)
    return {
      "code",
      text
    }
  end
  local other = (1 - code) ^ 1 / function(text)
    return {
      "text",
      text
    }
  end
  local document = Ct((code + other) ^ 0)
  local parts = document:match(text)
  local line_offset = 0
  local filled
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #parts do
      local part = parts[_index_0]
      local t, body = unpack(part)
      if t == "text" then
        body = render_cosmo(body, context, line_offset)
      end
      line_offset = line_offset + count_lines(body)
      local _value_0 = body
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    filled = _accum_0
  end
  return table.concat(filled)
end
local setfenv = setfenv or function(fn, env)
  local name
  local i = 1
  while true do
    name = debug.getupvalue(fn, i)
    if not name or name == "_ENV" then
      break
    end
    i = i + 1
  end
  if name then
    debug.upvaluejoin(fn, i, (function()
      return env
    end), 1)
  end
  return fn
end
local getfenv = getfenv or function(fn)
  local i = 1
  while true do
    local name, val = debug.getupvalue(fn, i)
    if not (name) then
      break
    end
    if name == "_ENV" then
      return val
    end
    i = i + 1
  end
  return _G
end
local extend
extend = function(t, ...)
  assert(not getmetatable(t), "table already has metatable")
  local other = {
    ...
  }
  return setmetatable(t, {
    __index = function(self, key)
      for _index_0 = 1, #other do
        local ot = other[_index_0]
        local val = ot[key]
        if val ~= nil then
          return val
        end
      end
    end
  })
end
return {
  bound_fn = bound_fn,
  catch_error = catch_error,
  convert_pattern = convert_pattern,
  escape_patt = escape_patt,
  extend = extend,
  fill_ignoring_pre = fill_ignoring_pre,
  flatten_args = flatten_args,
  get_local = get_local,
  make_list = make_list,
  pass_error = pass_error,
  setfenv = setfenv,
  getfenv = getfenv,
  slugify = slugify,
  split = split,
  throw_error = throw_error,
  error_context = error_context,
  timed_call = timed_call,
  trim = trim,
  trim_leading_white = trim_leading_white,
  unpack = unpack,
  highlight_line = highlight_line,
  OrderSet = OrderSet,
  Stack = Stack
}
