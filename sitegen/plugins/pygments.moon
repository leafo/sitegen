import CacheTable from require "sitegen.cache"
import HighlightPlugin from require "sitegen.highlight_plugin"

class PygmentsPlugin extends HighlightPlugin
  custom_highlighters: {}

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

  -- pygmentize runs as a separate process per block, so results are cached
  -- between builds
  _highlight: (lang, code, page=nil) =>
    lang_cache = @lang_cache\get lang
    highlighted = lang_cache[code]
    unless highlighted
      highlighted = super lang, code, page
      lang_cache[code] = highlighted

    @keep_cache\get(lang)\set code, highlighted
    highlighted

  new: (@site) =>
    super @site
    @lang_cache = @site.cache\get"highlight"
    @keep_cache = CacheTable!

    table.insert @site.cache.finalize, ->
      @site.cache\set "highlight", @keep_cache
