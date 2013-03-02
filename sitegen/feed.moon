
module "sitegen.feed", package.seeall
sitegen = require "sitegen"
require "sitegen.common"

html = require "sitegen.html"
discount = require "discount"

require "moon"
require "date"

moonscript = require "moonscript"

import extend from moon

export render_feed

render_feed = (root) ->
  concat = (list) ->
    html.builders.raw! html.build -> list

  format_date = (date) ->
    if date.fmt
      date\fmt "${http}"
    else
      tostring date

  html.build -> {
    raw [[<?xml version="1.0" encoding="utf-8"?>]]
    rss {
      version: "2.0"
      channel {
        title root.title
        link root.link
        description root.description
        concat for entry in *root
          item {
            title entry.title
            link entry.link
            pubDate format_date entry.date
            description cdata entry.description
          }
      }
    }
  }

class FeedPlugin
  mixin_funcs: {"feed"}

  on_site: =>
    @feeds = {}

  feed: (source, dest) =>
    fn = assert moonscript.loadfile source
    table.insert @feeds, { dest, fn! }

  write: (site) =>
    print "feeds:  ", #@feeds
    for feed in *@feeds
      dest, root = unpack feed

      root.description = root.description or ""

      -- format entries
      for entry in *root
        entry.description = trim_leading_white entry.description
        extend entry, root

        entry.description = switch entry.format
          when "markdown"
            discount entry.description
          else
            entry.description

      site\write_file dest, render_feed root

sitegen.register_plugin FeedPlugin


nil
