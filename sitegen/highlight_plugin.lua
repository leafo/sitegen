local html = require("sitegen.html")
local Plugin
Plugin = require("sitegen.plugin").Plugin
local trim_leading_white
trim_leading_white = require("sitegen.common").trim_leading_white
local HighlightPlugin
do
  local _class_0
  local _parent_0 = Plugin
  local _base_0 = {
    custom_highlighters = { },
    disable_indent_detect = false,
    highlight = function(self, lang, code)
      return error(tostring(self.__class.__name) .. " must implement highlight")
    end,
    _highlight = function(self, lang, code, page)
      if page == nil then
        page = nil
      end
      do
        local custom = self.custom_highlighters[lang]
        if custom then
          return assert(custom(self, code, page), "custom highlighter " .. tostring(lang) .. " failed to return result")
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
      local document = Cs(code_block ^ -1 * (nl * code_block + cosmo_pattern + 1) ^ 0) * -1
      return assert(document:match(text), "failed to parse string for syntax highlight")
    end,
    events = {
      ["renderer.markdown.pre_render"] = function(self, event, page, md_source)
        return page, self:filter(md_source, page)
      end
    }
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "HighlightPlugin",
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
  local self = _class_0
  self.subclasses = { }
  self.__inherited = function(self, child)
    return table.insert(HighlightPlugin.subclasses, child)
  end
  self.warn_unused_custom_highlighters = function(self, site)
    local _list_0 = HighlightPlugin.subclasses
    for _index_0 = 1, #_list_0 do
      local _continue_0 = false
      repeat
        local cls = _list_0[_index_0]
        if not (next(cls.custom_highlighters)) then
          _continue_0 = true
          break
        end
        if site:get_plugin(cls) then
          _continue_0 = true
          break
        end
        local langs
        do
          local _accum_0 = { }
          local _len_0 = 1
          for lang in pairs(cls.custom_highlighters) do
            _accum_0[_len_0] = lang
            _len_0 = _len_0 + 1
          end
          langs = _accum_0
        end
        table.sort(langs)
        site.logger:warn(tostring(cls.__name) .. ".custom_highlighters has highlighters for " .. tostring(table.concat(langs, ", ")) .. " but the plugin isn't loaded, they will not be used")
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  HighlightPlugin = _class_0
end
return {
  HighlightPlugin = HighlightPlugin
}
