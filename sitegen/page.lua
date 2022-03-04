local html = require("sitegen.html")
local Path = require("sitegen.path")
local Stack, split, throw_error, escape_patt, extend
do
  local _obj_0 = require("sitegen.common")
  Stack, split, throw_error, escape_patt, extend = _obj_0.Stack, _obj_0.split, _obj_0.throw_error, _obj_0.escape_patt, _obj_0.extend
end
local Page
do
  local _class_0
  local _base_0 = {
    __tostring = function(self)
      return table.concat({
        "<Page '",
        self.source,
        "'>"
      })
    end,
    trigger = function(self, event, ...)
      return self.site.events:trigger(event, self, ...)
    end,
    pipe = function(self, event, ...)
      return select(2, self.site.events:pipe(event, self, ...))
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
        local base = self.site.user_vars.base_url or self.site.user_vars.url or "/"
        path = Path.join(base, path)
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
      local content = self:render()
      assert(self.site.io.write_file_safe(self.target, content))
      local source = self.site.io.full_path(self.source)
      local target = self.site.io.full_path(self.target)
      self.site.logger:render(source, target)
      return self.target
    end,
    read = function(self)
      do
        local out = self.site.io.read_file(self.source)
        if not (out) then
          throw_error("failed to read input file: " .. self.source)
        end
        return out
      end
    end,
    plugin_template_helpers = function(self)
      local helpers = { }
      local _list_0 = self.site.plugins
      for _index_0 = 1, #_list_0 do
        local _continue_0 = false
        repeat
          local plugin = _list_0[_index_0]
          if not (plugin.tpl_helpers) then
            _continue_0 = true
            break
          end
          local _list_1 = plugin.tpl_helpers
          for _index_1 = 1, #_list_1 do
            local helper_name = _list_1[_index_1]
            helpers[helper_name] = function(...)
              return plugin[helper_name](plugin, self, ...)
            end
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      return helpers
    end,
    get_root = function(self)
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
      return root
    end,
    get_tpl_scope = function(self)
      local user_vars_scope = { }
      if self.site.user_vars then
        for k, v in pairs(self.site.user_vars) do
          if type(v) == "function" then
            user_vars_scope[k] = function(...)
              return v(self, ...)
            end
          else
            user_vars_scope[k] = v
          end
        end
      end
      return extend({
        generate_date = os.date(),
        root = self:get_root()
      }, self:plugin_template_helpers(), self.meta, user_vars_scope)
    end,
    set_content = function(self, _content)
      self._content = _content
    end,
    render = function(self)
      if self._content then
        return self._content
      end
      self:trigger("page.before_render")
      self.template_stack = Stack()
      self.tpl_scope = self:get_tpl_scope()
      self._content = assert(self:render_fn(self), "failed to get content from renderer")
      self:trigger("page.content_rendered", self._content)
      self._inner_content = self._content
      if self.tpl_scope.template ~= false then
        self.template_stack:push(self.tpl_scope.template or self.site.config.default_template)
      end
      while #self.template_stack > 0 do
        local tpl_name = self.template_stack:pop()
        do
          local template = self.site.templates:find_by_name(tpl_name)
          if template then
            self.tpl_scope.body = self._content
            self._content = template(self)
          end
        end
      end
      self:trigger("page.rendered")
      return self._content
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, site, source)
      self.site, self.source = site, source
      self.renderer = self.site:renderer_for(self.source)
      local source_text = self:read()
      local filter = self.site:filter_for(self.source)
      local filter_opts = { }
      if filter then
        source_text = filter(filter_opts, source_text) or source_text
      end
      self.render_fn, self.meta = self.renderer:load(source_text, self.source)
      self.meta = self.meta or { }
      self:merge_meta(filter_opts)
      do
        local override_meta = self.site.scope.meta[self.source]
        if override_meta then
          self:merge_meta(override_meta)
        end
      end
      if self.meta.target_fname then
        self.target = Path.join(self.site.config.out_dir, self.meta.target_fname)
      elseif self.meta.target then
        self.target = Path.join(self.site.config.out_dir, self.meta.target .. "." .. self.renderer.ext)
      else
        self.target = self.site:output_path_for(self.source, self.renderer.ext)
      end
      return self:trigger("page.new")
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
