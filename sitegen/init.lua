local Site = require("sitegen.site")
local colors = require("ansicolors")
local insert
insert = require("table").insert
local default_plugins = {
  "sitegen.plugins.feed",
  "sitegen.plugins.blog",
  "sitegen.plugins.deploy",
  "sitegen.plugins.indexer",
  "sitegen.plugins.analytics",
  "sitegen.plugins.coffee_script",
  "sitegen.plugins.pygments",
  "sitegen.plugins.dump"
}
local plugins = { }
local create_site
create_site = function(init_fn, site)
  if site == nil then
    site = Site()
  end
  io.stderr:write(colors("%{bright}%{red}WARNING: %{reset}sitegen.create_site is deprecated, use create and add markdown files manually.\n"))
  do
    local _with_0 = site
    _with_0:init_from_fn(init_fn)
    if not (_with_0.autoadd_disabled) then
      _with_0.scope:search("*md")
    end
    return _with_0
  end
end
local create
create = function(init_fn, site)
  if site == nil then
    site = Site()
  end
  assert(init_fn, "Attempted to create site without initialization function")
  do
    local _with_0 = site
    _with_0:init_from_fn(init_fn)
    return _with_0
  end
end
local register_plugin
register_plugin = function(plugin)
  if plugin.on_register then
    plugin:on_register()
  end
  return insert(plugins, plugin)
end
for _index_0 = 1, #default_plugins do
  local pname = default_plugins[_index_0]
  register_plugin(require(pname))
end
return {
  create_site = create_site,
  create = create,
  plugins = plugins,
  register_plugin = register_plugin
}
