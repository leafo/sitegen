
module ..., package.seeall

export *

-- this is pretty basic, it just watches the page inputs, not any of the
-- dependencies like templates or inline renders

class Watcher
  new: (@site, handler) =>
    inotify = require "inotify"
    error "missing inotify" if not inotify
    @handle = inotify.init!

    @handler = handler or (fname) ->
      with @site\Page fname
        \write!

  dirs_to_watch: =>
    dirs = {}
    for file in @site.scope.files\each!
      path = Path.basepath @site.io.real_path file
      dirs[path] = dirs[path] or { }
      dirs[path][Path.filename file] = file
    dirs

  loop: =>
    wd_table = {}

    dirs = @dirs_to_watch!

    for dir, set in pairs dirs
      wd_table[@handle\addwatch dir, inotify.IN_CLOSE_WRITE] = set

    print "Watching " .. #wd_table .. " dirs, Ctrl+C to quit"
    while true
      events = @handle\read!
      break if not events

      for ev in *events
        set = wd_table[ev.wd]
        if set and set[ev.name]
          self.handler set[ev.name]

