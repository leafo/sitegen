renderer = nil

set_backend = (name, ...) ->
  switch name
    when "discount"
      opts_list = {...}
      discount = require "discount"
      renderer = (md_source) ->
        assert discount md_source, unpack opts_list
    when "cmark"
      cmark = require "cmark"
      opts or= cmark.OPT_DEFAULT

      renderer = (md_source) ->
        document = assert cmark.parse_string md_source, opts
        assert cmark.render_html document, opts
    else
      error "unknown markdown backend: #{name}"

render = (md_source) ->
  unless renderer
    set_backend "discount"
  renderer md_source

set_renderer = (fn) ->
  assert type(fn) == "function", "renderer must be a function"
  renderer = fn


{ :render, :set_renderer, :set_backend }
