module("sitegen.extra", package.seeall)
local sitegen = require("sitegen")
local html = require("sitegen.html")
local dump
do
  local _table_0 = require("moon")
  dump = _table_0.dump
end
local CacheTable
do
  local _table_0 = require("sitegen.cache")
  CacheTable = _table_0.CacheTable
end
do
  local _parent_0 = sitegen.Plugin
  local _base_0 = {
    tpl_helpers = {
      "dump"
    },
    dump = function(self, args)
      return dump(args)
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "DumpPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DumpPlugin = _class_0
end
do
  local _parent_0 = sitegen.Plugin
  local _base_0 = {
    tpl_helpers = {
      "analytics"
    },
    analytics = function(self, arg)
      local code = arg[1]
      return [[<script type="text/javascript">
  if (window.location.hostname != "localhost") {
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', ']] .. code .. [[']);
    _gaq.push(['_trackPageview']);

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
  }
</script>]]
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "AnalyticsPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  AnalyticsPlugin = _class_0
end
do
  local _parent_0 = nil
  local _base_0 = {
    custom_highlighters = { },
    disable_indent_detect = false,
    highlight = function(self, lang, code)
      local fname = os.tmpname()
      do
        local _with_0 = io.open(fname, "w")
        _with_0:write(code)
        _with_0:close()
      end
      local p = io.popen(("pygmentize -f html -l %s %s"):format(lang, fname))
      local out = p:read("*a")
      return assert(out:match('^<div class="highlight"><pre>(.-)\n?</pre></div>'))
    end,
    _highlight = function(self, lang, code, page)
      if page == nil then
        page = nil
      end
      local lang_cache = self.lang_cache:get(lang)
      local cached = lang_cache[code]
      local highlighted
      if cached then
        highlighted = cached
      else
        local out
        if self.custom_highlighters[lang] then
          out = self.custom_highlighters[lang](self, code, page)
        else
          out = self:pre_tag(self:highlight(lang, code), lang)
        end
        lang_cache[code] = out
        highlighted = out
      end
      self.keep_cache:get(lang):set(code, highlighted)
      return highlighted
    end,
    pre_tag = function(self, html_code, lang)
      if lang == nil then
        lang = "text"
      end
      return html.build(function()
        return pre({
          __breakclose = true,
          class = "highlight lang_" .. lang,
          code({
            raw(html_code)
          })
        })
      end)
    end,
    filter = function(self, text, page)
      local lpeg = require("lpeg")
      local P, R, S, Cs, Cmt, C, Cg, Cb = lpeg.P, lpeg.R, lpeg.S, lpeg.Cs, lpeg.Cmt, lpeg.C, lpeg.Cg, lpeg.Cb
      local delim = P("```")
      local white = S(" \t") ^ 0
      local nl = P("\n")
      local check_indent = Cmt(C(white) * Cb("indent"), function(body, pos, white, prev)
        if prev ~= "" and self.disable_indent_detect then
          return false
        end
        return white == prev
      end)
      local start_line = Cg(white, "indent") * delim * C(R("az", "AZ") ^ 1) * nl
      local end_line = check_indent * delim * (#nl + -1)
      local code_block = start_line * C((1 - end_line) ^ 0) * end_line
      code_block = code_block * Cb("indent") / function(lang, body, indent)
        if indent ~= "" then
          body = trim_leading_white(body, indent)
        end
        return self:_highlight(lang, body, page)
      end
      local document = Cs(code_block + (nl * code_block + 1) ^ 0)
      return assert(document:match(text))
    end,
    on_site = function(self, site)
      self.lang_cache = site.cache:get("highlight")
      self.keep_cache = CacheTable()
      return table.insert(site.cache.finalize, function()
        return site.cache:set("highlight", self.keep_cache)
      end)
    end,
    on_register = function(self)
      return table.insert(sitegen.MarkdownRenderer.pre_render, (function()
        local _base_1 = self
        local _fn_0 = _base_1.filter
        return function(...)
          return _fn_0(_base_1, ...)
        end
      end)())
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "PygmentsPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  PygmentsPlugin = _class_0
end
do
  local _parent_0 = nil
  local _base_0 = {
    tpl_helpers = {
      "render_coffee"
    },
    compile_coffee = function(self, fname)
      local p = io.popen(("coffee -c -p %s"):format(fname))
      return p:read("*a")
    end,
    render_coffee = function(self, arg)
      local fname = unpack(arg)
      return html.build(function()
        return script({
          type = "text/javascript",
          raw(self:compile_coffee(fname))
        })
      end)
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "CoffeeScriptPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CoffeeScriptPlugin = _class_0
end
sitegen.register_plugin(DumpPlugin)
sitegen.register_plugin(AnalyticsPlugin)
sitegen.register_plugin(PygmentsPlugin)
sitegen.register_plugin(CoffeeScriptPlugin)
return nil
