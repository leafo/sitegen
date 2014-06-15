{
  whitelist_globals: {
    ["."]: { }

    ["sitegen/page"]: {
      "a"
    }

    ["sitegen/plugins/coffee_script"]: {
      "script", "raw"
    }

    ["sitegen/plugins/feed"]: {
      "raw", "rss", "channel", "title", "link", "description", "item",
      "pubDate", "cdata"
    }

    ["sitegen/plugins/pygments"]: {
      "pre", "code", "raw"
    }
  }
}
