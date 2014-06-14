lfs = require "lfs"
cosmo = require "cosmo"
yaml = require "yaml"
moonscript = require "moonscript"
lpeg = require "lpeg"

import insert, concat, sort from table
import dump, extend, bind_methods, run_with_scope from require "moon"

html = require "sitegen.html"

default_plugins = {
  "sitegen.feed"
  "sitegen.blog"
  "sitegen.deploy"
  "sitegen.indexer"

  "sitegen.plugins.analytics"
  "sitegen.plugins.coffee_script"
  "sitegen.plugins.pygments"
  "sitegen.plugins.dump"
}

default_renderers = {
  "sitegen.renderers.markdown"
  "sitegen.renderers.html"
  "sitegen.renderers.moon"
}

import
  Path
  OrderSet
  Stack
  throw_error
  make_list
  timed_call
  escape_patt
  bound_fn
  split
  convert_pattern
  bright_yellow
  flatten_args
  pass_error
  trim
  from require "sitegen.common"

import Cache from require "sitegen.cache"

local *

plugins = {}

register_plugin = (plugin) ->
  plugin\on_register! if plugin.on_register
  table.insert plugins, plugin

log = (...) ->
  print ...

-- replace all template vars in text not contained in a
-- code block
fill_ignoring_pre = (text, context) ->
  import P, R, S, V, Ct, C from lpeg

  string_patt = (delim) ->
    delim = P(delim)
    delim * (1 - delim)^0 * delim

  strings = string_patt"'" + string_patt'"'

  open = P"<code" * (strings + (1 - P">"))^0 * ">"
  close = P"</code>"

  Code = V"Code"
  code = P{
    Code
    Code: open * (Code + (1 - close))^0 * close
  }

  code = code / (text) -> {"code", text}

  other = (1 - code)^1 / (text) ->
    {"text", text}

  document = Ct((code + other)^0)
  -- parse to parts to avoid metamethod/c-call boundary
  parts = document\match text
  filled = for part in *parts
    t, body = unpack part
    body = cosmo.f(body) context if t == "text"
    body

  table.concat filled

-- template_helpers can yield if they decide to change the
-- entire body. This triggers the render to happen again
-- with the updated tpl_scope.
-- see indexer
render_until_complete = (tpl_scope, render_fn) ->
  out = nil
  while true
    co = coroutine.create ->
      out = render_fn!
      nil

    success, altered_body = assert coroutine.resume co
    pass_error altered_body

    if altered_body
      tpl_scope.body = altered_body
    else
      break
  out

-- does two things:
-- 1) finds the sitefile, looking up starting from the curret dir
-- 2) lets us open files relative to where the sitefile is
class SiteFile
  new: (@name="site.moon") =>
    dir = lfs.currentdir!
    depth = 0
    while dir
      path = Path.join dir, name
      if Path.exists path
        @file_path = path
        @set_rel_path depth
        return
      dir = Path.up dir
      depth += 1

    throw_error "failed to find sitefile: " .. name

  -- convert from shell relative to sitefile relative
  relativeize: (path) =>
    exec = (cmd) ->
      p = io.popen cmd
      with trim p\read "*a"
        p\close!

    rel_path = if @rel_path == "" then "." else @rel_path

    @prefix = @prefix or exec("realpath " .. rel_path) .. "/"
    realpath = exec "realpath " .. path
    realpath\gsub "^" .. escape_patt(@prefix), ""

  -- set relative path to depth folders above current
  -- add it to package.path
  set_rel_path: (depth) =>
    @rel_path = ("../")\rep depth
    @make_io!
    package.path = @rel_path .. "?.lua;" .. package.path
    --  TODO: regenerate moonpath?
    package.moonpath = @rel_path .. "?.moon;" .. package.moonpath

  make_io: =>
    -- performs operations relative to sitefile
    @io = {
      -- load a file relative to the sitepath
      open: (fname, ...) ->
        io.open @io.real_path(fname), ...

      real_path: (fname) ->
        Path.join(@rel_path, fname)
    }

  get_site: =>
    print bright_yellow"Using:", Path.join @rel_path, @name

    fn = moonscript.loadfile @file_path
    -- sitefiles have \write! on the bottom, disable it
    site = nil
    run_with_scope fn, {
      sitegen: extend {
        create_site: (fn) ->
          site = create_site fn, Site self
          site.write = ->
          site
      }, require "sitegen"
    }

    site.write = nil -- restore default write
    site

-- visible from init
class SiteScope
  new: (@site) =>
    @files = OrderSet!
    @meta = {}
    @copy_files = OrderSet!

    @builds = {}
    @filters = {}

  set: (name, value) => self[name] = value
  get: (name) => self[name]

  disable: (thing) =>
    @site[thing .. "_disabled"] = true

  add: (...) =>
    files, options = flatten_args ...
    for fname in *files
      continue if @files\has fname
      @files\add fname
      @meta[fname] = options if next(options)

  build: (tool, input, ...) =>
    table.insert @builds, {tool, input, {...}}

  copy: (...) =>
    files = flatten_args ...
    @copy_files\add fname for fname in *files

  filter: (pattern, fn) =>
    table.insert @filters, {pattern, fn}

  search: (pattern, dir=".", enter_dirs=false) =>
    pattern = convert_pattern pattern
    search = (dir) ->
      for fname in lfs.dir dir
        if not fname\match "^%."
          full_path = Path.join dir, fname
          if enter_dirs and "directory" == lfs.attributes full_path, "mode"
            search full_path
          elseif fname\match pattern
            if full_path\match"^%./"
              full_path = full_path\sub 3

            continue if @files\has full_path
            @files\add full_path

    search dir

  dump_files: =>
    print "added files:"
    for path in @files\each!
      print " * " .. path
    print!
    print "copy files:"
    for path in @copy_files\each!
      print " * " .. path

class Templates
  defaults: require "sitegen.default.templates"
  base_helpers: {
    render: (args) => -- render another page in current scope
      name = unpack args
      @site\Templates"."\fill name, @tpl_scope

    markdown: (args) =>
      MarkdownRenderer = require "sitegen.renderers.markdown"
      MarkdownRenderer\render args[1] or ""

    wrap: (args) =>
      tpl_name = unpack args
      throw_error "missing template name" if not tpl_name
      @template_stack\push tpl_name
      ""

    neq: (args) =>
      if args[1] != args[2]
        cosmo.yield {}
      else
        cosmo.yield _template: 2
      nil

    eq: (args) =>
      if args[1] == args[2]
        cosmo.yield {}
      else
        cosmo.yield _template: 2
      nil

    if: (args) =>
      if @tpl_scope[args[1]]
        cosmo.yield {}
      nil

    each: (args) =>
      list, name = unpack args
      if list
        list = flatten_args list
        for item in *list
          cosmo.yield { [(name)]: item }
      nil

    is_page: (args) =>
      page_pattern = unpack args
      cosmo.yield {} if @source\match page_pattern
      nil
  }

  new: (@dir, _io) =>
    @template_cache = {}
    @plugin_helpers = {}
    @base_helpers = extend @plugin_helpers, @base_helpers
    @io = _io or io

  fill: (name, context) =>
    tpl = @get_template name
    tpl context

  -- load an html (cosmo) template
  load_html: (name) =>
    file = @io.open Path.join @dir, name .. ".html"
    return if not file
    with cosmo.f file\read "*a"
      file\close!

  -- load a moonscript template
  load_moon: (name) =>
    file = @io.open Path.join @dir, name .. ".moon"
    return if not file
    fn = moonscript.loadstring file\read"*a", name
    file\close!

    (scope) ->
      tpl_fn = loadstring string.dump fn -- copy function
      source_env = getfenv tpl_fn

      setfenv tpl_fn, { :scope }

      html.build tpl_fn

  -- load a markdown template
  load_md: (name) =>
    file = @io.open Path.join @dir, name .. ".md"
    return if not file
    html = MarkdownRenderer\render file\read"*a"
    file\close!

    (scope) ->
      fill_ignoring_pre html, scope

  get_template: (name) =>
    if not @template_cache[name]
      local tpl

      -- look up exact file name
      base, ext = name\match "^(.-)%.([^/]*)$"
      if ext
        fn = self["load_"..ext]
        tpl = fn and fn self, base

      if not tpl
        for kind in *{"html", "moon", "md"}
          tpl = self["load_"..kind] self, name
          break if tpl

      if tpl
        @template_cache[name] = tpl
      else
        -- still don't have it? load default
        @template_cache[name] = if @defaults[name]
          cosmo.f @defaults[name]
        else
          throw_error "can't find template: " .. name if not file

    @template_cache[name]

-- an individual page
class Page
  __tostring: => table.concat { "<Page '",@source,"'>" }

  new: (@site, @source) =>
    @renderer = @site\renderer_for @source

    -- extract metadata
    @raw_text, @meta = @renderer\render @_read!, self
    @meta = @meta or {}

    if override_meta = @site.scope.meta[@source]
      @merge_meta override_meta

    @target = if @meta.target
      Path.join @site.config.out_dir, @meta.target .. "." .. @renderer.ext
    else
      @site\output_path_for @source, @renderer.ext

    filter = @site\filter_for @source
    if filter
      @raw_text = filter(@meta, @raw_text) or @raw_text

    -- expose meta in self
    cls = getmetatable self
    extend self, (key) => cls[key] or @meta[key]
    getmetatable(self).__tostring = Page.__tostring

  merge_meta: (tbl) =>
    for k,v in pairs tbl
      @meta[k] = v

  url_for: (absolute=false) =>
    front = "^"..escape_patt @site.config.out_dir
    path = @target\gsub front, ""

    if absolute
      if base = @site.user_vars.base_url or @site.user_vars.url
        path = Path.join base, path

    path

  link_to: =>
    html.build -> a { @title, href: @url_for! }

  -- write the file, return path to written file
  write: =>
    content = @_render!
    target_dir = Path.basepath @target
    target_dir = @site.io.real_path target_dir if @site.io.real_path

    Path.mkdir target_dir

    with @site.io.open @target, "w"
      \write content
      \close!

    real_path = @site.io.real_path
    source, target = if real_path
      real_path(@source), real_path(@target)
    else
      @source, @target

    log "rendered", source, "->", target
    @target

  -- read the source
  _read: =>
    text = nil
    file = @site.io.open @source

    throw_error "failed to read input file: " .. @source if not file

    with file\read"*a"
      file\close!

  _render: =>
    return @_content if @_content
    tpl_scope = {
      body: @raw_text
      generate_date: os.date!
    }

    helpers = @site\template_helpers tpl_scope, self

    base = Path.basepath @target
    parts = for i = 1, #split(base, "/") - 1 do ".."
    root = table.concat parts, "/"
    root = "." if root == ""
    helpers.root = root

    -- templates
    @template_stack = Stack!

    tpl_scope = extend tpl_scope, @meta, @site.user_vars, helpers
    @tpl_scope = tpl_scope

    tpl_scope.body = render_until_complete tpl_scope, ->
      fill_ignoring_pre tpl_scope.body, tpl_scope

    -- find the wrapping template
    if @meta.template != false
      @template_stack\push @meta.template or @site.config.default_template

    while #@template_stack > 0
      tpl_name = @template_stack\pop!
      stack_height = #@template_stack
      tpl_scope.body = render_until_complete tpl_scope, ->
        -- unroll any templates pushed from previous render attempt
        while #@template_stack > stack_height
          @template_stack\pop!

        @site.templates\fill tpl_name, tpl_scope

    @_content = tpl_scope.body
    @_content

-- a webpage
class Site
  @load_renderers: =>
    [require rname for rname in *default_renderers]

  __tostring: => "<Site>"

  config: {
    template_dir: "templates/"
    default_template: "index"
    out_dir: "www/"
    write_gitignore: true
  }

  new: (@sitefile=nil) =>
    @io = @sitefile and @sitefile.io or io

    @templates = @Templates @config.template_dir

    @scope = SiteScope self
    @cache = Cache self

    @user_vars = {}
    @written_files = {}

    @renderers = @@load_renderers!

    @plugins = OrderSet plugins
    -- extract aggregators from plugins
    @aggregators = {}
    for plugin in @plugins\each!
      if plugin.type_name
        for name in *make_list plugin.type_name
          @aggregators[name] = plugin

      if plugin.on_site
        plugin\on_site self

  Templates: (path) => Templates path, @io
  Page: (...) => Page self, ...

  plugin_scope: =>
    scope = {}
    for plugin in @plugins\each!
      if plugin.mixin_funcs
        for fn_name in *plugin.mixin_funcs
          scope[fn_name] = bound_fn plugin, fn_name

    scope

  init_from_fn: (fn) =>
    bound = bind_methods @scope
    bound = extend @plugin_scope!, bound
    run_with_scope fn, bound, @user_vars

  output_path_for: (path, ext=nil) =>
    if path\match"^%./"
      path = path\sub 3

    path = path\gsub "%.[^.]+$", "." .. ext if ext
    Path.join @config.out_dir, path

  real_output_path_for: (...) =>
    @io.real_path @output_path_for ...

  renderer_for: (path) =>
    for renderer in *@renderers
      if renderer\can_render path
        return renderer

    throw_error "don't know how to render: " .. path

  run_build: (buildset) =>
    tool, input, args = unpack buildset

    input = @io.real_path input

    time, name, msg = timed_call ->
      tool self, input, unpack args

    status = "built\t\t" .. name .. " (" .. msg .. ")"
    status = status .. " (" .. ("%.3f")\format(time) .. "s)" if time
    log status

  -- TODO: refactor to use this?
  write_file: (fname, content) =>
    full_path = Path.join @config.out_dir, fname
    Path.mkdir Path.basepath full_path

    with @io.open full_path, "w"
      \write content
      \close!

    table.insert @written_files, full_path

  -- strips the out_dir from the file paths
  write_gitignore: (written_files) =>
    with @io.open @config.out_dir .. ".gitignore", "w"
      patt = "^" .. escape_patt(@config.out_dir) .. "(.+)$"
      relative = [fname\match patt for fname in *written_files]
      table.sort relative
      \write concat relative, "\n"
      \close!

  filter_for: (path) =>
    path = Path.normalize path
    for filter in *@scope.filters
      patt, fn = unpack filter
      if path\match patt
        return fn
    nil

  -- get template helpers from plugins
  -- template plugins instances with tpl_scope
  template_helpers: (tpl_scope, page) =>
    helpers = {}
    for plugin in @plugins\each!
      if plugin.tpl_helpers
        p = plugin tpl_scope
        for helper_name in *plugin.tpl_helpers
          helpers[helper_name] = (...) ->
            p[helper_name] p, ...

    -- give the page to base helpers as first arg
    base = setmetatable {}, {
      __index: (_, name) ->
        fn = @templates.base_helpers[name]
        if type(fn) != "function"
          fn
        else
          (...) -> fn page, ...
    }

    extend helpers, base

  -- write the entire website
  write: (filter_files=false) =>
    pages = for path in @scope.files\each!
      continue if filter_files and not filter_files[path]
      page = @Page path
      -- TODO: check dont_write
      for t in *make_list page.meta.is_a
        plugin = @aggregators[t]
        throw_error "unknown `is_a` type: " .. t if not plugin
        plugin\on_aggregate page
      page

    if filter_files and #pages == 0
      throw_error "no pages found for rendering"

    written_files = for page in *pages
      page\write!

    for buildset in *@scope.builds
      @run_build buildset

    if not filter_files
      -- copy files
      for path in @scope.copy_files\each!
        target = Path.join @config.out_dir, path
        print "copied", target
        table.insert written_files, target
        Path.copy path, target

      -- write plugins
      for plugin in @plugins\each!
        plugin\write self if plugin.write

      -- gitignore
      if @config.write_gitignore
        -- add other written files
        table.insert written_files, file for file in *@written_files
        @write_gitignore written_files

    @cache\write! if not filter_files

create_site = (init_fn, site=Site!) ->
  with site
    \init_from_fn init_fn
    .scope\search "*md" unless .autoadd_disabled

for pname in *default_plugins
  register_plugin require pname

{
  :create_site, :register_plugin,
  :Site, :SiteFile
}
