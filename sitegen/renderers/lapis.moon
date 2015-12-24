import Renderer from require "sitegen.renderer"

moonscript = require "moonscript.base"

class LapisRenderer extends Renderer
  source_ext: "moon"
  ext: "html"

  load: (source, fname) =>
    chunk_name = if fname
      "@#{fname}"

    fn = assert moonscript.loadstring source, chunk_name
    widget = fn!
    ((page) ->
      w = widget(:page, site: page.site)
      w\include_helper page.tpl_scope
      w\render_to_string!), widget.options
