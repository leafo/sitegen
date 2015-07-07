
original_Site = require "sitegen.site"
page = require "sitegen.page"
site_file = require "sitegen.site_file"

local *

next_counter = do
  counters = setmetatable {}, __index: => 1
  (name) ->
    with counters[name]
      counters[name] += 1

Site = (opts={}) ->
  opts.rel_path or= "."

  original_Site site_file.SiteFile {
    rel_path: opts.rel_path
  }

Page = (opts={}) ->
  opts.site or= Site!

  base = "some_page_#{next_counter "page"}"

  opts.meta or= {}
  opts.source or= "#{base}.md"
  opts.target or= "www/#{base}.html"
  opts.render_fn or= ->

  opts.read = -> error "read disabled"
  opts.write = -> error "read disabled"

  setmetatable opts, page.Page.__base

  opts.site.pages or= {}
  table.insert opts.site.pages, opts

  opts

{ :Site, :Page }

