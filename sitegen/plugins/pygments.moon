
html = require "sitegen.html"
import CacheTable from require "sitegen.cache"
import trim_leading_white from require "sitegen.common"

import Plugin from require "sitegen.plugin"

--
-- Specify code to highlight using ````lang, eg.
--
--
-- ```lua
-- print "hello world"
-- ```
--
class PygmentsPlugin extends Plugin
  custom_highlighters: {}
  disable_indent_detect: false

  -- highlight code with pygments
  highlight: (lang, code) =>
    fname = os.tmpname!
    with io.open fname, "w"
      \write code
      \close!

    p = io.popen ("pygmentize -f html -l %s %s")\format lang, fname
    out = p\read"*a"

    -- get rid of the div and pre inserted by pygments
    assert out\match('^<div class="highlight"><pre>(.-)\n?</pre></div>'),
      "Failed to parse pygmentize result, is pygments installed?"

  -- checks cache and custom highlighters
  _highlight: (lang, code, page=nil) =>
    lang_cache = @lang_cache\get lang
    cached = lang_cache[code]
    highlighted = if cached
      cached
    else
      out = if custom = @custom_highlighters[lang]
        assert custom(@, code, page),
          "custom highlighter #{lang} failed to return result"
      else
        @pre_tag @highlight(lang, code), lang

      lang_cache[code] = out
      out

    @keep_cache\get(lang)\set code, highlighted
    highlighted

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

    document = Cs(code_block + (nl * code_block + 1)^0)

    assert document\match text

  -- prepare the cache
  on_site: (site) =>
    @lang_cache = site.cache\get"highlight"
    @keep_cache = CacheTable!
    table.insert site.cache.finalize, ->
      site.cache\set "highlight", @keep_cache

  on_register: =>
    MarkdownRenderer = require "sitegen.renderers.markdown"
    table.insert MarkdownRenderer.pre_render, @\filter


