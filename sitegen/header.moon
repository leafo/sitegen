-- parses header
yaml = require "yaml"

require "sitegen.common"

parse_header = (header) ->
  header = trim_leading_white header
  yaml.load header

extract_header = (text) ->
  local header
  s, e = text\find "%-%-\n"
  if s
    header = parse_header text\sub 1, s - 1
    text = text\sub e

  text, header or {}

{ :extract_header, :parse_header, :trim_front }
