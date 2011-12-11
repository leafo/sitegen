require "sitegen"

extra = require"sitegen.extra"
html = require"sitegen.html"

site = sitegen.create_site =>
  extra.PygmentsPlugin.custom_highlighters.moon = (code_text) =>
    html.build ->
      pre {
        class: "moon-code"
        code_text
      }

  deploy_to "leaf@leafo.net", "www/sitegen"
  add "../doc/plugins.md"

  @title = "Sitegen"
  @url = "http://leafo.net/sitegen/"

site\write!
