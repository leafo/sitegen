
module "sitegen.blog", package.seeall
html = require "sitegen.html"
require "cosmo"
require "moon"
require "date"

import copy, bind_methods from moon

escaped = (data) ->
  setmetatable {}, {
    __index: (name) =>
      value = data[name]
      t = type value
      if t == "string"
        html.encode value
      elseif t == "table"
        escaped value
      else
        value
  }

helper = (tbl) ->
  setmetatable {
    has: (arg) ->
      name = arg[1]
      if tbl[name]
        cosmo.yield tbl
      nil
  }, __index: tbl

render_rss = (site, posts, limit=0) ->
  tpl = cosmo.f [==[
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:wfw="http://wellformedweb.org/CommentAPI/">
  <channel>
  <title>$site|title</title>
  <link>$site|url</link>
  <description>$site|description</description>
  $posts[[<item>
    <title>$title</title>
    $has{"description"}[=[<description>$description</description>]=]
  </item>]]
  </channel>
</rss>
]==]

  tpl {
    posts: ->
      for post in *posts
        t = helper escaped post
        cosmo.yield t
    site: escaped site.user_vars
  }

cmp = {
  date: (dir="desc") ->
    (a, b) ->
      if dir == "asc"
        date(a) < date(b)
      else
        date(a) > date(b)
}

class BlogPlugin
  posts: {}
  consumes_pages: false
  type_name: "blog_post"

  on_site: (site) =>
    -- register template scope
    site.templates.plugin_helpers.blog = {
      query: (arg) ->
        -- print moon.dump arg
        for page in *@query!
          cosmo.yield bind_methods page
    }

  -- return true if it consumes page
  on_aggregate: (page) =>
    table.insert @posts, page
    @consumes_pages

  write: (site) =>
    print "blog posts:", #@posts
    if #@posts > 0
      site\write_file "feed.xml", render_rss site, @posts

    posts = @query!
    for post in *posts
      print "*", post.title, post.date

  query: (filter={}) =>
    filter.sort = {"date", cmp.date! }
    posts = copy @posts

    if filter.sort
      col, c = unpack filter.sort
      table.sort posts, (a, b) ->
        c a[col], b[col]

    posts

sitegen.register_plugin BlogPlugin

nil

