Site = require "sitegen.site"
colors = require "ansicolors"

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

{
  :create_site
  :create
  VERSION: "0.3"
}
