import trim_leading_white from require "sitegen.common"

load_header_table = (code) ->
  import loadstring from require "moonscript.base"
  fn = assert loadstring code
  fn!

-- lpeg moonscript (0.7 and earlier) expose the lpeg grammar pieces, so we can directly parse a table literal
match_header_grammar = (text, build_grammar) ->
  import V, Cp from require "lpeg"
  g = assert build_grammar V"TableLit" * Cp!
  _, pos = assert g\match(text)
  if type(pos) == "number"
    text\sub(pos), load_header_table text\sub 1, pos - 1

-- at this time, pgen moonscript can only parse whole file, so we do some
-- hackery
match_header_scan = (text, parse) ->
  init = 1
  while true
    brace = text\find "}", init, true
    error "failed to parse moonscript header" unless brace
    prefix = text\sub 1, brace
    tree = parse.string prefix
    if tree and #tree == 1 and type(tree[1]) == "table" and tree[1][1] == "table"
      return text\sub(brace + 1), load_header_table prefix
    init = brace + 1

parse_moonscript_header = (text) ->
  if text\match "^%s*{"
    parse = require "moonscript.parse"
    if parse.build_grammar
      match_header_grammar text, parse.build_grammar
    else
      match_header_scan text, parse

extract_header = (text) ->
  remaining, header = parse_moonscript_header text
  if remaining
    return remaining, header

  text, {}

{ :extract_header }
