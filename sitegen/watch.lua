local Path = require("sitegen.path")
local inotify
local Watcher
do
  local _class_0
  local _base_0 = {
    page_handler = function(self, fname)
      return function()
        self.site.pages = nil
        self.site:load_pages()
        return self.site:Page(fname):write()
      end
    end,
    build_handler = function(self, buildset)
      return function()
        return self.site:run_build(buildset)
      end
    end,
    watch_file_with = function(self, file, handler)
      local path = Path.basepath(self.site.io.full_path(file))
      self.dirs[path] = self.dirs[path] or { }
      self.dirs[path][Path.filename(file)] = handler
    end,
    setup_dirs = function(self)
      for file in self.site.scope.files:each() do
        self:watch_file_with(file, self:page_handler(file))
      end
      local _list_0 = self.site.scope.builds
      for _index_0 = 1, #_list_0 do
        local buildset = _list_0[_index_0]
        self:watch_file_with(buildset[2], self:build_handler(buildset))
      end
    end,
    loop = function(self)
      self.dirs = { }
      self:setup_dirs()
      local wd_table = { }
      for dir, set in pairs(self.dirs) do
        wd_table[self.handle:addwatch(dir, inotify.IN_CLOSE_WRITE)] = set
      end
      local filter_name
      filter_name = function(name)
        return name:match("^(.*)%~$") or name
      end
      print("Watching " .. #wd_table .. " dirs, Ctrl+C to quit")
      while true do
        local events = self.handle:read()
        if not events then
          break
        end
        for _index_0 = 1, #events do
          local ev = events[_index_0]
          local set = wd_table[ev.wd]
          local name = filter_name(ev.name)
          if set and set[name] then
            set[name]()
          end
        end
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      inotify = require("inotify")
      if not inotify then
        error("missing inotify")
      end
      self.handle = inotify.init()
    end,
    __base = _base_0,
    __name = "Watcher"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Watcher = _class_0
end
return {
  Watcher = Watcher
}
