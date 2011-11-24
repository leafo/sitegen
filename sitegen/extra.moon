require "moon"

module "sitegen.extra", package.seeall
sitegen = require "sitegen"
html = require "sitegen.html"

export AnalyticsPlugin, DumpPlugin

class DumpPlugin extends sitegen.Plugin
  tpl_helpers: { "dump" }
  dump: (args) =>
    moon.dump args

class AnalyticsPlugin extends sitegen.Plugin
  tpl_helpers: { "analytics" }

  analytics: (arg) =>
    code = arg[1]
    [[<script type="text/javascript">
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', ']]..code..[[']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
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
  highlight_code: (lang, code) =>
    fname = os.tmpname!
    with io.open fname, "w"
      \write code
      \close!

    p = io.popen ("pygmentize -f html -l %s %s")\format lang, fname
    p\read"*a"

  filter: (text, site) =>
    lpeg = require "lpeg"
    import P, R, S, Cs, C from lpeg

    delim = P"```"
    white = S" \t"^0
    nl = P"\n"

    body = (P(1) - (nl * delim * (nl + -1)))^0 * nl
    code_block = delim * C(R("az", "AZ")^1) * nl * C(body) * delim

    code_block = code_block / (lang, body) ->
      code_text = @highlight_code lang, body
      html.build -> code { class: "lang_"..lang, pre { raw code_text } }

    document = Cs((code_block + 1)^0)

    assert document\match text

  on_register: =>
    table.insert sitegen.MarkdownRenderer.pre_render, self\filter

sitegen.register_plugin DumpPlugin
sitegen.register_plugin AnalyticsPlugin
sitegen.register_plugin PygmentsPlugin

