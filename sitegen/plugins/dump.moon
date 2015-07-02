
import dump from require "moon"
import Plugin from require "sitegen.plugin"

class DumpPlugin extends Plugin
  tpl_helpers: { "dump" }
  dump: (page, args) =>
    dump args
