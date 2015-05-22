local cosmo = require("cosmo")
local html = require("sitegen.html")
local moonscript = require("moonscript.base")
local extend
extend = require("moon").extend
local Path = require("sitegen.path")
local fill_ignoring_pre, throw_error, flatten_args
do
  local _obj_0 = require("sitegen.common")
  fill_ignoring_pre, throw_error, flatten_args = _obj_0.fill_ignoring_pre, _obj_0.throw_error, _obj_0.flatten_args
end
local Templates
do
  local _base_0 = {
    defaults = require("sitegen.default.templates"),
    base_helpers = {
      render = function(self, args)
        local name = unpack(args)
        return self.site:Templates("."):fill(name, self.tpl_scope)
      end,
      markdown = function(self, args)
        local MarkdownRenderer = require("sitegen.renderers.markdown")
        local res = MarkdownRenderer:render(args[1] or "")
        return fill_ignoring_pre(res, self.tpl_scope)
      end,
      wrap = function(self, args)
        local tpl_name = unpack(args)
        if not tpl_name then
          throw_error("missing template name")
        end
        self.template_stack:push(tpl_name)
        return ""
      end,
      neq = function(self, args)
        if args[1] ~= args[2] then
          cosmo.yield({ })
        else
          cosmo.yield({
            _template = 2
          })
        end
        return nil
      end,
      eq = function(self, args)
        if args[1] == args[2] then
          cosmo.yield({ })
        else
          cosmo.yield({
            _template = 2
          })
        end
        return nil
      end,
      ["if"] = function(self, args)
        if self.tpl_scope[args[1]] then
          cosmo.yield({ })
        end
        return nil
      end,
      each = function(self, args)
        local list, name = unpack(args)
        if list then
          list = flatten_args(list)
          for _index_0 = 1, #list do
            local item = list[_index_0]
            cosmo.yield({
              [(name)] = item
            })
          end
        end
        return nil
      end,
      is_page = function(self, args)
        local page_pattern = unpack(args)
        if self.source:match(page_pattern) then
          cosmo.yield({ })
        end
        return nil
      end
    },
    fill = function(self, name, context)
      local tpl = self:get_template(name)
      return tpl(context)
    end,
    load_html = function(self, name)
      local full_name = Path.join(self.dir, name .. ".html")
      if not (self.io.exists(full_name)) then
        return 
      end
      return cosmo.f(self.io.read_file(full_name))
    end,
    load_moon = function(self, name)
      local full_name = Path.join(self.dir, name .. ".moon")
      if not (self.io.exists(full_name)) then
        return 
      end
      local fn = moonscript.loadstring(self.io.read_file(full_name), name)
      return function(scope)
        local tpl_fn = loadstring(string.dump(fn))
        local source_env = getfenv(tpl_fn)
        setfenv(tpl_fn, {
          scope = scope
        })
        return html.build(tpl_fn)
      end
    end,
    load_md = function(self, name)
      local full_name = Path.join(self.dir, name .. ".md")
      if not (self.io.exists(full_name)) then
        return 
      end
      local MarkdownRenderer = require("sitegen.renderers.markdown")
      html = MarkdownRenderer:render(self.io.read_file(full_name))
      return function(scope)
        return fill_ignoring_pre(html, scope)
      end
    end,
    get_template = function(self, name)
      if not self.template_cache[name] then
        local tpl
        local base, ext = name:match("^(.-)%.([^/]*)$")
        if ext then
          local fn = self["load_" .. ext]
          tpl = fn and fn(self, base)
        end
        if not tpl then
          local _list_0 = {
            "html",
            "moon",
            "md"
          }
          for _index_0 = 1, #_list_0 do
            local kind = _list_0[_index_0]
            tpl = self["load_" .. kind](self, name)
            if tpl then
              break
            end
          end
        end
        if tpl then
          self.template_cache[name] = tpl
        else
          if self.defaults[name] then
            self.template_cache[name] = cosmo.f(self.defaults[name])
          else
            self.template_cache[name] = throw_error("can't find template: " .. name)
          end
        end
      end
      return self.template_cache[name]
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, dir, _io)
      self.dir = dir
      self.template_cache = { }
      self.plugin_helpers = { }
      self.base_helpers = extend(self.plugin_helpers, self.base_helpers)
      self.io = _io or io
    end,
    __base = _base_0,
    __name = "Templates"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Templates = _class_0
end
return {
  Templates = Templates
}
