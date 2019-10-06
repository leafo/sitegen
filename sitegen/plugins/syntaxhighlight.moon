html = require "sitegen.html"
import Plugin from require "sitegen.plugin"

import trim_leading_white from require "sitegen.common"

--
-- Specify code to highlight using ````lang, eg.
--
--
-- ```lua
-- print "hello world"
-- ```
--
class SyntaxhighlightPlugin extends Plugin
  before_highlight: {}
  disable_indent_detect: false
  ignore_missing_lexer: true

  -- allow remapping language names
  language_aliases: {
    moon: "moonscript"
    erb: "rhtml"
  }

  -- highlight code with pygments
  highlight: (lang, code) =>
    syntaxhighlight = require("syntaxhighlight")

    lang = @language_aliases[lang] or lang

    -- pass through must be html escaped
    if @ignore_missing_lexer and not syntaxhighlight.lexers[lang]
      if @site
        @site.logger\warn "Failed to find syntax highlighter for: #{lang}"

      return html.escape code

    out = assert syntaxhighlight.highlight_to_html lang, code, {
      bare: true
    }

    (out\gsub "\n$", "")

  -- checks cache and custom highlighters
  _highlight: (lang, code, page=nil) =>
    if fn = @before_highlight[lang]
      assert fn @, code, page

    @pre_tag @highlight(lang, code), lang

  pre_tag: (html_code, lang="text") =>
    html.build -> pre {
      __breakclose: true
      class: "highlight lang_"..lang
      code { raw html_code }
    }

  filter: (text, page) =>
    lpeg = require "lpeg"
    import P, R, S, Cs, Cmt, C, Cg, Cb from lpeg

    delim = P"```"
    white = S" \t"^0
    nl = P"\n"

    check_indent = Cmt C(white) * Cb"indent", (body, pos, white, prev) ->
      return false if prev != "" and @disable_indent_detect
      white == prev

    start_line = Cg(white, "indent") * delim * C(R("az", "AZ")^1) * nl
    end_line = check_indent * delim * (#nl + -1)

    code_block = start_line * C((1 - end_line)^0) * end_line
    code_block = code_block * Cb"indent" / (lang, body, indent) ->
      if indent != ""
        body = trim_leading_white body, indent
      assert @_highlight(lang, body, page),
        "failed to highlight #{lang} code\n\n#{body}"

    import parse_cosmo from require "sitegen.renderers.markdown"
    cosmo_pattern = parse_cosmo!

    document = Cs(code_block^0 * (nl * code_block + cosmo_pattern + 1)^0) * -1

    assert document\match(text), "failed to parse string for syntax highlight"

  new: (@site) =>
    @site.events\on "renderer.markdown.pre_render",
      (event, page, md_source) ->
        page, @filter md_source, page

