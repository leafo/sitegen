
import Plugin from require "sitegen.plugin"

query = require "sitegen.query"

import copy, bind_methods from require "moon"
import insert from table

import render_feed from require "sitegen.plugins.feed"

class BlogPlugin extends Plugin
  new: (@site) =>
    @opts = {
      out_file: "feed.xml"
      filter: { is_a: query.filter.contains "blog_post" }
      prepare: (page, ...) -> ...
    }


  mixin_funcs: { "blog_feed" }

  blog_feed: (opts={}) =>
    @create_feed = true

    for k,v in pairs opts
      @opts[k] = v


  write: =>
    return unless @create_feed
    @posts = @site\query_pages @opts.filter, sort: query.sort.date!

    return unless @posts[1]

    @site.logger\plain "blog posts:", #@posts

    import title, url, description from @site.user_vars

    feed_posts = for page in *@posts
      meta = page.meta

      @opts.prepare page, {
        title: meta.title
        date: meta.date
        link: page\url_for true

        -- to avoid getting description of page from chained meta
        description: rawget meta, "description"
      }

    rss_text = render_feed {
      title: @opts.title or title
      description: @opts.description or description
      link: @opts.url or url

      unpack feed_posts
    }

    @site\write_file @opts.out_file, rss_text
