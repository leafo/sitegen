
html = require "sitegen.html"

export *

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

