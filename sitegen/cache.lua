module("sitegen.cache", package.seeall)
local concat = table.concat
local json = require("cjson")
local serialize
serialize = function(obj)
  return json.encode(obj)
end
local unserialize
unserialize = function(text)
  return json.decode(text)
end
do
  local _parent_0 = nil
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
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, ...)
      if _parent_0 then
        return _parent_0.__init(self, ...)
      end
    end,
    __base = _base_0,
    __name = "CacheTable",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
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
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  CacheTable = _class_0
end
do
  local _parent_0 = nil
  local _base_0 = {
    write = function(self)
      local _list_0 = self.finalize
      for _index_0 = 1, #_list_0 do
        local fn = _list_0[_index_0]
        fn(self)
      end
      local text = serialize(self.cache)
      if not text then
        error("Failed to serialize cache")
      end
      do
        local _with_0 = self.site.io.open(self.fname, "w")
        _with_0:write(text)
        _with_0:close()
        return _with_0
      end
    end,
    clear = function(self)
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
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
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
      if not skip_load then
        local f = self.site.io.open(self.fname)
        if f then
          local err
          self.cache, err = unserialize(f:read("*a"))
          if not self.cache then
            error(concat({
              "Could not load cache, ",
              self.fname,
              ", please delete and try again: ",
              err
            }))
          end
          f:close()
        end
      end
      return CacheTable:inject(self.cache)
    end,
    __base = _base_0,
    __name = "Cache",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil and _parent_0 then
        return _parent_0[name]
      else
        return val
      end
    end,
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
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Cache = _class_0
end
return nil
