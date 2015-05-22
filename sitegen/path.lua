local io = io
local needs_shell_escape
needs_shell_escape = function(str)
  return not not str:match("[^%w_-]")
end
local shell_escape
shell_escape = function(str)
  return str:gsub("'", "''")
end
local up, exists, normalize, basepath, filename, write_file_safe, write_file, read_file, mkdir, rmdir, copy, join, _prepare_command, exec, read_exec, relative_to, annotate
up = function(path)
  path = path:gsub("/$", "")
  path = path:gsub("[^/]*$", "")
  if path ~= "" then
    return path
  end
end
exists = function(path)
  local file = io.open(path)
  if file then
    return file:close() and true
  end
end
normalize = function(path)
  return (path:gsub("^%./", ""))
end
basepath = function(path)
  return (path:match("^(.*)/[^/]*$") or ".")
end
filename = function(path)
  return (path:match("([^/]*)$"))
end
write_file_safe = function(path, content, check_exists)
  if check_exists == nil then
    check_exists = false
  end
  if check_exists and exists(path) then
    return nil, "file already exists `" .. tostring(path) .. "`"
  end
  do
    local prefix = path:match("^(.+)/[^/]+$")
    if prefix then
      if not (exists(prefix)) then
        mkdir(prefix)
      end
    end
  end
  write_file(path, content)
  return true
end
write_file = function(path, content)
  assert(content, "trying to write `" .. tostring(path) .. "` with no content")
  do
    local _with_0 = io.open(path, "w")
    _with_0:write(content)
    _with_0:close()
    return _with_0
  end
end
read_file = function(path)
  local file = io.open(path)
  if not (file) then
    error("file doesn't exist `" .. tostring(path) .. "'")
  end
  do
    local _with_0 = file:read("*a")
    file:close()
    return _with_0
  end
end
mkdir = function(path)
  return os.execute("mkdir -p '" .. tostring(shell_escape(path)) .. "'")
end
rmdir = function(path)
  return os.execute("rm -r '" .. tostring(shell_escape(path)) .. "'")
end
copy = function(src, dest)
  return os.execute("cp '" .. tostring(shell_escape(src)) .. "' '" .. tostring(shell_escape(dest)) .. "'")
end
join = function(a, b)
  assert(a, "missing left argument to Path.join")
  assert(b, "missing right argument to Path.join")
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
_prepare_command = function(cmd, ...)
  local args
  do
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local x = _list_0[_index_0]
      if needs_shell_escape(x) then
        _accum_0[_len_0] = "'" .. tostring(shell_escape(x)) .. "'"
      else
        _accum_0[_len_0] = x
      end
      _len_0 = _len_0 + 1
    end
    args = _accum_0
  end
  args = table.concat(args, " ")
  return tostring(cmd) .. " " .. tostring(args)
end
exec = function(cmd, ...)
  return os.execute(_prepare_command(cmd, ...))
end
read_exec = function(cmd, ...)
  local f = assert(io.popen(_prepare_command(cmd, ...), "r"))
  do
    local _with_0 = f:read("*a")
    f:close()
    return _with_0
  end
end
relative_to = function(self, prefix)
  local methods = {
    "mkdir",
    "read_file",
    "write_file",
    "write_file_safe",
    "exists"
  }
  local prefixed
  prefixed = function(fn)
    return function(path, ...)
      return self[fn](self.join(prefix, path), ...)
    end
  end
  local m = setmetatable((function()
    local _tbl_0 = { }
    for _index_0 = 1, #methods do
      m = methods[_index_0]
      _tbl_0[m] = prefixed(m)
    end
    return _tbl_0
  end)(), {
    __index = self
  })
  m.full_path = function(path)
    return self.join(prefix, path)
  end
  m.strip_prefix = function(path)
    local escape_patt
    escape_patt = require("sitegen.common").escape_patt
    return path:gsub("^" .. tostring(escape_patt(prefix)) .. "/?", "")
  end
  m.get_prefix = function()
    return prefix
  end
  m.set_prefix = function(p)
    prefix = p
  end
  return m
end
annotate = function(self)
  local wrap_module
  wrap_module = function(obj, verbs)
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
            print(verbs[name], (...))
            return fn(...)
          end
        else
          return fn
        end
      end
    })
  end
  local colors = require("ansicolors")
  return wrap_module(self, {
    mkdir = colors("%{bright}%{magenta}made directory%{reset}"),
    write_file = colors("%{bright}%{yellow}wrote%{reset}"),
    write_file_safe = colors("%{bright}%{yellow}wrote%{reset}"),
    read_file = colors("%{bright}%{green}read%{reset}"),
    exists = colors("%{bright}%{cyan}exists?%{reset}"),
    exec = colors("%{bright}%{red}exec%{reset}"),
    read_exec = colors("%{bright}%{red}exec%{reset}")
  })
end
return {
  up = up,
  exists = exists,
  normalize = normalize,
  basepath = basepath,
  filename = filename,
  write_file = write_file,
  write_file_safe = write_file_safe,
  mkdir = mkdir,
  rmdir = rmdir,
  copy = copy,
  join = join,
  read_file = read_file,
  shell_escape = shell_escape,
  exec = exec,
  read_exec = read_exec,
  relative_to = relative_to,
  annotate = annotate
}
