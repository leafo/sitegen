local renderer = nil
local set_backend
set_backend = function(name, ...)
  local _exp_0 = name
  if "discount" == _exp_0 then
    local opts_list = {
      ...
    }
    local discount = require("discount")
    renderer = function(md_source)
      return assert(discount(md_source, unpack(opts_list)))
    end
  elseif "cmark" == _exp_0 then
    local cmark = require("cmark")
    local opts = opts or cmark.OPT_DEFAULT
    renderer = function(md_source)
      local document = assert(cmark.parse_string(md_source, opts))
      return assert(cmark.render_html(document, opts))
    end
  else
    return error("unknown markdown backend: " .. tostring(name))
  end
end
local render
render = function(md_source)
  if not (renderer) then
    set_backend("cmark")
  end
  return renderer(md_source)
end
local set_renderer
set_renderer = function(fn)
  assert(type(fn) == "function", "renderer must be a function")
  renderer = fn
end
return {
  render = render,
  set_renderer = set_renderer,
  set_backend = set_backend
}
