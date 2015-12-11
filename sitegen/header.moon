import trim_leading_white from require "sitegen.common"

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
  remaining, header = parse_moonscript_header text
  if remaining
    return remaining, header

  text, {}

{ :extract_header }
