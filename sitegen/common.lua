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
  local lines = split(str, "\n")
  if #lines > 0 then
    local first = lines[1]
    leading = leading or first:match("^(%s*)")
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
  return str:match("^%s*(.-)%s*$")
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
local fill_ignoring_pre
fill_ignoring_pre = function(text, context)
  local cosmo = require("sitegen.cosmo")
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
  local filled
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #parts do
      local part = parts[_index_0]
      local t, body = unpack(part)
      if t == "text" then
        body = cosmo.f(body)(context)
      end
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
  timed_call = timed_call,
  trim = trim,
  trim_leading_white = trim_leading_white,
  unpack = unpack,
  OrderSet = OrderSet,
  Stack = Stack
}
