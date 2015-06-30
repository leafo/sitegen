import Renderer from require "sitegen.renderer"

moonscript = require "moonscript.base"

class LapisRenderer extends Renderer
  source_ext: "moon"
  ext: "html"

  load: (source) =>
    fn = assert moonscript.loadstring source
    widget = fn!
    ((page) ->
      w = widget(:page)
      w\include_helper page.tpl_scope
      w\render_to_string!), widget.options
