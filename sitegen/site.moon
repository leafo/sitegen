import concat from table

import
  extend
  run_with_scope
  bind_methods
  from require "moon"

Path = require "sitegen.path"

import
  OrderSet
  make_list
  throw_error
  escape_patt
  timed_call
  bound_fn
  unpack
  from require "sitegen.common"

import Cache from require "sitegen.cache"
import SiteScope from require "sitegen.site_scope"
import Templates from require "sitegen.templates"
import Page from require "sitegen.page"

-- a webpage
class Site
  @default_renderers: {
    "sitegen.renderers.markdown"
    "sitegen.renderers.html"
    "sitegen.renderers.moon"
  }

  @default_plugins: {
    "sitegen.plugins.feed"
    "sitegen.plugins.blog"
    "sitegen.plugins.deploy"
    "sitegen.plugins.indexer"
    "sitegen.plugins.analytics"
    "sitegen.plugins.coffee_script"
    "sitegen.plugins.pygments"
    -- "sitegen.plugins.syntaxhighlight"
    "sitegen.plugins.dump"
  }

  __tostring: => "<Site>"

  config: {
    template_dir: "templates/"
    default_template: "index"
    out_dir: "www/"
    write_gitignore: true
  }

  new: (sitefile=nil) =>
    import Dispatch from require "sitegen.dispatch"
    import SiteFile from require "sitegen.site_file"
    @sitefile = assert sitefile or SiteFile.master, "missing sitefile"

    @logger = assert @sitefile.logger, "missing sitefile.logger"
    @io = assert @sitefile.io, "missing sitefile.io"

    @templates = @Templates @config.template_dir

    @scope = SiteScope self
    @cache = Cache self

    @events = Dispatch!

    @user_vars = {}
    @written_files = {}

    @renderers = [require(rmod) @ for rmod in *@@default_renderers]
    @plugins = [require(pmod) @ for pmod in *@@default_plugins]
    @events\trigger "site.new", @

  Templates: => Templates @
  Page: (...) => Page self, ...

  get_renderer: (cls) =>
    cls = require cls if type(cls) == "string"
    for r in *@renderers
      return r if cls == r.__class

  add_plugin: (mod) =>
    p = require(mod) @
    table.insert @plugins, p

  get_plugin: (cls) =>
    cls = require cls if type(cls) == "string"
    for p in *@plugins
      return p if cls == p.__class

  plugin_scope: =>
    scope = {}
    for plugin in *@plugins
      if plugin.mixin_funcs
        for fn_name in *plugin.mixin_funcs
          scope[fn_name] = bound_fn plugin, fn_name

    scope

  plugin_actions: =>
    actions = {}
    for plugin in *@plugins
      continue unless plugin.command_actions
      for fn_name in *plugin.command_actions
        actions[fn_name] = bound_fn plugin, fn_name

    actions

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
    @io.full_path @output_path_for ...

  renderer_for: (path) =>
    for renderer in *@renderers
      if renderer\can_load path
        return renderer

    throw_error "don't know how to render: " .. path

  run_build: (buildset) =>
    tool, input, args = unpack buildset

    input = @io.full_path input

    time, name, msg, code = timed_call ->
      tool self, input, unpack args

    if code > 0
      throw_error "failed to run command #{name}"

    status = "#{name} (#{msg})"
    status = status .. " (" .. ("%.3f")\format(time) .. "s)" if time

    @logger\build status

  -- TODO: refactor to use this?
  write_file: (fname, content) =>
    full_path = Path.join @config.out_dir, fname
    assert @io.write_file_safe full_path, content
    table.insert @written_files, full_path

  -- strips the out_dir from the file paths
  write_gitignore: (written_files) =>
    patt = "^" .. escape_patt(@config.out_dir) .. "(.+)$"
    relative = [fname\match patt for fname in *written_files]
    table.sort relative

    @io.write_file_safe Path.join(@config.out_dir, ".gitignore"),
      concat relative, "\n"

  filter_for: (path) =>
    path = Path.normalize path
    for filter in *@scope.filters
      patt, fn = unpack filter
      if path\match patt
        return fn
    nil

  load_pages: =>
    unless @pages
      @pages = for path in @scope.files\each!
        with page = @Page path
          @events\trigger "site.load_page", @, page

    @pages

  query_pages: (...) =>
    @load_pages!
    import query_pages from require "sitegen.query"
    query_pages @pages, ...

  -- write the entire website
  write: (filter_files=false) =>
    @load_pages!
    pages = @pages

    if filter_files
      pages = [p for p in *pages when filter_files[p.source]]
      throw_error "no pages found for rendering" if #pages == 0

    written_files = for page in *pages
      page\write!

    return if filter_files -- don't do anything else when rendering subset

    for buildset in *@scope.builds
      @run_build buildset

    -- copy files
    for path in @scope.copy_files\each!
      target = Path.join @config.out_dir, path
      table.insert written_files, target
      Path.copy path, target

    -- write plugins
    for plugin in *@plugins
      plugin\write! if plugin.write

    -- gitignore
    if @config.write_gitignore
      -- add other written files
      table.insert written_files, file for file in *@written_files
      @write_gitignore written_files

    -- save the cache if updated
    @cache\write!

