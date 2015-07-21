moonscript = require "moonscript"
cosmo = require "cosmo"

import throw_error, slugify from require "sitegen.common"
import log, get_site, get_site, columnize, Path from require "sitegen.cmd.util"

import extend, dump from require "moon"

default = {
  sitefile: "site.moon"
  files:
    page: [==[{
  date: "$eval{"require('date')()"}"
  $if{"title"}[[title: "$title"]]
}

Hello world!

]==]
    sitefile: [==[
sitegen = require "sitegen"
sitegen.create =>
  @title = $title
]==]
}


scope = (t={}) ->
  extend t, {
    eval: (arg) ->
      code = "return -> " .. arg[1]
      moonscript.loadstring(code)!!
    if: (arg) ->
      var_name = arg[1]
      cosmo.yield t if t[var_name]
      nil
  }

actions = {
  dump: -> print dump get_site!

  new: (title) ->
    if Path.exists default.sitefile
      throw_error "sitefile already exists: " .. default.sitefile

    title = ("%q")\format title or "Hello World"

    Path.mkdir"www"
    Path.mkdir"templates"

    site_moon = cosmo.f(default.files.sitefile) scope{:title}
    Path.write_file default.sitefile, site_moon

  page: (path, title)->
    get_site!

    if not title
      title = path
      path_part, title_part = title\match"^(.-)([^/]+)$"
      if path_part
        title = title_part
        path = path_part
      else
        path = '.'

    Path.mkdir path if Path.normalize(path) != ""

    -- iterater for all potential file names
    names = (fname, ext=".md") ->
      i = 0
      coroutine.wrap ->
        while true
          coroutine.yield if i == 0
            fname .. ext
          else
            table.concat {fname, "_", i, ext }
          i += 1

    full_path = nil
    for name in names slugify title
      full_path = Path.join path, name
      if not Path.exists full_path
        break

    Path.write_file full_path, cosmo.f(default.files.page) scope{:title}

  build: (...) ->
    files = {...}
    site = get_site!

    local filter
    if next files
      filter = {}
      for i, fname in ipairs files
        filter[site.sitefile\relativeize fname] = true

    site\write filter

  watch: ->
    site = get_site!
    w = require "sitegen.watch"

    with w.Watcher site
      \loop!

  help: ->
    print "Sitegen"
    print "usage: sitegen <action> [args]"
    print!
    print "Available actions:"

    print!
    print columnize {
      {"new", "Create a new site in the current directory"}
      {"build [input-files]", "Build (or rebuild) all pages, or only files"}
      {"page <path> [title]", "Create a new markdown page at path"}
      -- TODO: this should come from plugin
      {"deploy [host] [path]", "Deploy site to host over ssh (rsync)"}
      {"watch", "Compile pages automatically when inputs change (needs inotify)"}
    }
    print!
}

find_action = (name) ->
  return actions[name] if actions[name]
  site = get_site!
  site\plugin_actions![name]

{:actions, :find_action}


