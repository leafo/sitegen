
colors = require "ansicolors"

class Logger
  new: (@opts={}) =>

  _flatten: (...) =>
    table.concat [tostring p for p in *{...}], " "

  plain: (...) =>
    @print @_flatten ...

  notice: (prefix, ...) =>
    @print colors("%{bright}%{yellow}#{prefix}:%{reset} ") .. @_flatten ...

  warn: (...) =>
    @print colors("%{bright}%{yellow}Warning:%{reset} ") .. @_flatten ...

  error: (...) =>
    @print colors("%{bright}%{red}Error:%{reset} ") .. @_flatten ...

  render: (source, dest) =>
    @print colors("%{bright}%{green}rendered:%{reset} ") .. "#{source} -> #{dest}"

  print: (...) =>
    return if @opts.silent
    print ...

{
  :Logger
}

