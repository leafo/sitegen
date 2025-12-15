discount = require "discount"

renderer = (md_source) ->
  assert discount md_source

render = (md_source) ->
  renderer md_source

set_renderer = (fn) ->
  assert type(fn) == "function", "renderer must be a function"
  renderer = fn

{ :render, :set_renderer }
