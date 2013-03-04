
html = require "sitegen.html"
date = require "date"
import copy, bind_methods from require "moon"
import insert from table
FeedPlugin = require "sitegen.feed"

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
    import title, url, description from site.user_vars
    if #@posts > 0
      feed_posts = for page in *@query!
        print "*", page.title, page.date
        {
          title: page.title
          date: page.date
          link: page\url_for true
          description: rawget page.meta, "description"
        }

      rss_text = FeedPlugin.render_feed {
        :title, :description, link: url
        unpack feed_posts
      }

      site\write_file "feed.xml", rss_text

  query: (filter={}) =>
    filter.sort = {"date", cmp.date! }
    posts = copy @posts

    if filter.sort
      col, c = unpack filter.sort
      table.sort posts, (a, b) ->
        c a[col], b[col]

    posts
