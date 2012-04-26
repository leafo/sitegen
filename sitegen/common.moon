
html = require "sitegen.html"
require "moon"

export *

colors = {
  reset: 0
  bright: 1
  red: 31
}
colors = { name, string.char(27) .. "[" .. tostring(key) .. "m" for name, key in pairs colors }

bright_red = (str) ->
  colors.bright .. colors.red .. tostring(str) .. colors.reset

throw_error = (...) ->
  if coroutine.running()
    coroutine.yield { "error", ... }
  else
    error ...

catch_error = (fn) ->
  co = coroutine.create fn

  status, res = coroutine.resume co

  -- real error
  error debug.traceback co, res if not status

  -- something thrown
  if res
    print bright_red"Error:",  res[2]
    true
  else
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

Path =
  exists: (path) ->
    file = io.open path
    with file
      file\close if file
  write_file: (path, content) ->
    with io.open path, "w"
      \write content
      \close!
  normalize: (path) ->
    path\gsub "^%./", ""
  basepath: (path) ->
    path\match"^(.*)/[^/]*$" or "."
  mkdir: (path) ->
    os.execute ("mkdir -p %s")\format path
  copy: (src, dest) ->
    os.execute ("cp %s %s")\format src, dest
  join: (a, b) ->
    a = a\match"^(.*)/$" or a
    b = b\match"^/(.*)$" or b
    return b if a == ""
    return a if b == ""
    a .. "/" .. b

