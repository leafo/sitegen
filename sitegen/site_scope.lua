local lfs = require("lfs")
local Path = require("sitegen.path")
local OrderSet, flatten_args, convert_pattern
do
  local _obj_0 = require("sitegen.common")
  OrderSet, flatten_args, convert_pattern = _obj_0.OrderSet, _obj_0.flatten_args, _obj_0.convert_pattern
end
local SiteScope
do
  local _base_0 = {
    set = function(self, name, value)
      self[name] = value
    end,
    get = function(self, name)
      return self[name]
    end,
    disable = function(self, thing)
      self.site[thing .. "_disabled"] = true
    end,
    add = function(self, ...)
      local files, options = flatten_args(...)
      for _index_0 = 1, #files do
        local _continue_0 = false
        repeat
          local fname = files[_index_0]
          if self.files:has(fname) then
            _continue_0 = true
            break
          end
          self.files:add(fname)
          if next(options) then
            self.meta[fname] = options
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end,
    build = function(self, tool, input, ...)
      return table.insert(self.builds, {
        tool,
        input,
        {
          ...
        }
      })
    end,
    copy = function(self, ...)
      local files = flatten_args(...)
      local _list_0 = files
      for _index_0 = 1, #_list_0 do
        local fname = _list_0[_index_0]
        self.copy_files:add(fname)
      end
    end,
    filter = function(self, pattern, fn)
      return table.insert(self.filters, {
        pattern,
        fn
      })
    end,
    search = function(self, pattern, dir, enter_dirs)
      if dir == nil then
        dir = "."
      end
      if enter_dirs == nil then
        enter_dirs = false
      end
      pattern = convert_pattern(pattern)
      local search
      search = function(dir)
        for fname in lfs.dir(dir) do
          local _continue_0 = false
          repeat
            if not fname:match("^%.") then
              local full_path = Path.join(dir, fname)
              if enter_dirs and "directory" == lfs.attributes(full_path, "mode") then
                search(full_path)
              elseif fname:match(pattern) then
                if full_path:match("^%./") then
                  full_path = full_path:sub(3)
                end
                if self.files:has(full_path) then
                  _continue_0 = true
                  break
                end
                self.files:add(full_path)
              end
            end
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
      end
      return search(dir)
    end,
    dump_files = function(self)
      print("added files:")
      for path in self.files:each() do
        print(" * " .. path)
      end
      print()
      print("copy files:")
      for path in self.copy_files:each() do
        print(" * " .. path)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      self.files = OrderSet()
      self.meta = { }
      self.copy_files = OrderSet()
      self.builds = { }
      self.filters = { }
    end,
    __base = _base_0,
    __name = "SiteScope"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SiteScope = _class_0
end
return {
  SiteScope = SiteScope
}
