import trim_leading_white from require "sitegen.common"

get_yaml = ->
  local yaml
  pcall ->
    yaml = require "yaml"

  get_yaml = -> yaml
  yaml

parse_yaml_header = (text) ->
  s, e = text\find "\n%s*%-%-\n"

  if s
    header = text\sub 1, s - 1
    text = text\sub e

    header = trim_leading_white header
    header = get_yaml!.load header
    return text, header

  nil, "no header found"

parse_moonscript_header = (text) ->
  if text\match "^%s*{"
    import build_grammar from require "moonscript.parse"
    import V, Cp, Ct from require "lpeg"
    g = assert build_grammar V"TableLit" * Cp!
    _, pos = assert g\match(text)

    if type(pos) == "number"
      import loadstring from require "moonscript.base"
      fn = assert loadstring text\sub 1, pos - 1
      return text\sub(pos), fn!

extract_header = (text) ->
  if get_yaml!
    remaining, header = parse_yaml_header text
    if remaining
      return remaining, header

  remaining, header = parse_moonscript_header text
  if remaining
    return remaining, header


  text, {}

{ :extract_header }
