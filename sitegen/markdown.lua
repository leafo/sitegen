local discount = require("discount")
local renderer
renderer = function(md_source)
  return assert(discount(md_source))
end
local render
render = function(md_source)
  return renderer(md_source)
end
local set_renderer
set_renderer = function(fn)
  assert(type(fn) == "function", "renderer must be a function")
  renderer = fn
end
return {
  render = render,
  set_renderer = set_renderer
}
