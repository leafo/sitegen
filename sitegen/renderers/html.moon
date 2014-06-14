import Renderer from require "sitegen.renderer"

import convert_pattern from require "sitegen.common"

class HTMLRenderer extends Renderer
  ext: "html"
  pattern: convert_pattern "*.html"

