local Renderer
Renderer = require("sitegen.renderer").Renderer
local cosmo = require("sitegen.cosmo")
local extend
extend = require("moon").extend
local fill_ignoring_pre, throw_error, flatten_args, pass_error, unpack
do
  local _obj_0 = require("sitegen.common")
  fill_ignoring_pre, throw_error, flatten_args, pass_error, unpack = _obj_0.fill_ignoring_pre, _obj_0.throw_error, _obj_0.flatten_args, _obj_0.pass_error, _obj_0.unpack
end
local render_until_complete
render_until_complete = function(tpl_scope, render_fn, reset_fn)
  local out = nil
  while true do
    reset_fn()
    local co = coroutine.create(function()
      out = render_fn()
      return nil
    end)
    local _, altered_source = assert(coroutine.resume(co))
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
  local _class_0
  local _parent_0 = Renderer
  local _base_0 = {
    source_ext = "html",
    ext = "html",
    cosmo_helpers = {
      render = function(self, args)
        local name = assert(unpack(args), "missing template name for render")
        local templates = self.site:Templates()
        templates.search_dir = "."
        templates.defaults = { }
        return assert(templates:find_by_name(args[1]), "failed to find template: " .. tostring(name))(self)
      end,
      markdown = function(self, args)
        local md = self.site:get_renderer("sitegen.renderers.markdown")
        return md:render(self, assert(args and args[1], "missing markdown string"))
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
      end,
      query_pages = function(self, query)
        local query_pages
        query_pages = require("sitegen.query").query_pages
        local _list_0 = query_pages(self.site.pages, query)
        for _index_0 = 1, #_list_0 do
          local page = _list_0[_index_0]
          cosmo.yield(page:get_tpl_scope())
        end
        return nil
      end,
      query_page = function(self, query)
        local query_pages
        query_pages = require("sitegen.query").query_pages
        local res = query_pages(self.site.pages, query)
        assert(#res == 1, "expected to find one page for `query_page`, found " .. tostring(#res))
        cosmo.yield(res[1]:get_tpl_scope())
        return nil
      end,
      url_for = function(self, query)
        local query_pages
        query_pages = require("sitegen.query").query_pages
        local res = query_pages(self.site.pages, query)
        if #res == 0 then
          return error("failed to find any pages matching: " .. tostring(require("moon").dump(query)))
        elseif #res > 1 then
          return error("found more than 1 page matching: " .. tostring(require("moon").dump(query)))
        else
          return tostring(self.tpl_scope.root) .. "/" .. tostring(res[1]:url_for())
        end
      end
    },
    helpers = function(self, page)
      return extend({ }, (function()
        local _tbl_0 = { }
        for k, v in pairs(self.cosmo_helpers) do
          _tbl_0[k] = (function(...)
            return v(page, ...)
          end)
        end
        return _tbl_0
      end)(), page.tpl_scope)
    end,
    render = function(self, page, html_source)
      local cosmo_scope = self:helpers(page)
      local old_render_source = page.tpl_scope.render_source
      page.tpl_scope.render_source = html_source
      local init_stack = #page.template_stack
      local out = render_until_complete(page.tpl_scope, (function()
        return fill_ignoring_pre(page.tpl_scope.render_source, cosmo_scope)
      end), (function()
        while #page.template_stack > init_stack do
          page.template_stack:pop()
        end
      end))
      page.tpl_scope.render_source = old_render_source
      return out
    end,
    load = function(self, source)
      local content_fn, meta = _class_0.__parent.__base.load(self, source)
      return (function(page)
        return self:render(page, content_fn())
      end), meta
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "HTMLRenderer",
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
  HTMLRenderer = _class_0
  return _class_0
end
