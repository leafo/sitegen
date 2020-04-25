local html = require("sitegen.html")
local Plugin
Plugin = require("sitegen.plugin").Plugin
local trim_leading_white
trim_leading_white = require("sitegen.common").trim_leading_white
local SyntaxhighlightPlugin
do
  local _class_0
  local _parent_0 = Plugin
  local _base_0 = {
    before_highlight = { },
    disable_indent_detect = false,
    ignore_missing_lexer = true,
    language_aliases = {
      moon = "moonscript",
      erb = "rhtml"
    },
    highlight = function(self, lang, code)
      local syntaxhighlight = require("syntaxhighlight")
      lang = self.language_aliases[lang] or lang
      if self.ignore_missing_lexer and not syntaxhighlight.lexers[lang] then
        if self.site then
          self.site.logger:warn("Failed to find syntax highlighter for: " .. tostring(lang))
        end
        return html.escape(code)
      end
      local out = assert(syntaxhighlight.highlight_to_html(lang, code, {
        bare = true
      }))
      return (out:gsub("\n$", ""))
    end,
    _highlight = function(self, lang, code, page)
      if page == nil then
        page = nil
      end
      code = code:gsub("\r?\n$", ""):gsub("^\r?\n", "")
      do
        local fn = self.before_highlight[lang]
        if fn then
          assert(fn(self, code, page))
        end
      end
      return self:pre_tag(self:highlight(lang, code), lang)
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
      local parse_cosmo
      parse_cosmo = require("sitegen.renderers.markdown").parse_cosmo
      local cosmo_pattern = parse_cosmo()
      local document = Cs(code_block ^ 0 * (nl * code_block + cosmo_pattern + 1) ^ 0) * -1
      return assert(document:match(text), "failed to parse string for syntax highlight")
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      return self.site.events:on("renderer.markdown.pre_render", function(event, page, md_source)
        return page, self:filter(md_source, page)
      end)
    end,
    __base = _base_0,
    __name = "SyntaxhighlightPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  SyntaxhighlightPlugin = _class_0
  return _class_0
end
