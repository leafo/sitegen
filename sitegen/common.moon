
socket = nil
pcall ->
  socket = require "socket"

local *

timed_call = (fn) ->
  start = socket and socket.gettime!
  res = {fn!}
  socket and (socket.gettime! - start), unpack res


throw_error = (...) ->
  if coroutine.running()
    coroutine.yield { "error", ... }
  else
    error ...

pass_error = (obj, ...) ->
  if type(obj) == "table" and obj[1] == "error"
    throw_error unpack obj, 2
  obj, ...

catch_error = (fn) ->
  import bright_red from require "sitegen.output"
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
  html = require "sitegen.html"
  text = html.strip_tags text
  text = text\gsub "[&+]", " and "
  (text\lower!\gsub("%s+", "_")\gsub("[^%w_]", ""))

flatten_args = (...) ->
  accum = {}
  options = {}

  flatten = (tbl) ->
    for k,v in pairs tbl
      if type(k) == "number"
        if type(v) == "table"
          flatten(v)
        else
          table.insert accum, v
      else
        options[k] = v
  flatten {...}
  accum, options

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

-- replace all template vars in text not contained in a
-- code block
fill_ignoring_pre = (text, context) ->
  cosmo = require "cosmo"
  import P, R, S, V, Ct, C from require "lpeg"

  string_patt = (delim) ->
    delim = P(delim)
    delim * (1 - delim)^0 * delim

  strings = string_patt"'" + string_patt'"'

  open = P"<code" * (strings + (1 - P">"))^0 * ">"
  close = P"</code>"

  Code = V"Code"
  code = P{
    Code
    Code: open * (Code + (1 - close))^0 * close
  }

  code = code / (text) -> {"code", text}

  other = (1 - code)^1 / (text) ->
    {"text", text}

  document = Ct((code + other)^0)
  -- parse to parts to avoid metamethod/c-call boundary
  parts = document\match text
  filled = for part in *parts
    t, body = unpack part
    body = cosmo.f(body) context if t == "text"
    body

  table.concat filled

{
  :timed_call
  :throw_error
  :pass_error
  :catch_error
  :get_local
  :trim_leading_white
  :make_list
  :bound_fn
  :escape_patt
  :convert_pattern
  :slugify
  :flatten_args
  :split
  :trim
  :fill_ignoring_pre

  :OrderSet
  :Stack
  Path: Path(io)
}

