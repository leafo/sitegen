Site = require "sitegen.site"
colors = require "ansicolors"

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

-- legacy create that adds all md files
create_site = (init_fn, site=Site!) ->
  io.stderr\write colors "%{bright}%{red}WARNING: %{reset}sitegen.create_site is deprecated, use create and add markdown files manually.\n"
  with site
    \init_from_fn init_fn
    .scope\search "*md" unless .autoadd_disabled

create = (init_fn, site=Site!) ->
  assert init_fn, "Attempted to create site without initialization function"
  with site
    \init_from_fn init_fn

register_plugin = (plugin) ->
  plugin\on_register! if plugin.on_register
  insert plugins, plugin

for pname in *default_plugins
  register_plugin require pname

{
  :create_site
  :create
  :plugins, :register_plugin
}
