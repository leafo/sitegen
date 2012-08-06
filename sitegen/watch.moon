
module ..., package.seeall

export *

-- this is pretty basic, it just watches the page inputs, not any of the
-- dependencies like templates or inline renders

class Watcher
  new: (@site) =>
    inotify = require "inotify"
    error "missing inotify" if not inotify

    @handle = inotify.init!

  page_handler: (fname) =>
    -> @site\Page(fname)\write!

  build_handler: (buildset) =>
    -> @site\run_build buildset

  watch_file_with: (file, handler) =>
    path = Path.basepath @site.io.real_path file
    @dirs[path] = @dirs[path] or { }
    @dirs[path][Path.filename file] = handler

  setup_dirs: =>
    for file in @site.scope.files\each!
      @watch_file_with file, @page_handler file

    for buildset in *@site.scope.builds
      @watch_file_with buildset[2], @build_handler buildset

  loop: =>
    @dirs = {}
    @setup_dirs!

    wd_table = {}

    for dir, set in pairs @dirs
      wd_table[@handle\addwatch dir, inotify.IN_CLOSE_WRITE] = set

    print "Watching " .. #wd_table .. " dirs, Ctrl+C to quit"
    while true
      events = @handle\read!
      break if not events

      for ev in *events
        set = wd_table[ev.wd]
        if set and set[ev.name]
          set[ev.name]()

