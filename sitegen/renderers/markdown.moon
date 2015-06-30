import Renderer from require "sitegen.renderer"
 
amp_temp = "0000sitegen_markdown00amp0000"

class MarkdownRenderer extends require "sitegen.renderers.html"
  source_ext: "md"
  ext: "html"

  pre_render: {}

  render: (page, md_source) =>
    discount = require "discount"

    for filter in *@pre_render
      md_source = filter md_source, page

    -- markdown encodes $ but we want them to pass thorugh so cosmo can pick
    -- them up, so we temporarily replace them :)
    md_source = md_source\gsub "%$", amp_temp
    html_source = assert discount md_source
    html_source = html_source\gsub amp_temp, "$"

    super page, html_source


