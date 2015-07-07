local moonscript = require("moonscript")
local cosmo = require("cosmo")
local throw_error, slugify
do
  local _obj_0 = require("sitegen.common")
  throw_error, slugify = _obj_0.throw_error, _obj_0.slugify
end
local log, get_site, columnize, Path
do
  local _obj_0 = require("sitegen.cmd.util")
  log, get_site, get_site, columnize, Path = _obj_0.log, _obj_0.get_site, _obj_0.get_site, _obj_0.columnize, _obj_0.Path
end
local extend, dump
do
  local _obj_0 = require("moon")
  extend, dump = _obj_0.extend, _obj_0.dump
end
local default = {
  sitefile = "site.moon",
  files = {
    page = [==[{
  date: "$eval{"require('date')()"}"
  $if{"title"}[[title: "$title"]]
}

Hello world!

]==],
    sitefile = [==[sitegen = require "sitegen"
sitegen.create =>
  @title = $title
]==]
  }
}
local scope
scope = function(t)
  if t == nil then
    t = { }
  end
  return extend(t, {
    eval = function(arg)
      local code = "return -> " .. arg[1]
      return moonscript.loadstring(code)()()
    end,
    ["if"] = function(arg)
      local var_name = arg[1]
      if t[var_name] then
        cosmo.yield(t)
      end
      return nil
    end
  })
end
local actions = {
  dump = function()
    return print(dump(get_site()))
  end,
  new = function(title)
    if Path.exists(default.sitefile) then
      throw_error("sitefile already exists: " .. default.sitefile)
    end
    title = ("%q"):format(title or "Hello World")
    Path.mkdir("www")
    Path.mkdir("templates")
    local site_moon = cosmo.f(default.files.sitefile)(scope({
      title = title
    }))
    return Path.write_file(default.sitefile, site_moon)
  end,
  page = function(path, title)
    get_site()
    if not title then
      title = path
      local path_part, title_part = title:match("^(.-)([^/]+)$")
      if path_part then
        title = title_part
        path = path_part
      else
        path = '.'
      end
    end
    if Path.normalize(path) ~= "" then
      Path.mkdir(path)
    end
    local names
    names = function(fname, ext)
      if ext == nil then
        ext = ".md"
      end
      local i = 0
      return coroutine.wrap(function()
        while true do
          coroutine.yield((function()
            if i == 0 then
              return fname .. ext
            else
              return table.concat({
                fname,
                "_",
                i,
                ext
              })
            end
          end)())
          i = i + 1
        end
      end)
    end
    local full_path = nil
    for name in names(slugify(title)) do
      full_path = Path.join(path, name)
      if not Path.exists(full_path) then
        break
      end
    end
    return Path.write_file(full_path, cosmo.f(default.files.page)(scope({
      title = title
    })))
  end,
  deploy = function(host, path)
    local site = get_site()
    local deploy = site:get_plugin("sitegen.plugins.deploy")
    if not (deploy) then
      throw_error("deploy plugin not initialized")
    end
    host, path = deploy.host, deploy.path
    if not (host) then
      throw_error("need host")
    end
    if not (path) then
      throw_error("need path")
    end
    log("uploading to:", host, path)
    return deploy:sync()
  end,
  build = function(...)
    local files = {
      ...
    }
    local site = get_site()
    local filter
    if next(files) then
      filter = { }
      for i, fname in ipairs(files) do
        filter[site.sitefile:relativeize(fname)] = true
      end
    end
    return site:write(filter)
  end,
  watch = function()
    local site = get_site()
    local w = require("sitegen.watch")
    do
      local _with_0 = w.Watcher(site)
      _with_0:loop()
      return _with_0
    end
  end,
  help = function()
    print("Sitegen")
    print("usage: sitegen <action> [args]")
    print()
    print("Available actions:")
    print()
    print(columnize({
      {
        "new",
        "Create a new site in the current directory"
      },
      {
        "build [input-files]",
        "Build (or rebuild) all pages, or only files"
      },
      {
        "page <path> [title]",
        "Create a new markdown page at path"
      },
      {
        "deploy [host] [path]",
        "Deploy site to host over ssh (rsync)"
      },
      {
        "watch",
        "Compile pages automatically when inputs change (needs inotify)"
      }
    }))
    return print()
  end
}
local find_action
find_action = function(name)
  if actions[name] then
    return actions[name]
  end
  local site = get_site()
  return site:plugin_actions()[name]
end
return {
  actions = actions,
  find_action = find_action
}
