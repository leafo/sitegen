local Renderer
Renderer = require("sitegen.renderer").Renderer
local extend
extend = require("moon").extend
local fill_ignoring_pre, throw_error, flatten_args, pass_error
do
  local _obj_0 = require("sitegen.common")
  fill_ignoring_pre, throw_error, flatten_args, pass_error = _obj_0.fill_ignoring_pre, _obj_0.throw_error, _obj_0.flatten_args, _obj_0.pass_error
end
local render_until_complete
render_until_complete = function(tpl_scope, render_fn)
  local out = nil
  while true do
    local co = coroutine.create(function()
      out = render_fn()
      return nil
    end)
    local success, altered_source = assert(coroutine.resume(co))
    pass_error(altered_source)
    if altered_source then
      tpl_scope.render_source = altered_source
    else
      break
    end
  end
  return out
end
local HTMLRenderer
do
  local _parent_0 = Renderer
  local _base_0 = {
    source_ext = "html",
    ext = "html",
    cosmo_helpers = {
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
    helpers = function(self, page)
      local cosmo
      do
        local _tbl_0 = { }
        for k, v in pairs(self.cosmo_helpers) do
          _tbl_0[k] = (function(...)
            return v(page, ...)
          end)
        end
        cosmo = _tbl_0
      end
      return extend({ }, cosmo, page.tpl_scope)
    end,
    load = function(self, source, site)
      local content_fn, meta = _parent_0.load(self, source, site)
      local render
      render = function(page)
        local cosmo_scope = self:helpers(page)
        page.tpl_scope.render_source = content_fn()
        local out = render_until_complete(page.tpl_scope, function()
          return fill_ignoring_pre(page.tpl_scope.render_source, cosmo_scope)
        end)
        page.tpl_scope.render_source = nil
        return out
      end
      return render, meta
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "HTMLRenderer",
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
  HTMLRenderer = _class_0
  return _class_0
end
