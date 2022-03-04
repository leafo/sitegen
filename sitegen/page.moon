html = require "sitegen.html"

Path = require "sitegen.path"

import
  Stack
  split
  throw_error
  escape_patt
  extend
  from require "sitegen.common"


-- an individual page
-- source: the subpath for the page's source
-- target: where the output of the page is written
-- meta: the parsed header merged with any additional page options
class Page
  __tostring: => table.concat { "<Page '",@source,"'>" }

  new: (@site, @source) =>
    @renderer = @site\renderer_for @source

    source_text = @read!
    filter = @site\filter_for @source
    filter_opts = {}

    if filter
       source_text = filter(filter_opts, source_text) or source_text

    -- extract metadata
    @render_fn, @meta = @renderer\load source_text, @source
    @meta = @meta or {}

    @merge_meta filter_opts

    if override_meta = @site.scope.meta[@source]
      @merge_meta override_meta

    @target = if @meta.target_fname
      Path.join @site.config.out_dir, @meta.target_fname
    elseif @meta.target
      Path.join @site.config.out_dir, @meta.target .. "." .. @renderer.ext
    else
      @site\output_path_for @source, @renderer.ext

    @trigger "page.new"

  trigger: (event, ...) =>
    @site.events\trigger event, @, ...

  pipe: (event, ...) =>
    select 2, @site.events\pipe event, @, ...

  merge_meta: (tbl) =>
    for k,v in pairs tbl
      @meta[k] = v

  url_for: (absolute=false) =>
    front = "^"..escape_patt @site.config.out_dir
    path = @target\gsub front, ""

    if absolute
      base = @site.user_vars.base_url or @site.user_vars.url or "/"
      path = Path.join base, path

    path

  link_to: =>
    html.build -> a { @title, href: @url_for! }

  -- write the file, return path to written file
  write: =>
    content = @render!
    assert @site.io.write_file_safe @target, content

    source = @site.io.full_path @source
    target = @site.io.full_path @target

    @site.logger\render source, target
    @target

  -- read the source
  read: =>
    with out = @site.io.read_file @source
      unless out
        throw_error "failed to read input file: " .. @source

  plugin_template_helpers: =>
    helpers = {}

    for plugin in *@site.plugins
      continue unless plugin.tpl_helpers
      for helper_name in *plugin.tpl_helpers
        helpers[helper_name] = (...) ->
          plugin[helper_name] plugin, @, ...

    helpers

  get_root: =>
    base = Path.basepath @target
    parts = for i = 1, #split(base, "/") - 1 do ".."
    root = table.concat parts, "/"
    root = "." if root == ""
    root

  get_tpl_scope: =>
    user_vars_scope = {}
    if @site.user_vars
      -- bind the functions to the page
      for k,v in pairs @site.user_vars
        user_vars_scope[k] = if type(v) == "function"
          (...) -> v @, ...
        else
          v

    extend {
      generate_date: os.date!
      root: @get_root!
    }, @plugin_template_helpers!, @meta, user_vars_scope

  set_content: (@_content) =>

  render: =>
    return @_content if @_content
    @trigger "page.before_render"

    @template_stack = Stack!

    @tpl_scope = @get_tpl_scope!

    @_content = assert @render_fn(@), "failed to get content from renderer"
    @trigger "page.content_rendered", @_content

    @_inner_content = @_content

    -- wrap the page in template
    if @tpl_scope.template != false
      @template_stack\push @tpl_scope.template or @site.config.default_template

    while #@template_stack > 0
      tpl_name = @template_stack\pop!
      if template = @site.templates\find_by_name tpl_name
        @tpl_scope.body = @_content
        @_content = template @

    @trigger "page.rendered"

    @_content

{
  :Page
}

