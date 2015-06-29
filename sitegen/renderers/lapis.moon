import Renderer from require "sitegen.renderer"

moonscript = require "moonscript.base"

import convert_pattern from require "sitegen.common"

class LapisRenderer extends Renderer
  ext: "html"
  pattern: convert_pattern "*.moon"

  render: (text, page) =>
    fn = assert moonscript.loadstring text
    widget = fn!
    widget\render_to_string!, {}


