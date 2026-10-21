html = require "sitegen.html"
import Plugin from require "sitegen.plugin"

import trim_leading_white from require "sitegen.common"

--
-- Base class for plugins that highlight fenced code blocks in markdown,
-- subclasses implement highlight. Specify code to highlight using ```lang, eg.
--
--
-- ```lua
-- print "hello world"
-- ```
--
class HighlightPlugin extends Plugin
  @subclasses: {}

  @__inherited: (child) =>
    table.insert HighlightPlugin.subclasses, child

  -- Highlighters registered on a plugin class that the site doesn't load are
  -- never called, eg. on PygmentsPlugin after syntaxhighlight became the
  -- default, so point them out instead of silently ignoring them
  @warn_unused_custom_highlighters: (site) =>
    for cls in *HighlightPlugin.subclasses
      continue unless next cls.custom_highlighters
      continue if site\get_plugin cls

      langs = [lang for lang in pairs cls.custom_highlighters]
      table.sort langs
      site.logger\warn "#{cls.__name}.custom_highlighters has highlighters for #{table.concat langs, ", "} but the plugin isn't loaded, they will not be used"

  -- functions that render a language's code block in place of the default
  -- highlighted pre tag: (plugin, code, page) -> html. Subclasses define their
  -- own table so sites can register highlighters per plugin
  custom_highlighters: {}

  disable_indent_detect: false

  -- returns html for the code, without the wrapping pre tag
  highlight: (lang, code) =>
    error "#{@@__name} must implement highlight"

  -- html for a single code block
  _highlight: (lang, code, page=nil) =>
    if custom = @custom_highlighters[lang]
      return assert custom(@, code, page),
        "custom highlighter #{lang} failed to return result"

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

    -- normally a code block must start at the beginning of a new line, but
    -- there is no new line at the beginning of the file so we have a special
    -- case for that
    document = Cs(code_block^-1 * (nl * code_block + cosmo_pattern + 1)^0) * -1

    assert document\match(text), "failed to parse string for syntax highlight"

  events: {
    "renderer.markdown.pre_render": (event, page, md_source) =>
      page, @filter md_source, page
  }

{
  :HighlightPlugin
}
