
module "sitegen.blog", package.seeall
html = require "sitegen.html"
require "cosmo"

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

class BlogPlugin
  pages: {}
  type_name: "blog_post"

  on_aggregate: (page) =>
    table.insert @pages, page

  write: (site) =>
    print "blog posts:", #@pages
    site\write_file "feed.xml", render_rss site, @pages

sitegen.register_plugin BlogPlugin

