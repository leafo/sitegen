local html = require("sitegen.html")
local CacheTable
CacheTable = require("sitegen.cache").CacheTable
local trim_leading_white
trim_leading_white = require("sitegen.common").trim_leading_white
local Plugin
Plugin = require("sitegen.plugin").Plugin
local PygmentsPlugin
do
  local _parent_0 = Plugin
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
      return assert(out:match('^<div class="highlight"><pre>(.-)\n?</pre></div>'), "Failed to parse pygmentize result, is pygments installed?")
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
        do
          local custom = self.custom_highlighters[lang]
          if custom then
            out = assert(custom(self, code, page), "custom highlighter " .. tostring(lang) .. " failed to return result")
          else
            out = self:pre_tag(self:highlight(lang, code), lang)
          end
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
      local P, R, S, Cs, Cmt, C, Cg, Cb
      P, R, S, Cs, Cmt, C, Cg, Cb = lpeg.P, lpeg.R, lpeg.S, lpeg.Cs, lpeg.Cmt, lpeg.C, lpeg.Cg, lpeg.Cb
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
        return assert(self:_highlight(lang, body, page), "failed to highlight " .. tostring(lang) .. " code\n\n" .. tostring(body))
      end
      local document = Cs(code_block + (nl * code_block + 1) ^ 0)
      return assert(document:match(text))
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      self.lang_cache = self.site.cache:get("highlight")
      self.keep_cache = CacheTable()
      table.insert(self.site.cache.finalize, function()
        return self.site.cache:set("highlight", self.keep_cache)
      end)
      do
        local renderer = self.site:get_renderer("sitegen.renderers.markdown")
        if renderer then
          return table.insert(renderer.pre_render, (function()
            local _base_1 = self
            local _fn_0 = _base_1.filter
            return function(...)
              return _fn_0(_base_1, ...)
            end
          end)())
        end
      end
    end,
    __base = _base_0,
    __name = "PygmentsPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  PygmentsPlugin = _class_0
  return _class_0
end
