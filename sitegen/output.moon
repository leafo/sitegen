
colors = require "ansicolors"

class Logger
  new: (@opts={}) =>

  _flatten: (...) =>
    table.concat [tostring p for p in *{...}], " "

  plain: (...) =>
    @print @_flatten ...

  notice: (prefix, ...) =>
    @print colors("%{bright}%{yellow}#{prefix}:%{reset} ") .. @_flatten ...

  positive: (prefix, ...) =>
    @print colors("%{bright}%{green}#{prefix}:%{reset} ") .. @_flatten ...

  negative: (prefix, ...) =>
    @print colors("%{bright}%{red}#{prefix}:%{reset} ") .. @_flatten ...

  --

  warn: (...) =>
    @notice "Warning", ...

  error: (...) =>
    @negative "Error", ...

  render: (source, dest) =>
    @positive "rendered", "#{source} -> #{dest}"

  build: (...) =>
    @positive "built", ...

  print: (...) =>
    return if @opts.silent
    print ...

{
  :Logger
}

