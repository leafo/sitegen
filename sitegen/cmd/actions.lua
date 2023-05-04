local moonscript = require("moonscript")
local cosmo = require("sitegen.cosmo")
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
  new = function(args)
    local title
    title = args.title
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
  page = function(args)
    local title, path
    title, path = args.title, args.path
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
  build = function(args)
    local files = args.input_files
    local site = get_site()
    local filter
    if files and next(files) then
      filter = { }
      for i, fname in ipairs(files) do
        filter[site.sitefile:relativeize(fname)] = true
      end
    end
    return site:write(filter)
  end,
  watch = function(args)
    local site = get_site()
    local w = require("sitegen.watch")
    do
      local _with_0 = w.Watcher(site)
      _with_0:loop()
      return _with_0
    end
  end
}
local find_action
find_action = function(name)
  if actions[name] then
    return actions[name]
  end
  for action_obj, call in get_site():plugin_actions() do
    local plugin_action_name = action_obj.action or action_obj.method
    if plugin_action_name == name then
      return call
    end
  end
end
return {
  actions = actions,
  find_action = find_action
}
