moonscript = require "moonscript"
cosmo = require "sitegen.cosmo"

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
  dump: (args) -> print dump get_site args.site_module_name

  new: (args) ->
    {:title} = args

    if Path.exists default.sitefile
      throw_error "sitefile already exists: " .. default.sitefile

    title = ("%q")\format title or "Hello World"

    Path.mkdir"www"
    Path.mkdir"templates"

    site_moon = cosmo.f(default.files.sitefile) scope{:title}
    Path.write_file default.sitefile, site_moon

  page: (args) ->
    {:title, :path} = args

    get_site args.site_module_name

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

  build: (args) ->
    files = args.input_files
    site = get_site args.site_module_name

    local filter
    if files and next files
      filter = {}
      for i, fname in ipairs files
        filter[site.sitefile\relativeize fname] = true

    site\write filter

  watch: (args) ->
    site = get_site args.site_module_name
    w = require "sitegen.watch"

    with w.Watcher site
      \loop!

  render: (args) ->
    site = get_site args.site_module_name

    -- Disable cache file I/O entirely (read and write)
    site.cache.disabled = true

    -- Create anonymous page (not registered in site file)
    file = site.sitefile\relativeize args.file
    page = site\Page file

    -- Handle --no-template flag
    if args.no_template
      page.meta.template = false

    -- Render and output to stdout
    content = page\render!
    io.stdout\write content

}

-- return function to be called for command line action
-- function should take one argument, the args object returned by argparse
find_action = (name, site_module_name=nil) ->
  return actions[name] if actions[name]

  for action_obj, call in get_site(site_module_name)\plugin_actions!
    plugin_action_name = action_obj.action or action_obj.method
    if plugin_action_name == name
      return call

{:actions, :find_action}


