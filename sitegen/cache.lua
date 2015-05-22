local concat
concat = table.concat
local json = require("cjson")
local serialize
serialize = function(obj)
  return json.encode(obj)
end
local unserialize
unserialize = function(text)
  return json.decode(text)
end
local CacheTable
do
  local _base_0 = {
    __tostring = function(self)
      return "<CacheTable>"
    end,
    get = function(self, name, default)
      if default == nil then
        default = (function()
          return CacheTable()
        end)
      end
      local val = self[name]
      if type(val) == "table" and getmetatable(val) ~= self.__class.__base then
        self.__class:inject(val)
      end
      if val == nil then
        val = default()
        self[name] = val
        return val
      else
        return val
      end
    end,
    set = function(self, name, value)
      self[name] = value
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "CacheTable"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.inject = function(self, tbl)
    return setmetatable(tbl, self.__base)
  end
  CacheTable = _class_0
end
local Cache
do
  local _base_0 = {
    load_cache = function(self)
      if not (self.site.io.exists(self.fname)) then
        return 
      end
      local content = self.site.io.read_file(self.fname)
      local err
      self.cache, err = unserialize(content)
      if not (self.cache) then
        return error("could not load cache `" .. tostring(self.fname) .. "`, delete and try again: " .. tostring(err))
      end
    end,
    write = function(self)
      local _list_0 = self.finalize
      for _index_0 = 1, #_list_0 do
        local fn = _list_0[_index_0]
        fn(self)
      end
      local text = serialize(self.cache)
      if not text then
        error("failed to serialize cache")
      end
      return self.site.io.write_file(self.fname, text)
    end,
    clear = function(self)
      error("FIXXME")
      return os.remove(self.fname)
    end,
    set = function(self, ...)
      return self.cache:set(...)
    end,
    get = function(self, ...)
      return self.cache:get(...)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, site, fname, skip_load)
      if fname == nil then
        fname = ".sitegen_cache"
      end
      if skip_load == nil then
        skip_load = false
      end
      self.site, self.fname = site, fname
      self.finalize = { }
      self.cache = { }
      if not (skip_load) then
        self:load_cache()
      end
      return CacheTable:inject(self.cache)
    end,
    __base = _base_0,
    __name = "Cache"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.clear = function(self)
    local c = Cache(nil, true)
    return c:clear()
  end
  Cache = _class_0
end
return {
  Cache = Cache,
  CacheTable = CacheTable
}
