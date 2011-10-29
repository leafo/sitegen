
require "lfs"
require "cosmo"
require "yaml"
discount = require "discount"

util = require "moonscript.util"

module "sitegen", package.seeall

import insert, concat, sort from table
export create_site, html_encode, html_decode, slugify
export index_headers, render_index

export dump
dump = util.dump

punct = "[%^$()%.%[%]*+%-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

html_encode_entities = {
  ['&']: '&amp;'
  ['<']: '&lt;'
  ['>']: '&gt;'
  ['"']: '&quot;'
  ["'"]: '&q#039;'
}

Path =
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

html_decode_entities = {}
for key,value in pairs html_encode_entities
  html_decode_entities[value] = key

html_encode_string = "[" .. concat([escape_patt char for char in pairs html_encode_entities]) .. "]"
html_encode = (text) ->
  (text\gsub html_encode_string, html_encode_entities)

html_decode = (text) ->
  (text\gsub "(&[^&]-;)", (enc) ->
    decoded = html_decode_entities[enc]
    decoded if decoded else enc)

strip_tags = (html) ->
  html\gsub "<[^>]+>", ""

render_index = (index) ->
  yield_index = (index) ->
    for item in *index
      if item.depth
        cosmo.yield _template: 2
        yield_index item
        cosmo.yield _template: 3
      else
        cosmo.yield name: item[1], target: item[2]

  tpl = [==[
		<ul>
		$index[[
			<li><a href="#$target">$name</a></li>
		]], [[ <ul> ]] , [[ </ul> ]]
		</ul>
  ]==]

  cosmo.f(tpl) index: -> yield_index index

-- filter to build index for headers
index_headers = (body, meta, opts={}) ->
  headers = {}

  opts.min_depth = opts.min_depth or 1
  opts.max_depth = opts.max_depth or 9

  current = headers
  fn = (body, i) ->
    i = tonumber i

    if i >= opts.min_depth and i <= opts.max_depth
      if not current.depth
        current.depth = i
      else
        if i > current.depth
          current = parent: current, depth: i
        else
          while i < current.depth and current.parent
            insert current.parent, current
            current = current.parent

          current.depth = i if i < current.depth

    slug = slugify html_decode body
    insert current, {body, slug}
    concat {
      '<h', i, '><a name="',slug,'"></a>', body, '</h', i, '>'
    }

  require "lpeg"
  import P, R, Cmt, Cs, Cg, Cb, C from lpeg

  nums = R("19")
  open = P"<h" * Cg(nums, "num") * ">"

  close = P"</h" * C(nums) * ">"
  close_pair = Cmt close * Cb("num"), (s, i, a, b) -> a == b
  tag = open * C((1 - close_pair)^0) * close

  patt = Cs((tag / fn + 1)^0)
  out = patt\match(body)

  while current.parent
    insert current.parent, current
    current = current.parent

  out, headers

slugify = (text) ->
  text = strip_tags text
  text = text\gsub "[&+]", " and "
  (text\lower!\gsub("%s+", "_")\gsub("[^%w_]", ""))

-- don't forget trailing /
config =
  template_dir: "template/"
  out_dir: "www/"
  page_pattern: "^(.*)%.md$"
  write_gitignore: true

default_meta =
  template: "index"

extend = (...) ->
  tbls = {...}
  return if #tbls < 2

  for i = 1, #tbls - 1
    a = tbls[i]
    b = tbls[i + 1]

    setmetatable a, __index: b

  tbls[1]

bound_object = (obj) ->
  setmetatable {}, {
    __index: (name) =>
      val = obj[name]
      if val and type(val) == "function"
        bound = (...) -> val obj, ...
        self[name] = bound
        bound
      else
        val
  }

run_with_scope = (fn, scope, ...) ->
  old_env = getfenv fn
  env = setmetatable {}, {
    __index: (name) =>
      val = scope[name]
      if val != nil
        val
      else
        old_env[name]
  }
  setfenv fn, env
  fn ...

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

class Renderer
  new: (@pattern) =>
  render: -> error "provide me"
  can_render: (fname) =>
    nil != fname\match @pattern

class MarkdownRenderer extends Renderer
  ext: "html"
  new: =>
    super convert_pattern "*.md"
  
  parse_header: (text) =>
    header = {}
    s, e = text\find "%-%-\n"
    if s
      header = yaml.load text\sub 1, s - 1
      text = text\sub e

    text, header

  render: (text, site) =>
    text, header = @parse_header text
    discount text

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
      MarkdownRenderer!
    }

  init_from_fn: (fn) =>
    bound = bound_object @scope
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

  -- write the entire website
  write: =>
    templates = Templates @config.template_dir

    written_files = for path in @scope.files\each!
      renderer = @renderer_for path
      text = io.open(path)\read "*a"
      out, meta = renderer\render text
      meta = meta or {}

      out = templates\fill "index", extend {
        body: out
        generate_date: os.date!
      }, meta, @user_vars

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

