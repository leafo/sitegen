
module "sitegen.extra", package.seeall
sitegen = require "sitegen"
html = require "sitegen.html"

import dump from require "moon"


import CacheTable from require "sitegen.cache"

export ^

class DumpPlugin extends sitegen.Plugin
  tpl_helpers: { "dump" }
  dump: (args) =>
    dump args

class AnalyticsPlugin extends sitegen.Plugin
  tpl_helpers: { "analytics" }

  analytics: (arg) =>
    code = arg[1]
    [[<script type="text/javascript">
  if (window.location.hostname != "localhost") {
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', ']]..code..[[']);
    _gaq.push(['_trackPageview']);

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
  }
</script>]]


--
-- Specify code to highlight using ````lang, eg.
--
--
-- ```lua
-- print "hello world"
-- ```
--
class PygmentsPlugin
  custom_highlighters: {}
  disable_indent_detect: false

  -- highlihgt code with pygments
  highlight: (lang, code) =>
    fname = os.tmpname!
    with io.open fname, "w"
      \write code
      \close!

    p = io.popen ("pygmentize -f html -l %s %s")\format lang, fname
    out = p\read"*a"

    -- get rid of the div and pre inserted by pygments
    assert out\match '^<div class="highlight"><pre>(.-)\n?</pre></div>'

  -- checks cache and custom highlighters
  _highlight: (lang, code, page=nil) =>
    lang_cache = @lang_cache\get lang
    cached = lang_cache[code]
    highlighted = if cached
      cached
    else
      out = if @custom_highlighters[lang]
        @custom_highlighters[lang] self, code, page
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
      @_highlight lang, body, page

    document = Cs(code_block + (nl * code_block + 1)^0)

    assert document\match text

  -- prepare the cache
  on_site: (site) =>
    @lang_cache = site.cache\get"highlight"
    @keep_cache = CacheTable!
    table.insert site.cache.finalize, ->
      site.cache\set "highlight", @keep_cache

  on_register: =>
    table.insert sitegen.MarkdownRenderer.pre_render, self\filter

-- embed compiled coffeescript directly into the page
class CoffeeScriptPlugin
  tpl_helpers: { "render_coffee" }

  compile_coffee: (fname) =>
    p = io.popen ("coffee -c -p %s")\format fname
    p\read"*a"

  render_coffee: (arg) =>
    fname = unpack arg
    html.build ->
      script {
        type: "text/javascript"
        raw @compile_coffee fname
      }

sitegen.register_plugin DumpPlugin
sitegen.register_plugin AnalyticsPlugin
sitegen.register_plugin PygmentsPlugin
sitegen.register_plugin CoffeeScriptPlugin

nil

