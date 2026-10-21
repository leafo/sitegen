local CacheTable
CacheTable = require("sitegen.cache").CacheTable
local HighlightPlugin
HighlightPlugin = require("sitegen.highlight_plugin").HighlightPlugin
local PygmentsPlugin
do
  local _class_0
  local _parent_0 = HighlightPlugin
  local _base_0 = {
    custom_highlighters = { },
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
      local highlighted = lang_cache[code]
      if not (highlighted) then
        highlighted = _class_0.__parent.__base._highlight(self, lang, code, page)
        lang_cache[code] = highlighted
      end
      self.keep_cache:get(lang):set(code, highlighted)
      return highlighted
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      _class_0.__parent.__init(self, self.site)
      self.lang_cache = self.site.cache:get("highlight")
      self.keep_cache = CacheTable()
      return table.insert(self.site.cache.finalize, function()
        return self.site.cache:set("highlight", self.keep_cache)
      end)
    end,
    __base = _base_0,
    __name = "PygmentsPlugin",
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
  PygmentsPlugin = _class_0
  return _class_0
end
