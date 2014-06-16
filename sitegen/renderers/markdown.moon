import Renderer from require "sitegen.renderer"

import convert_pattern from require "sitegen.common"

amp_temp = "#{os.time!}amp#{os.time!}"

class MarkdownRenderer extends Renderer
  ext: "html"
  pattern: convert_pattern "*.md"
  pre_render: {}

  render: (text, page) =>
    discount = require "discount"

    text, header = @parse_header text

    for filter in *@pre_render
      text = filter text, page

    -- markdown encodes $ but we want them to pass thorugh so cosmo can pick
    -- them up, so we temporarily replace them :)
    text = text\gsub "%$", amp_temp
    text = assert discount text
    text = text\gsub amp_temp, "$"

    text, header


