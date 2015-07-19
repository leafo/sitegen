import Renderer from require "sitegen.renderer"

dollar_temp = "0000sitegen_markdown00dollar0000"

escape_cosmo = (str) ->
  escapes = {}
  import P, R, Cmt, Cs from require "lpeg"

  counter = 0

  alphanum = R "az", "AZ", "09", "__"
  -- TODO: this doesn't support nesting
  -- TODO: this doesn't escape the blocks
  cosmo = P"$" * alphanum^1 * (P"{" * (P(1) - "}")^0 * P"}")^-1 / (tpl) ->
    counter += 1
    key = "#{dollar_temp}.#{counter}"
    escapes[key] = tpl
    key

  patt = Cs (cosmo + P(1))^0 * P(-1)
  str = patt\match(str) or str, escapes
  str, escapes

unescape_cosmo = (str, escapes) ->
  import P, R, Cmt, Cs from require "lpeg"

  escape_patt = P(dollar_temp) * P(".") * R("09")^1 / (key) ->
    escapes[key] or error "bad key for unescape_cosmo"

  patt = Cs (escape_patt + P(1))^0 * P(-1)
  assert patt\match(str)

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

    md_source, escapes = escape_cosmo md_source

    html_source = assert discount md_source
    html_source = unescape_cosmo html_source, escapes

    super page, html_source

