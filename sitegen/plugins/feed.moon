
import Plugin from require "sitegen.plugin"

import
  trim_leading_white
  unpack
  from require "sitegen.common"

html = require "sitegen.html"
discount = require "discount"

date = require "date"

import extend from require "moon"
import insert from table

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
          parts = { }
          insert parts, title entry.title if entry.title
          insert parts, link entry.link if entry.link
          insert parts, pubDate format_date entry.date if entry.date
          insert parts, description cdata entry.description if entry.description
          item parts
      }
    }
  }

class FeedPlugin extends Plugin
  @render_feed: render_feed

  mixin_funcs: { "feed" }

  new: (@site) =>
    @feeds = {}

  feed: (source, dest) =>
    moonscript = require "moonscript.base"
    fn = assert moonscript.loadfile source
    table.insert @feeds, { dest, fn! }

  write: =>
    return unless @feeds[1]
    @site.logger\plain "feeds:", #@feeds

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

      @site\write_file dest, render_feed root

