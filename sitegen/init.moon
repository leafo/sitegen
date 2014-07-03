Site = require "sitegen.site"
import insert from require "table"

default_plugins = {
  "sitegen.plugins.feed"
  "sitegen.plugins.blog"
  "sitegen.plugins.deploy"
  "sitegen.plugins.indexer"
  "sitegen.plugins.analytics"
  "sitegen.plugins.coffee_script"
  "sitegen.plugins.pygments"
  "sitegen.plugins.dump"
}

plugins = {}

create_site = (init_fn, site=Site!) ->
  with site
    \init_from_fn init_fn
    .scope\search "*md" unless .autoadd_disabled

register_plugin = (plugin) ->
  plugin\on_register! if plugin.on_register
  insert plugins, plugin

for pname in *default_plugins
  register_plugin require pname

{
  :create_site
  :plugins, :register_plugin
}
