local concat
concat = table.concat
local extend, run_with_scope, bind_methods
do
  local _obj_0 = require("moon")
  extend, run_with_scope, bind_methods = _obj_0.extend, _obj_0.run_with_scope, _obj_0.bind_methods
end
local Path = require("sitegen.path")
local OrderSet, make_list, throw_error, escape_patt, timed_call, bound_fn
do
  local _obj_0 = require("sitegen.common")
  OrderSet, make_list, throw_error, escape_patt, timed_call, bound_fn = _obj_0.OrderSet, _obj_0.make_list, _obj_0.throw_error, _obj_0.escape_patt, _obj_0.timed_call, _obj_0.bound_fn
end
local Cache
Cache = require("sitegen.cache").Cache
local SiteScope
SiteScope = require("sitegen.site_scope").SiteScope
local Templates
Templates = require("sitegen.templates").Templates
local Page
Page = require("sitegen.page").Page
local Site
do
  local _base_0 = {
    __tostring = function(self)
      return "<Site>"
    end,
    config = {
      template_dir = "templates/",
      default_template = "index",
      out_dir = "www/",
      write_gitignore = true
    },
    Templates = function(self)
      return Templates(self)
    end,
    Page = function(self, ...)
      return Page(self, ...)
    end,
    plugin_scope = function(self)
      local scope = { }
      for plugin in self.plugins:each() do
        if plugin.mixin_funcs then
          local _list_0 = plugin.mixin_funcs
          for _index_0 = 1, #_list_0 do
            local fn_name = _list_0[_index_0]
            scope[fn_name] = bound_fn(plugin, fn_name)
          end
        end
      end
      return scope
    end,
    init_from_fn = function(self, fn)
      local bound = bind_methods(self.scope)
      bound = extend(self:plugin_scope(), bound)
      return run_with_scope(fn, bound, self.user_vars)
    end,
    output_path_for = function(self, path, ext)
      if ext == nil then
        ext = nil
      end
      if path:match("^%./") then
        path = path:sub(3)
      end
      if ext then
        path = path:gsub("%.[^.]+$", "." .. ext)
      end
      return Path.join(self.config.out_dir, path)
    end,
    real_output_path_for = function(self, ...)
      return self.io.full_path(self:output_path_for(...))
    end,
    renderer_for = function(self, path)
      local _list_0 = self.renderers
      for _index_0 = 1, #_list_0 do
        local renderer = _list_0[_index_0]
        if renderer:can_load(path) then
          return renderer
        end
      end
      return throw_error("don't know how to render: " .. path)
    end,
    run_build = function(self, buildset)
      local tool, input, args = unpack(buildset)
      input = self.io.full_path(input)
      local time, name, msg, code = timed_call(function()
        return tool(self, input, unpack(args))
      end)
      if code > 0 then
        throw_error("failed to run command " .. tostring(name))
      end
      local status = tostring(name) .. " (" .. tostring(msg) .. ")"
      if time then
        status = status .. " (" .. ("%.3f"):format(time) .. "s)"
      end
      return self.logger:build(status)
    end,
    write_file = function(self, fname, content)
      local full_path = Path.join(self.config.out_dir, fname)
      assert(self.io.write_file_safe(full_path, content))
      return table.insert(self.written_files, full_path)
    end,
    write_gitignore = function(self, written_files)
      local patt = "^" .. escape_patt(self.config.out_dir) .. "(.+)$"
      local relative
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #written_files do
          local fname = written_files[_index_0]
          _accum_0[_len_0] = fname:match(patt)
          _len_0 = _len_0 + 1
        end
        relative = _accum_0
      end
      table.sort(relative)
      return self.io.write_file_safe(Path.join(self.config.out_dir, ".gitignore"), concat(relative, "\n"))
    end,
    filter_for = function(self, path)
      path = Path.normalize(path)
      local _list_0 = self.scope.filters
      for _index_0 = 1, #_list_0 do
        local filter = _list_0[_index_0]
        local patt, fn = unpack(filter)
        if path:match(patt) then
          return fn
        end
      end
      return nil
    end,
    plugin_template_helpers = function(self, page)
      local helpers = { }
      for plugin in self.plugins:each() do
        if plugin.tpl_helpers then
          local p = plugin(tpl_scope)
          local _list_0 = plugin.tpl_helpers
          for _index_0 = 1, #_list_0 do
            local helper_name = _list_0[_index_0]
            helpers[helper_name] = function(...)
              return p[helper_name](p, ...)
            end
          end
        end
      end
      return extend(helpers, base)
    end,
    write = function(self, filter_files)
      if filter_files == nil then
        filter_files = false
      end
      local pages
      do
        local _accum_0 = { }
        local _len_0 = 1
        for path in self.scope.files:each() do
          local _continue_0 = false
          repeat
            if filter_files and not filter_files[path] then
              _continue_0 = true
              break
            end
            local page = self:Page(path)
            local _list_0 = make_list(page.meta.is_a)
            for _index_0 = 1, #_list_0 do
              local t = _list_0[_index_0]
              local plugin = self.aggregators[t]
              if not plugin then
                throw_error("unknown `is_a` type: " .. t)
              end
              plugin:on_aggregate(page)
            end
            local _value_0 = page
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        pages = _accum_0
      end
      if filter_files and #pages == 0 then
        throw_error("no pages found for rendering")
      end
      local written_files
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #pages do
          local page = pages[_index_0]
          _accum_0[_len_0] = page:write()
          _len_0 = _len_0 + 1
        end
        written_files = _accum_0
      end
      local _list_0 = self.scope.builds
      for _index_0 = 1, #_list_0 do
        local buildset = _list_0[_index_0]
        self:run_build(buildset)
      end
      if not filter_files then
        for path in self.scope.copy_files:each() do
          local target = Path.join(self.config.out_dir, path)
          table.insert(written_files, target)
          Path.copy(path, target)
        end
        for plugin in self.plugins:each() do
          if plugin.write then
            plugin:write(self)
          end
        end
        if self.config.write_gitignore then
          local _list_1 = self.written_files
          for _index_0 = 1, #_list_1 do
            local file = _list_1[_index_0]
            table.insert(written_files, file)
          end
          self:write_gitignore(written_files)
        end
      end
      if not filter_files then
        return self.cache:write()
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, sitefile)
      if sitefile == nil then
        sitefile = nil
      end
      local SiteFile
      SiteFile = require("sitegen.site_file").SiteFile
      self.sitefile = assert(sitefile or SiteFile.master, "missing sitefile")
      self.logger = assert(self.sitefile.logger, "missing sitefile.logger")
      self.io = assert(self.sitefile.io, "missing sitefile.io")
      self.templates = self:Templates(self.config.template_dir)
      self.scope = SiteScope(self)
      self.cache = Cache(self)
      self.user_vars = { }
      self.written_files = { }
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self.__class.default_renderers
        for _index_0 = 1, #_list_0 do
          local rmod = _list_0[_index_0]
          _accum_0[_len_0] = require(rmod)(self)
          _len_0 = _len_0 + 1
        end
        self.renderers = _accum_0
      end
      self.plugins = OrderSet(require("sitegen").plugins)
      self.aggregators = { }
      for plugin in self.plugins:each() do
        if plugin.type_name then
          local _list_0 = make_list(plugin.type_name)
          for _index_0 = 1, #_list_0 do
            local name = _list_0[_index_0]
            self.aggregators[name] = plugin
          end
        end
        if plugin.on_site then
          plugin:on_site(self)
        end
      end
    end,
    __base = _base_0,
    __name = "Site"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.default_renderers = {
    "sitegen.renderers.markdown",
    "sitegen.renderers.html",
    "sitegen.renderers.moon"
  }
  Site = _class_0
  return _class_0
end
