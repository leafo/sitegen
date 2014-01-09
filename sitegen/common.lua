local html = require("sitegen.html")
local colors = {
  reset = 0,
  bright = 1,
  red = 31,
  yellow = 33
}
colors = (function()
  local _tbl_0 = { }
  for name, key in pairs(colors) do
    _tbl_0[name] = string.char(27) .. "[" .. tostring(key) .. "m"
  end
  return _tbl_0
end)()
local make_bright
make_bright = function(color)
  return function(str)
    return colors.bright .. colors[color] .. tostring(str) .. colors.reset
  end
end
local socket = nil
pcall(function()
  socket = require("socket")
end)
timed_call = function(fn)
  local start = socket and socket.gettime()
  local res = {
    fn()
  }
  return socket and (socket.gettime() - start), unpack(res)
end
bright_red = make_bright("red")
bright_yellow = make_bright("yellow")
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
pass_error = function(obj, ...)
  if type(obj) == "table" and obj[1] == "error" then
    throw_error(unpack(obj, 2))
  end
  return obj, ...
end
catch_error = function(fn)
  local co = coroutine.create(function()
    return fn() and nil
  end)
  local status, res = coroutine.resume(co)
  if not status then
    error(debug.traceback(co, res))
  end
  if res then
    print(bright_red("Error:"), res[2])
    os.exit(1)
  end
  return false
end
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
dumps = function(...)
  local dump
  do
    local _table_0 = require("moon")
    dump = _table_0.dump
  end
  return print(moon.dump(...))
end
make_list = function(item)
  return type(item) == "table" and item or {
    item
  }
end
bound_fn = function(cls, fn_name)
  return function(...)
    return cls[fn_name](cls, ...)
  end
end
punct = "[%^$()%.%[%]*+%-?]"
escape_patt = function(str)
  return (str:gsub(punct, function(p)
    return "%" .. p
  end))
end
convert_pattern = function(patt)
  patt = patt:gsub("([.])", function(item)
    return "%" .. item
  end)
  return patt:gsub("[*]", ".*")
end
slugify = function(text)
  text = html.strip_tags(text)
  text = text:gsub("[&+]", " and ")
  return (text:lower():gsub("%s+", "_"):gsub("[^%w_]", ""))
end
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
split = function(str, delim)
  str = str .. delim
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for part in str:gmatch("(.-)" .. escape_patt(delim)) do
      _accum_0[_len_0] = part
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
trim = function(str)
  return str:match("^%s*(.-)%s*$")
end
do
  local _parent_0 = nil
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
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, items)
      self.list = { }
      self.set = { }
      if items then
        local _list_0 = items
        for _index_0 = 1, #_list_0 do
          local item = _list_0[_index_0]
          self:add(item)
        end
      end
    end,
    __base = _base_0,
    __name = "OrderSet",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
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
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  OrderSet = _class_0
end
do
  local _parent_0 = nil
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
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "Stack",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
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
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Stack = _class_0
end
Path = function(io)
  return {
    set_io = function(_io)
      io = _io
    end,
    up = function(path)
      path = path:gsub("/$", "")
      path = path:gsub("[^/]*$", "")
      if path ~= "" then
        return path
      end
    end,
    exists = function(path)
      local file = io.open(path)
      if file then
        return file:close() and true
      end
    end,
    normalize = function(path)
      return path:gsub("^%./", "")
    end,
    basepath = function(path)
      return path:match("^(.*)/[^/]*$") or "."
    end,
    filename = function(path)
      return path:match("([^/]*)$")
    end,
    write_file = function(path, content)
      do
        local _with_0 = io.open(path, "w")
        _with_0:write(content)
        _with_0:close()
        return _with_0
      end
    end,
    mkdir = function(path)
      return os.execute(("mkdir -p %s"):format(path))
    end,
    copy = function(src, dest)
      return os.execute(("cp %s %s"):format(src, dest))
    end,
    join = function(a, b)
      if a ~= "/" then
        a = a:match("^(.*)/$") or a
      end
      b = b:match("^/(.*)$") or b
      if a == "" then
        return b
      end
      if b == "" then
        return a
      end
      return a .. "/" .. b
    end
  }
end
Path = Path(io)
return nil
