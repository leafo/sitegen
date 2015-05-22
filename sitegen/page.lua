local html = require("sitegen.html")
local extend
extend = require("moon").extend
local log
log = require("sitegen.output").log
local Path = require("sitegen.path")
local Stack, fill_ignoring_pre, split, throw_error, pass_error, escape_patt
do
  local _obj_0 = require("sitegen.common")
  Stack, fill_ignoring_pre, split, throw_error, pass_error, escape_patt = _obj_0.Stack, _obj_0.fill_ignoring_pre, _obj_0.split, _obj_0.throw_error, _obj_0.pass_error, _obj_0.escape_patt
end
local render_until_complete
render_until_complete = function(tpl_scope, render_fn)
  local out = nil
  while true do
    local co = coroutine.create(function()
      out = render_fn()
      return nil
    end)
    local success, altered_body = assert(coroutine.resume(co))
    pass_error(altered_body)
    if altered_body then
      tpl_scope.body = altered_body
    else
      break
    end
  end
  return out
end
local Page
do
  local _base_0 = {
    __tostring = function(self)
      return table.concat({
        "<Page '",
        self.source,
        "'>"
      })
    end,
    merge_meta = function(self, tbl)
      for k, v in pairs(tbl) do
        self.meta[k] = v
      end
    end,
    url_for = function(self, absolute)
      if absolute == nil then
        absolute = false
      end
      local front = "^" .. escape_patt(self.site.config.out_dir)
      local path = self.target:gsub(front, "")
      if absolute then
        do
          local base = self.site.user_vars.base_url or self.site.user_vars.url
          if base then
            path = Path.join(base, path)
          end
        end
      end
      return path
    end,
    link_to = function(self)
      return html.build(function()
        return a({
          self.title,
          href = self:url_for()
        })
      end)
    end,
    write = function(self)
      local content = self:_render()
      local target_dir = Path.basepath(self.target)
      if self.site.io.real_path then
        target_dir = self.site.io.real_path(target_dir)
      end
      Path.mkdir(target_dir)
      do
        local _with_0 = self.site.io.open(self.target, "w")
        _with_0:write(content)
        _with_0:close()
      end
      local real_path = self.site.io.real_path
      local source, target
      if real_path then
        source, target = real_path(self.source), real_path(self.target)
      else
        source, target = self.source, self.target
      end
      log("rendered", source, "->", target)
      return self.target
    end,
    _read = function(self)
      local text = nil
      local file = self.site.io.open(self.source)
      if not file then
        throw_error("failed to read input file: " .. self.source)
      end
      do
        local _with_0 = file:read("*a")
        file:close()
        return _with_0
      end
    end,
    _render = function(self)
      if self._content then
        return self._content
      end
      local tpl_scope = {
        body = self.raw_text,
        generate_date = os.date()
      }
      local helpers = self.site:template_helpers(tpl_scope, self)
      local base = Path.basepath(self.target)
      local parts
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, #split(base, "/") - 1 do
          _accum_0[_len_0] = ".."
          _len_0 = _len_0 + 1
        end
        parts = _accum_0
      end
      local root = table.concat(parts, "/")
      if root == "" then
        root = "."
      end
      helpers.root = root
      self.template_stack = Stack()
      tpl_scope = extend(tpl_scope, self.meta, self.site.user_vars, helpers)
      self.tpl_scope = tpl_scope
      tpl_scope.body = render_until_complete(tpl_scope, function()
        return fill_ignoring_pre(tpl_scope.body, tpl_scope)
      end)
      if self.meta.template ~= false then
        self.template_stack:push(self.meta.template or self.site.config.default_template)
      end
      while #self.template_stack > 0 do
        local tpl_name = self.template_stack:pop()
        local stack_height = #self.template_stack
        tpl_scope.body = render_until_complete(tpl_scope, function()
          while #self.template_stack > stack_height do
            self.template_stack:pop()
          end
          return self.site.templates:fill(tpl_name, tpl_scope)
        end)
      end
      self._content = tpl_scope.body
      return self._content
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, site, source)
      self.site, self.source = site, source
      self.renderer = self.site:renderer_for(self.source)
      self.raw_text, self.meta = self.renderer:render(self:_read(), self)
      self.meta = self.meta or { }
      do
        local override_meta = self.site.scope.meta[self.source]
        if override_meta then
          self:merge_meta(override_meta)
        end
      end
      if self.meta.target then
        self.target = Path.join(self.site.config.out_dir, self.meta.target .. "." .. self.renderer.ext)
      else
        self.target = self.site:output_path_for(self.source, self.renderer.ext)
      end
      local filter = self.site:filter_for(self.source)
      if filter then
        self.raw_text = filter(self.meta, self.raw_text) or self.raw_text
      end
      local cls = getmetatable(self)
      extend(self, function(self, key)
        return cls[key] or self.meta[key]
      end)
      getmetatable(self).__tostring = Page.__tostring
    end,
    __base = _base_0,
    __name = "Page"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Page = _class_0
end
return {
  Page = Page
}
