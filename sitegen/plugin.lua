local Plugin
do
  local _class_0
  local _base_0 = {
    detach = function(self)
      if not (self.event_callbacks) then
        return 
      end
      local _list_0 = self.event_callbacks
      for _index_0 = 1, #_list_0 do
        local _des_0 = _list_0[_index_0]
        local event_name, callback
        event_name, callback = _des_0[1], _des_0[2]
        self.site.events:off(event_name, callback)
      end
      self.event_callbacks = nil
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      if self.events then
        self.event_callbacks = { }
        for event_name, func in pairs(self.events) do
          local callback
          callback = function(...)
            return func(self, ...)
          end
          self.site.events:on(event_name, callback)
          table.insert(self.event_callbacks, {
            event_name,
            callback
          })
        end
      end
    end,
    __base = _base_0,
    __name = "Plugin"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Plugin = _class_0
end
return {
  Plugin = Plugin
}
