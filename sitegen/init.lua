local Site = require("sitegen.site")
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
  do
    local _with_0 = site
    _with_0:init_from_fn(init_fn)
    if not (_with_0.autoadd_disabled) then
      _with_0.scope:search("*md")
    end
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
  plugins = plugins,
  register_plugin = register_plugin
}
