
-- needed to load plugin commands
import SiteFile from require "sitegen.site_file"

argparse = require "argparse"

parser = argparse "sitegen",
  "MoonScript powered static site generator"

parser\command_target "action"
parser\require_command false

with parser\command "new"
  \summary "Create a new site template in the current directory"
  \argument("title", "Title of site")\args "?"

with parser\command "build"
  \summary "Build (or rebuild) all pages, or listed inputs"
  \argument("input_files")\args "*"

with parser\command "page"
  \summary "Create a new markdown page at specified path"

  \argument "path"
  \argument("title", "Title of page")\args "?"

with parser\command "watch"
  \summary "Compile pages automatically when inputs change (needs inotify)"

with parser\command "dump"
  \summary "Debug dump of sitefile"
  \hidden true

-- attempt to insert plugin actions
local site
pcall -> site = SiteFile(logger_opts: { silent: true })\get_site!

-- install custom commands from the list of plugins in the current site file
if site
  for action_obj in site\plugin_actions!
    action = action_obj.action or action_obj.method
    continue unless action

    command = parser\command action
    if type(action_obj.argparser) == "function"
      action_obj.argparser command

parser\add_help_command! -- should be last
parser
