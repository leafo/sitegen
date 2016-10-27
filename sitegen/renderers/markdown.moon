import Renderer from require "sitegen.renderer"

dollar_temp = "0000sitegen_markdown00dollar0000"

-- a constructor for quote delimited strings
simple_string = (delim) ->
  import P from require "lpeg"

  inner = P("\\#{delim}") + "\\\\" + (1 - P delim)
  inner = inner^0
  P(delim) * inner * P(delim)

escape_cosmo = (str) ->
  escapes = {}
  import P, R, Cmt, Cs from require "lpeg"

  counter = 0

  cosmo_inner = simple_string("'") + simple_string('"')+ (P(1) - "}")

  alphanum = R "az", "AZ", "09", "__"
  -- TODO: this doesn't support nesting
  -- TODO: this doesn't escape the blocks
  cosmo = P"$" * alphanum^1 * (P"{" * cosmo_inner^0 * P"}")^-1 / (tpl) ->
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
  @escape_cosmo: escape_cosmo
  @unescape_cosmo: unescape_cosmo

  source_ext: "md"
  ext: "html"

  render: (page, md_source) =>
    discount = require "discount"

    md_source = page\pipe "renderer.markdown.pre_render", md_source
    md_source, escapes = escape_cosmo md_source

    html_source = assert discount md_source
    html_source = unescape_cosmo html_source, escapes

    super page, html_source

