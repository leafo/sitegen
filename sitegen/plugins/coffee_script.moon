import Plugin from require "sitegen.plugin"

-- embed compiled coffeescript directly into the page
class CoffeeScriptPlugin extends Plugin
  tpl_helpers: { "render_coffee" }

  compile_coffee: (fname) =>
    p = io.popen ("coffee -c -p %s")\format fname
    p\read"*a"

  render_coffee: (arg) =>
    fname = unpack arg
    html.build ->
      script {
        type: "text/javascript"
        raw @compile_coffee fname
      }

