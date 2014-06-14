-- provides a basic scope that lets your write to a buffer
-- and return it

html = require "sitegen.html"
import extend, bind_methods from require "moon"

scope = {
  write: (...) =>
    for thing in *{...}
      table.insert @buffer, tostring(thing)

  html: (...) =>
    @write html.build ...

  render: =>
    table.concat @buffer, "\n"
}

{
  make_context: (page) ->
    bind_methods extend { buffer: {} }, scope
}

