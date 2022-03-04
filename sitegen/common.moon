
socket = nil
pcall ->
  socket = require "socket"

unpack = unpack or table.unpack

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
  import Logger from require "sitegen.output"
  co = coroutine.create -> fn! and nil

  status, res = coroutine.resume co

  -- real error
  error debug.traceback co, res if not status

  -- something thrown
  if res
    Logger!\error res[2]
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

punct = "[%^$()%.%[%]*+%-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

split = (str, delim) ->
  str ..= delim
  [part for part in str\gmatch "(.-)" .. escape_patt(delim)]

trim_leading_white = (str, leading) ->
  assert type(str) == "string", "Expecting string for trim_leading_white"

  lines = split str, "\n"
  if #lines > 0
    unless leading
      for line in *lines
        continue if line\match "^%s*$"
        leading = line\match"^(%s*)"
        break

    -- failed to find leading whitespace, just return original string
    unless leading
      return str

    for i, line in ipairs lines
      lines[i] = line\match("^"..leading.."(.*)$") or line

    if lines[#lines]\match "^%s*$"
      lines[#lines] = nil

  table.concat lines, "\n"

make_list = (item) ->
  type(item) == "table" and item or {item}

bound_fn = (cls, fn_name) ->
  (...) -> cls[fn_name] cls, ...

convert_pattern = (patt) ->
  patt = patt\gsub "([.])", (item) ->
    "%" .. item

  patt\gsub "[*]", ".*"

slugify = (text) ->
  html = require "sitegen.html"
  text = html.strip_tags text
  text = text\gsub "[&+]", " and "
  (text\gsub("[%s_]+", "-")\gsub("[^%w%-]+", "")\gsub("-+", "-"))\lower!

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


highlight_line = (lines, line_no, context=2, highlight_color="%{bright}%{red}") ->
  assert line_no, "missing line no"

  import P, Cs, Ct from require "lpeg"

  end_of_line = (P"\r"^-1 * P"\n") + -1

  starting_line_no = math.max 1, line_no - context
  num_lines = math.min(line_no - 1, context) + context + 1

  line = (P(1) - end_of_line)^0 * end_of_line

  pattern = P""

  for k=1, starting_line_no - 1
    pattern *= line

  for i=1,num_lines
    -- this is crappy short ciruit that just parses end of document over and over
    pattern *= P(-1) + line / (l) -> {starting_line_no + i - 1, l}

  colors = require "ansicolors"

  preview = Ct(pattern)\match lines

  max_len = 0
  for tuple in *preview
    max_len = math.max max_len, #tostring(tuple[1])

  parts = for {ln, lt} in *preview
    lt = "#{lt\gsub("%s+$", "")}\n"

    spacer = " "\rep 2 + max_len - #tostring(ln)
    if line_no == ln
      colors"#{highlight_color}#{ln}%{reset}#{spacer}#{lt}"
    else
      colors"%{yellow}#{ln}%{reset}#{spacer}#{lt}"

  table.concat parts

-- this tries to parse the error message to make a more meaningful error message
render_cosmo = (template, context) ->
  cosmo = require "sitegen.cosmo"

  success, output_or_err = pcall ->
    cosmo.f(template) context

  if success
    return output_or_err

  local error_fragment

  error_preview = if type(output_or_err) == "string"
    line, position = output_or_err\match "syntax error in template at line (%d+) position (%d)"
    highlight_line template, tonumber(line), 5

  throw_error "cosmo failed: #{output_or_err}#{error_preview and "\n#{error_preview}" or ""}"

-- replace all template vars in text not contained in a
-- code block
fill_ignoring_pre = (text, context) ->
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

    if t == "text"
      body = render_cosmo body, context

    body

  table.concat filled

setfenv = setfenv or (fn, env) ->
  local name
  i = 1
  while true
    name = debug.getupvalue fn, i
    break if not name or name == "_ENV"
    i += 1

  if name
    debug.upvaluejoin fn, i, (-> env), 1

  fn

getfenv = getfenv or (fn) ->
  i = 1
  while true
    name, val = debug.getupvalue fn, i
    break unless name
    return val if name == "_ENV"
    i += 1
  _G

extend = (t, ...) ->
  assert not getmetatable(t), "table already has metatable"
  other = {...}

  setmetatable t, {
    __index: (key) =>
      for ot in *other
        val = ot[key]
        if val != nil
          return val

  }


{
  :bound_fn
  :catch_error
  :convert_pattern
  :escape_patt
  :extend
  :fill_ignoring_pre
  :flatten_args
  :get_local
  :make_list
  :pass_error
  :setfenv, :getfenv
  :slugify
  :split
  :throw_error
  :timed_call
  :trim
  :trim_leading_white
  :unpack

  :highlight_line

  :OrderSet
  :Stack
}

