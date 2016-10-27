sitegen = require "sitegen"

tools = require "sitegen.tools"

sassc = tools.system_command "sassc < %s > %s", "css"
coffeescript = tools.system_command "coffee -c -s < %s > %s", "js"

sitegen.create =>
  deploy_to "leaf@leafo.net", "www/sitegen"

  build sassc, "style.scss", "style.css"
  build coffeescript, "main.coffee", "main.js"

  add "index.md"
  add "../doc/plugins.md"
  add "../doc/creating_a_plugin.md"
  add "../doc/html_helpers.md"
  add "../doc/renderers_markdown.md"

  @title = "Sitegen"
  @url = "http://leafo.net/sitegen/"

