html = require "sitegen.html"

import extend from require "moon"

Path = require "sitegen.path"

import
  Stack
  fill_ignoring_pre
  split
  throw_error
  pass_error
  escape_patt
  from require "sitegen.common"

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

    @site.io.write_file_safe @target, content

    source = @site.io.full_path @source
    target = @site.io.full_path @target

    @site.logger\render source, target
    @target

  -- read the source
  _read: =>
    text = nil
    with out = @site.io.read_file @source
      unless out
        throw_error "failed to read input file: " .. @source

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

{
  :Page
}

