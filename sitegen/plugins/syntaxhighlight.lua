local html = require("sitegen.html")
local HighlightPlugin
HighlightPlugin = require("sitegen.highlight_plugin").HighlightPlugin
local SyntaxhighlightPlugin
do
  local _class_0
  local _parent_0 = HighlightPlugin
  local _base_0 = {
    custom_highlighters = { },
    before_highlight = { },
    ignore_missing_lexer = true,
    language_aliases = {
      moon = "moonscript",
      erb = "rhtml",
      js = "javascript",
      scss = "sass"
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
      return _class_0.__parent.__base._highlight(self, lang, code, page)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
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
