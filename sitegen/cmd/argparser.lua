local SiteFile
SiteFile = require("sitegen.site_file").SiteFile
local argparse = require("argparse")
local parser = argparse("sitegen", "MoonScript powered static site generator")
parser:option("-m --site-module", "Load site from a Lua/MoonScript module via require instead of searching for a site.moon file"):target("site_module_name")
parser:command_target("action")
parser:require_command(false)
do
  local _with_0 = parser:command("new")
  _with_0:summary("Create a new site template in the current directory")
  _with_0:argument("title", "Title of site"):args("?")
end
do
  local _with_0 = parser:command("build")
  _with_0:summary("Build (or rebuild) all pages, or listed inputs")
  _with_0:argument("input_files"):args("*")
end
do
  local _with_0 = parser:command("page")
  _with_0:summary("Create a new markdown page at specified path")
  _with_0:argument("path")
  _with_0:argument("title", "Title of page"):args("?")
end
do
  local _with_0 = parser:command("watch")
  _with_0:summary("Compile pages automatically when inputs change (needs inotify)")
end
do
  local _with_0 = parser:command("dump")
  _with_0:summary("Debug dump of sitefile")
  _with_0:hidden(true)
end
do
  local _with_0 = parser:command("render")
  _with_0:summary("Render a single file to stdout")
  _with_0:argument("file")
  _with_0:flag("--no-template", "Skip template wrapping")
end
local site
pcall(function()
  site = SiteFile({
    logger_opts = {
      silent = true
    }
  }):get_site()
end)
if site then
  for action_obj in site:plugin_actions() do
    local _continue_0 = false
    repeat
      local action = action_obj.action or action_obj.method
      if not (action) then
        _continue_0 = true
        break
      end
      local command = parser:command(action)
      if type(action_obj.argparser) == "function" then
        action_obj.argparser(command)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
parser:add_help_command()
return parser
