import split, Path from require "sitegen.common"
import SiteFile from require "sitegen.site_file"

log = (...) ->
  print "->", ...

get_site = -> SiteFile!\get_site!

annotate = (obj, verbs) ->
  setmetatable {}, {
    __newindex: (name, value) =>
      obj[name] = value
    __index: (name) =>
      fn =  obj[name]
      return fn if not type(fn) == "function"
      if verbs[name]
        (...) ->
          fn ...
          first = ...
          log verbs[name], first
      else
        fn
  }

Path = annotate Path, {
  mkdir: "made directory"
  write_file: "wrote"
}

-- wrap test based on tokens
wrap_text = (text, indent=0, max_width=80) ->
  width = max_width - indent
  words = split text, " "
  pos = 1
  lines = {}
  while pos <= #words
    line_len = 0
    line = {}
    while true
      word = words[pos]
      break if word == nil
      error "can't wrap text, words too long" if #word > width
      break if line_len + #word > width

      pos += 1
      table.insert line, word
      line_len += #word + 1 -- +1 for the space

    table.insert lines, table.concat line, " "

  table.concat lines, "\n" .. (" ")\rep indent

columnize = (rows, indent=2, padding=4) ->
  max = 0
  max = math.max max, #row[1] for row in *rows

  left_width = indent + padding + max

  formatted = for row in *rows
    padd = (max - #row[1]) + padding
    table.concat {
      (" ")\rep indent
      row[1]
      (" ")\rep padd
      wrap_text row[2], left_width
    }

  table.concat formatted, "\n"


{ :log, :Path, :annotate, :get_site, :columnize }
