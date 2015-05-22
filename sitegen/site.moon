
default_renderers = {
  "sitegen.renderers.markdown"
  "sitegen.renderers.html"
  "sitegen.renderers.moon"
}

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
  from require "sitegen.common"

import Cache from require "sitegen.cache"
import SiteScope from require "sitegen.site_scope"
import Templates from require "sitegen.templates"
import Page from require "sitegen.page"

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

  new: (sitefile=nil) =>
    import SiteFile from require "sitegen.site_file"
    @sitefile = assert sitefile or SiteFile.master, "missing sitefile"

    @logger = assert @sitefile.logger, "missing sitefile.logger"
    @io = assert @sitefile.io, "missing sitefile.io"
    @io = @io\annotate!

    @templates = @Templates @config.template_dir

    @scope = SiteScope self
    @cache = Cache self

    @user_vars = {}
    @written_files = {}

    @renderers = @@load_renderers!

    @plugins = OrderSet require("sitegen").plugins

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

    time, name, msg, code = timed_call ->
      tool self, input, unpack args

    if code > 0
      throw_error "failed to run command #{name}"

    status = "built\t\t#{name} (#{msg})"
    status = status .. " (" .. ("%.3f")\format(time) .. "s)" if time
    @logger\plain status

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

