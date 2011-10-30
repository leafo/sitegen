require "moon"
require "lfs"
require "cosmo"
require "yaml"
discount = require "discount"

module "sitegen", package.seeall

import insert, concat, sort from table
import dump, extend, bind_methods, run_with_scope from moon

export create_site
export Plugin

punct = "[%^$()%.%[%]*+%-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

Path =
  normalize: (path) ->
    path\gsub "^%./", ""
  basepath: (path) ->
    path\match"^(.*)/[^/]*$" or "."
  mkdir: (path) ->
    os.execute ("mkdir -p %s")\format path
  copy: (src, dest) ->
    os.execute ("cp %s %s")\format src, dest
  join: (a, b) ->
    a = a\match"^(.*)/$" or a
    b = b\match"^/(.*)$" or b
    a .. "/" .. b

convert_pattern = (patt) ->
  patt = patt\gsub "([.])", (item) ->
    "%" .. item

  patt\gsub "[*]", ".*"

class OrderSet
  new: (items) =>
    @list = {}
    @set = {}
    if items
      for item in *items
        @add item

  add: (item) =>
    if @list[item] == nil
      table.insert @list, item
      @set[item] = #@list

  has: (item) =>
    @set[item] != nil

  each: =>
    coroutine.wrap ->
      for item in *@list
        coroutine.yield item

flatten_args = (...) ->
  accum = {}
  flatten = (tbl) ->
    for arg in *tbl
      if type(arg) == "table"
        flatten(arg)
      else
        table.insert accum, arg
  flatten {...}
  accum

class Plugin
  new: (@tpl_scope) =>

class Renderer
  new: (@pattern) =>
  render: -> error "must provide render method"
  can_render: (fname) =>
    nil != fname\match @pattern

  parse_header: (text) =>
    header = {}
    s, e = text\find "%-%-\n"
    if s
      header = yaml.load text\sub 1, s - 1
      text = text\sub e

    text, header

  render: (text, site) =>
    @parse_header text

class HTMLRenderer extends Renderer
  ext: "html"
  pattern: convert_pattern "*.html"

class MarkdownRenderer extends Renderer
  ext: "html"
  pattern: convert_pattern "*.md"

  render: (text, site) =>
    text, header = @parse_header text
    discount(text), header

-- visible from init
class SiteScope
  new: (@site) =>
    @files = OrderSet!
    @copy_files = OrderSet!
    @filters = {}

  set: (name, value) => self[name] = value
  get: (name) => self[name]

  add: (...) =>
    files = flatten_args ...
    @files\add fname for fname in *files

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
            @files\add full_path

    search dir

  dump_files: =>
    print "added files:"
    for path in @files\each!
      print " * " .. path

class Templates
  new: (@dir) =>
    @template_cache = {}

  fill: (name, context) =>
    tpl = @get_template name
    tpl context

  get_template: (name) =>
    if not @template_cache[name]
      file = io.open Path.join @dir, name .. ".html"
      error "could not find template: " .. name if not file
      @template_cache[name] = cosmo.f file\read "*a"

    @template_cache[name]

-- a webpage
class Site
  config: {
    template_dir: "templates/"
    default_template: "index"
    out_dir: "www/"
    write_gitignore: true
  }

  new: =>
    @scope = SiteScope self
    @user_vars = {}

    @renderers = {
      MarkdownRenderer
      HTMLRenderer
    }

    @plugins = {
      extra.DumpPlugin
      extra.AnalyticsPlugin
      indexer.IndexerPlugin
    }

  init_from_fn: (fn) =>
    bound = bind_methods @scope
    run_with_scope fn, bound, @user_vars

  output_path_for: (path, ext) =>
    if path\match"^%./"
      path = path\sub 3

    path = path\gsub "%.[^.]+$", "." .. ext
    Path.join @config.out_dir, path

  renderer_for: (path) =>
    for renderer in *@renderers
      if renderer\can_render path
        return renderer

    error "Don't know how to render:", path
  
  write_gitignore: (written_files) =>
    with io.open @config.out_dir .. ".gitignore", "w"
      patt = "^" .. escape_patt(@config.out_dir) .. "(.+)$"
      relative = [fname\match patt for fname in *written_files]
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
  template_helpers: (tpl_scope) =>
    helpers = {}
    for plugin in *@plugins
      if plugin.tpl_helpers
        p = plugin tpl_scope
        for helper_name in *plugin.tpl_helpers
          helpers[helper_name] = (...) ->
            p[helper_name] p, ...

    helpers

  -- write the entire website
  write: =>
    templates = Templates @config.template_dir

    written_files = for path in @scope.files\each!
      renderer = @renderer_for path
      text = io.open(path)\read "*a"
      out, meta = renderer\render text
      meta = meta or {}

      filter = @filter_for path
      if filter
        out = filter(meta, out) or out

      tpl_scope = {
        body: out
        generate_date: os.date!
      }

      helpers = @template_helpers tpl_scope
      tpl_scope = extend tpl_scope, meta, @user_vars, helpers

      while true
        co = coroutine.create ->
          tpl_scope.body = cosmo.f(tpl_scope.body) tpl_scope
          nil

        pass, altered_body = coroutine.resume co
        error altered_body if not pass
        if altered_body
          tpl_scope.body = altered_body
        else
          break

      tpl_name = meta.template == nil and "index" or meta.template
      if tpl_name
        out = templates\fill tpl_name, tpl_scope

      target = @output_path_for path, renderer.ext
      Path.mkdir Path.basepath target

      print "rendered", path, "->", target

      with io.open target, "w"
        \write out
        \close!

      target

    for path in @scope.copy_files\each!
      target = Path.join @config.out_dir, path
      print "copied", target
      table.insert written_files, target
      Path.copy path, target

    if @config.write_gitignore
      @write_gitignore written_files

create_site = (init_fn) ->
  site = Site! -- fix with bug!
  site\init_from_fn init_fn
  site.scope\search "*md"
  site

require "sitegen.indexer"
require "sitegen.extra"

