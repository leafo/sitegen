html = require "sitegen.html"
import HighlightPlugin from require "sitegen.highlight_plugin"

class SyntaxhighlightPlugin extends HighlightPlugin
  custom_highlighters: {}
  before_highlight: {}
  ignore_missing_lexer: true

  -- allow remapping language names
  language_aliases: {
    moon: "moonscript"
    erb: "rhtml"
    js: "javascript"
    scss: "sass"
  }

  -- highlight code with syntaxhighlight library https://github.com/leafo/lua-syntaxhighlight
  highlight: (lang, code) =>
    syntaxhighlight = require "syntaxhighlight"

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

  _highlight: (lang, code, page=nil) =>
    -- strip extra newlines
    code = code\gsub("\r?\n$", "")\gsub("^\r?\n", "")

    if fn = @before_highlight[lang]
      assert fn @, code, page

    super lang, code, page
