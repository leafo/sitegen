local lfs = require("lfs")
local cosmo = require("cosmo")
local yaml = require("yaml")
local discount = require("discount")
local moonscript = require("moonscript")
local lpeg = require("lpeg")
module("sitegen", package.seeall)
local insert, concat, sort
do
  local _obj_0 = table
  insert, concat, sort = _obj_0.insert, _obj_0.concat, _obj_0.sort
end
local dump, extend, bind_methods, run_with_scope
do
  local _obj_0 = require("moon")
  dump, extend, bind_methods, run_with_scope = _obj_0.dump, _obj_0.extend, _obj_0.bind_methods, _obj_0.run_with_scope
end
local plugins = { }
register_plugin = function(plugin)
  if plugin.on_register then
    plugin:on_register()
  end
  return table.insert(plugins, plugin)
end
local load_plugins
load_plugins = function(register)
  register(require("sitegen.feed"))
  register(require("sitegen.blog"))
  register(require("sitegen.deploy"))
  register(require("sitegen.indexer"))
  return require("sitegen.extra")
end
local html = require("sitegen.html")
local Path, OrderSet, Stack, throw_error, make_list, timed_call, escape_patt, bound_fn, split, convert_pattern, bright_yellow, flatten_args, pass_error, trim
do
  local _obj_0 = require("sitegen.common")
  Path, OrderSet, Stack, throw_error, make_list, timed_call, escape_patt, bound_fn, split, convert_pattern, bright_yellow, flatten_args, pass_error, trim = _obj_0.Path, _obj_0.OrderSet, _obj_0.Stack, _obj_0.throw_error, _obj_0.make_list, _obj_0.timed_call, _obj_0.escape_patt, _obj_0.bound_fn, _obj_0.split, _obj_0.convert_pattern, _obj_0.bright_yellow, _obj_0.flatten_args, _obj_0.pass_error, _obj_0.trim
end
local Cache
do
  local _obj_0 = require("sitegen.cache")
  Cache = _obj_0.Cache
end
local log
log = function(...)
  return print(...)
end
local fill_ignoring_pre
fill_ignoring_pre = function(text, context)
  local P, R, S, V, Ct, C
  P, R, S, V, Ct, C = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.Ct, lpeg.C
  local string_patt
  string_patt = function(delim)
    delim = P(delim)
    return delim * (1 - delim) ^ 0 * delim
  end
  local strings = string_patt("'") + string_patt('"')
  local open = P("<code") * (strings + (1 - P(">"))) ^ 0 * ">"
  local close = P("</code>")
  local Code = V("Code")
  local code = P({
    Code,
    Code = open * (Code + (1 - close)) ^ 0 * close
  })
  code = code / function(text)
    return {
      "code",
      text
    }
  end
  local other = (1 - code) ^ 1 / function(text)
    return {
      "text",
      text
    }
  end
  local document = Ct((code + other) ^ 0)
  local parts = document:match(text)
  local filled
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #parts do
      local part = parts[_index_0]
      local t, body = unpack(part)
      if t == "text" then
        body = cosmo.f(body)(context)
      end
      local _value_0 = body
      _accum_0[_len_0] = _value_0
      _len_0 = _len_0 + 1
    end
    filled = _accum_0
  end
  return table.concat(filled)
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
do
  local _base_0 = {
    relativeize = function(self, path)
      local exec
      exec = function(cmd)
        local p = io.popen(cmd)
        do
          local _with_0 = trim(p:read("*a"))
          p:close()
          return _with_0
        end
      end
      local rel_path
      if self.rel_path == "" then
        rel_path = "."
      else
        rel_path = self.rel_path
      end
      self.prefix = self.prefix or exec("realpath " .. rel_path) .. "/"
      local realpath = exec("realpath " .. path)
      return realpath:gsub("^" .. escape_patt(self.prefix), "")
    end,
    set_rel_path = function(self, depth)
      self.rel_path = ("../"):rep(depth)
      self:make_io()
      package.path = self.rel_path .. "?.lua;" .. package.path
      package.moonpath = self.rel_path .. "?.moon;" .. package.moonpath
    end,
    make_io = function(self)
      self.io = {
        open = function(fname, ...)
          return io.open(self.io.real_path(fname), ...)
        end,
        real_path = function(fname)
          return Path.join(self.rel_path, fname)
        end
      }
    end,
    get_site = function(self)
      print(bright_yellow("Using:"), Path.join(self.rel_path, self.name))
      local fn = moonscript.loadfile(self.file_path)
      local site = nil
      run_with_scope(fn, {
        sitegen = extend({
          create_site = function(fn)
            site = sitegen.create_site(fn, Site(self))
            site.write = function() end
            return site
          end
        }, sitegen)
      })
      site.write = nil
      return site
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, name)
      if name == nil then
        name = "site.moon"
      end
      self.name = name
      local dir = lfs.currentdir()
      local depth = 0
      while dir do
        local path = Path.join(dir, name)
        if Path.exists(path) then
          self.file_path = path
          self:set_rel_path(depth)
          return 
        end
        dir = Path.up(dir)
        depth = depth + 1
      end
      return throw_error("failed to find sitefile: " .. name)
    end,
    __base = _base_0,
    __name = "SiteFile"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SiteFile = _class_0
end
do
  local _base_0 = { }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, tpl_scope)
      self.tpl_scope = tpl_scope
    end,
    __base = _base_0,
    __name = "Plugin"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Plugin = _class_0
end
local Renderer
do
  local _base_0 = {
    render = function()
      return error("must provide render method")
    end,
    can_render = function(self, fname)
      return nil ~= fname:match(self.pattern)
    end,
    parse_header = function(self, text)
      local extract_header
      do
        local _obj_0 = require("sitegen.header")
        extract_header = _obj_0.extract_header
      end
      return extract_header(text)
    end,
    render = function(self, text, site)
      return self:parse_header(text)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, pattern)
      self.pattern = pattern
    end,
    __base = _base_0,
    __name = "Renderer"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Renderer = _class_0
end
do
  local _parent_0 = Renderer
  local _base_0 = {
    ext = "html",
    pattern = convert_pattern("*.html")
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
end
do
  local _parent_0 = Renderer
  local _base_0 = {
    ext = "html",
    pattern = convert_pattern("*.md"),
    pre_render = { },
    render = function(self, text, page)
      local header
      text, header = self:parse_header(text)
      local _list_0 = self.pre_render
      for _index_0 = 1, #_list_0 do
        local filter = _list_0[_index_0]
        text = filter(text, page)
      end
      return discount(text), header
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "MarkdownRenderer",
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
  MarkdownRenderer = _class_0
end
local MoonRenderer
do
  local _parent_0 = Renderer
  local _base_0 = {
    ext = "html",
    pattern = convert_pattern("*.moon"),
    render = function(self, text, page)
      local scopes = { }
      local meta = { }
      local context = setmetatable({ }, {
        __index = function(self, key)
          for i = #scopes, 1, -1 do
            local val = scopes[i][key]
            if val then
              return val
            end
          end
        end
      })
      local base_scope = setmetatable({
        _context = function()
          return context
        end,
        set = function(name, value)
          meta[name] = value
        end,
        get = function(name)
          return meta[name]
        end,
        format = function(name)
          local formatter
          if type(name) == "string" then
            formatter = require(name)
          else
            formatter = name
          end
          return insert(scopes, formatter.make_context(page, context))
        end
      }, {
        __index = _G
      })
      insert(scopes, base_scope)
      context.format("sitegen.formatters.default")
      local fn = moonscript.loadstring(text)
      setfenv(fn, context)
      fn()
      return context.render(), meta
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "MoonRenderer",
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
  MoonRenderer = _class_0
end
local SiteScope
do
  local _base_0 = {
    set = function(self, name, value)
      self[name] = value
    end,
    get = function(self, name)
      return self[name]
    end,
    disable = function(self, thing)
      self.site[thing .. "_disabled"] = true
    end,
    add = function(self, ...)
      local files, options = flatten_args(...)
      for _index_0 = 1, #files do
        local _continue_0 = false
        repeat
          local fname = files[_index_0]
          if self.files:has(fname) then
            _continue_0 = true
            break
          end
          self.files:add(fname)
          if next(options) then
            self.meta[fname] = options
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end,
    build = function(self, tool, input, ...)
      return table.insert(self.builds, {
        tool,
        input,
        {
          ...
        }
      })
    end,
    copy = function(self, ...)
      local files = flatten_args(...)
      local _list_0 = files
      for _index_0 = 1, #_list_0 do
        local fname = _list_0[_index_0]
        self.copy_files:add(fname)
      end
    end,
    filter = function(self, pattern, fn)
      return table.insert(self.filters, {
        pattern,
        fn
      })
    end,
    search = function(self, pattern, dir, enter_dirs)
      if dir == nil then
        dir = "."
      end
      if enter_dirs == nil then
        enter_dirs = false
      end
      pattern = convert_pattern(pattern)
      local search
      search = function(dir)
        for fname in lfs.dir(dir) do
          local _continue_0 = false
          repeat
            if not fname:match("^%.") then
              local full_path = Path.join(dir, fname)
              if enter_dirs and "directory" == lfs.attributes(full_path, "mode") then
                search(full_path)
              elseif fname:match(pattern) then
                if full_path:match("^%./") then
                  full_path = full_path:sub(3)
                end
                if self.files:has(full_path) then
                  _continue_0 = true
                  break
                end
                self.files:add(full_path)
              end
            end
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
      end
      return search(dir)
    end,
    dump_files = function(self)
      print("added files:")
      for path in self.files:each() do
        print(" * " .. path)
      end
      print()
      print("copy files:")
      for path in self.copy_files:each() do
        print(" * " .. path)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      self.files = OrderSet()
      self.meta = { }
      self.copy_files = OrderSet()
      self.builds = { }
      self.filters = { }
    end,
    __base = _base_0,
    __name = "SiteScope"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SiteScope = _class_0
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
        return MarkdownRenderer:render(args[1] or "")
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
      local file = self.io.open(Path.join(self.dir, name .. ".html"))
      if not file then
        return 
      end
      do
        local _with_0 = cosmo.f(file:read("*a"))
        file:close()
        return _with_0
      end
    end,
    load_moon = function(self, name)
      local file = self.io.open(Path.join(self.dir, name .. ".moon"))
      if not file then
        return 
      end
      local fn = moonscript.loadstring(file:read("*a"), name)
      file:close()
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
      local file = self.io.open(Path.join(self.dir, name .. ".md"))
      if not file then
        return 
      end
      html = MarkdownRenderer:render(file:read("*a"))
      file:close()
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
            if not file then
              self.template_cache[name] = throw_error("can't find template: " .. name)
            end
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
    Templates = function(self, path)
      return Templates(path, self.io)
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
      return self.io.real_path(self:output_path_for(...))
    end,
    renderer_for = function(self, path)
      local _list_0 = self.renderers
      for _index_0 = 1, #_list_0 do
        local renderer = _list_0[_index_0]
        if renderer:can_render(path) then
          return renderer
        end
      end
      return throw_error("don't know how to render: " .. path)
    end,
    run_build = function(self, buildset)
      local tool, input, args = unpack(buildset)
      input = self.io.real_path(input)
      local time, name, msg = timed_call(function()
        return tool(self, input, unpack(args))
      end)
      local status = "built\t\t" .. name .. " (" .. msg .. ")"
      if time then
        status = status .. " (" .. ("%.3f"):format(time) .. "s)"
      end
      return log(status)
    end,
    write_file = function(self, fname, content)
      local full_path = Path.join(self.config.out_dir, fname)
      Path.mkdir(Path.basepath(full_path))
      do
        local _with_0 = self.io.open(full_path, "w")
        _with_0:write(content)
        _with_0:close()
      end
      return table.insert(self.written_files, full_path)
    end,
    write_gitignore = function(self, written_files)
      do
        local _with_0 = self.io.open(self.config.out_dir .. ".gitignore", "w")
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
        _with_0:write(concat(relative, "\n"))
        _with_0:close()
        return _with_0
      end
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
    template_helpers = function(self, tpl_scope, page)
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
      local base = setmetatable({ }, {
        __index = function(_, name)
          local fn = self.templates.base_helpers[name]
          if type(fn) ~= "function" then
            return fn
          else
            return function(...)
              return fn(page, ...)
            end
          end
        end
      })
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
          print("copied", target)
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
      self.sitefile = sitefile
      self.io = self.sitefile and self.sitefile.io or io
      self.templates = self:Templates(self.config.template_dir)
      self.scope = SiteScope(self)
      self.cache = Cache(self)
      self.user_vars = { }
      self.written_files = { }
      self.renderers = {
        MarkdownRenderer,
        HTMLRenderer,
        MoonRenderer
      }
      self.plugins = OrderSet(plugins)
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
  Site = _class_0
end
create_site = function(init_fn, site)
  if site == nil then
    site = Site()
  end
  do
    local _with_0 = site
    _with_0:init_from_fn(init_fn)
    if not (_with_0.autoadd_disabled) then
      _with_0.scope:search("*md")
    end
    return _with_0
  end
end
load_plugins(sitegen.register_plugin)
return nil
