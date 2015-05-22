sitegen = require "sitegen"

tools = require "sitegen.tools"

scssphp = tools.system_command "sassc < %s > %s", "css"
coffeescript = tools.system_command "coffee -c -s < %s > %s", "js"

sitegen.create =>
  deploy_to "leaf@leafo.net", "www/sitegen"

  build scssphp, "style.scss", "style.css"
  build coffeescript, "main.coffee", "main.js"

  add "index.md"
  add "../doc/plugins.md"

  @title = "Sitegen"
  @url = "http://leafo.net/sitegen/"

