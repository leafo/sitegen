import Renderer from require "sitegen.renderer"

amp_temp = "0000sitegen_markdown00amp0000"

escape_cosmo = (str) ->
  escapes = {}
  import P, R, Cmt, Cs from require "lpeg"

  counter = 0

  alphanum = R "az", "AZ", "09", "__"
  -- TODO: this doesn't support nesting
  -- TODO: this doesn't escpae the blocks
  cosmo = P"$" * alphanum^1 * P"{" * (P(1) - "}")^0 * P"}" / (tpl) ->
    counter += 1
    key = "#{amp_temp}.#{counter}"
    escapes[key] = tpl
    key

  pat = Cs (cosmo + P(1))^0 * P(-1)
  str = pat\match(str) or str, escapes
  str, escapes

unescap_cosmo = (str, vals) ->

-- Converts input from markdown, then passes through cosmo filter from HTML
-- renderer
class MarkdownRenderer extends require "sitegen.renderers.html"
  source_ext: "md"
  ext: "html"

  pre_render: {}

  render: (page, md_source) =>
    discount = require "discount"

    for filter in *@pre_render
      md_source = filter md_source, page

    -- require("moon").p {
    --   escape_cosmo md_source
    -- }

    -- markdown encodes $ but we want them to pass thorugh so cosmo can pick
    -- them up, so we temporarily replace them :)
    md_source = md_source\gsub "%$", amp_temp
    html_source = assert discount md_source
    html_source = html_source\gsub amp_temp, "$"

    super page, html_source

