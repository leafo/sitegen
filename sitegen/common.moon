
html = require "sitegen.html"
require "moon"

colors = {
  reset: 0
  bright: 1
  red: 31
  yellow: 33
}
colors = { name, string.char(27) .. "[" .. tostring(key) .. "m" for name, key in pairs colors }

make_bright = (color) ->
  (str) -> colors.bright .. colors[color] .. tostring(str) .. colors.reset

socket = nil
pcall ->
  socket = require "socket"

export *

timed_call = (fn) ->
  start = socket and socket.gettime!
  res = {fn!}
  socket and (socket.gettime! - start), unpack res

bright_red = make_bright"red"
bright_yellow = make_bright"yellow"

throw_error = (...) ->
  if coroutine.running()
    coroutine.yield { "error", ... }
  else
    error ...

catch_error = (fn) ->
  co = coroutine.create -> fn! and nil

  status, res = coroutine.resume co

  -- real error
  error debug.traceback co, res if not status

  -- something thrown
  if res
    print bright_red"Error:",  res[2]
    os.exit 1

  false

get_local = (name, level=4) ->
  locals = {}
  names = {}
  i = 1
  info = debug.getinfo level
  print "capturing scope for ", info.name or info.short_src

  while true
    lname, value = debug.getlocal(level, i)
    break if not lname
    print "->", lname, value
    table.insert names, lname
    locals[lname] = value
    i += 1

  print "locals:", table.concat names, ", "
  locals[name] if name

trim_leading_white = (str, leading) ->
  lines = split str, "\n"
  if #lines > 0
    first = lines[1]
    leading = leading or first\match"^(%s*)"

    for i, line in ipairs lines
      lines[i] = line\match("^"..leading.."(.*)$") or line

    if lines[#lines]\match "^%s*$"
      lines[#lines] = nil

  table.concat lines, "\n"

dumps = (...) ->
  print moon.dump ...

make_list = (item) ->
  type(item) == "table" and item or {item}

bound_fn = (cls, fn_name) ->
  (...) -> cls[fn_name] cls, ...

punct = "[%^$()%.%[%]*+%-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

convert_pattern = (patt) ->
  patt = patt\gsub "([.])", (item) ->
    "%" .. item

  patt\gsub "[*]", ".*"

slugify = (text) ->
  text = html.strip_tags text
  text = text\gsub "[&+]", " and "
  (text\lower!\gsub("%s+", "_")\gsub("[^%w_]", ""))

flatten_args = (...) ->
  accum = {}
  flatten = (tbl) ->
    for arg in *tbl
      if type(arg) == "table"
        flatten(arg)
      else
        table.insert accum, arg
  flatten {...}
  accum

split = (str, delim using nil) ->
  str ..= delim
  [part for part in str\gmatch "(.-)" .. escape_patt(delim)]

trim = (str) -> str\match "^%s*(.-)%s*$"

class OrderSet
  new: (items) =>
    @list = {}
    @set = {}
    if items
      for item in *items
        @add item

  add: (item) =>
    if @list[item] == nil
      table.insert @list, item
      @set[item] = #@list

  has: (item) =>
    @set[item] != nil

  each: =>
    coroutine.wrap ->
      for item in *@list
        coroutine.yield item

class Stack
  push: (item) =>
    self[#self + 1] = item

  pop: (item) =>
    len = #self
    with self[len]
      self[len] = nil

Path = (io) -> {
    set_io: (_io) -> io = _io

    -- move up a directory
    -- /hello/world -> /hello
    up: (path) ->
      path = path\gsub "/$", ""
      path = path\gsub "[^/]*$", ""
      path if path != ""

    exists: (path) ->
      file = io.open path
      file\close! and true if file

    normalize: (path) ->
      path\gsub "^%./", ""

    basepath: (path) ->
      path\match"^(.*)/[^/]*$" or "."

    filename: (path) ->
      path\match"([^/]*)$"

    write_file: (path, content) ->
      with io.open path, "w"
        \write content
        \close!

    mkdir: (path) ->
      os.execute ("mkdir -p %s")\format path

    copy: (src, dest) ->
      os.execute ("cp %s %s")\format src, dest

    join: (a, b) ->
      a = a\match"^(.*)/$" or a if a != "/"
      b = b\match"^/(.*)$" or b
      return b if a == ""
      return a if b == ""
      a .. "/" .. b
  }

Path = Path io

nil

