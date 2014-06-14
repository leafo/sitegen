import Renderer from require "sitegen.renderer"

import convert_pattern from require "sitegen.common"

class MarkdownRenderer extends Renderer
  ext: "html"
  pattern: convert_pattern "*.md"
  pre_render: {}

  render: (text, page) =>
    discount = require "discount"

    text, header = @parse_header text

    for filter in *@pre_render
      text = filter text, page

    discount(text), header

