local Dispatch
do
  local _class_0
  local _base_0 = {
    _parse_name = function(self, name)
      assert(type(name) == "string", "event name must be string")
      local parts
      do
        local _accum_0 = { }
        local _len_0 = 1
        for p in name:gmatch("[^.]+") do
          _accum_0[_len_0] = p
          _len_0 = _len_0 + 1
        end
        parts = _accum_0
      end
      assert(next(parts), "invalid name")
      return parts
    end,
    on = function(self, name, callback)
      local parts = self:_parse_name(name)
      local callbacks = self.callbacks
      for _index_0 = 1, #parts do
        local p = parts[_index_0]
        callbacks[p] = callbacks[p] or { }
        callbacks = callbacks[p]
      end
      return table.insert(callbacks, callback)
    end,
    off = function(self, name)
      local parts = self:_parse_name(name)
      local last = parts[#parts]
      table.remove(parts)
      local callbacks = self.callbacks
      for _index_0 = 1, #parts do
        local p = parts[_index_0]
        callbacks = callbacks[p]
      end
      callbacks[last] = nil
    end,
    callbacks_for = function(self, name)
      local matched = { }
      local callbacks = self.callbacks
      local _list_0 = self:_parse_name(name)
      for _index_0 = 1, #_list_0 do
        local p = _list_0[_index_0]
        callbacks = callbacks[p]
        if not (callbacks) then
          break
        end
        for _index_1 = 1, #callbacks do
          local c = callbacks[_index_1]
          table.insert(matched, c)
        end
      end
      return matched
    end,
    pipe_callbacks = function(self, callbacks, i, event, ...)
      local cb = callbacks[i]
      if cb and not event.cancel then
        return self:pipe_callbacks(callbacks, i + 1, event, cb(event, ...))
      else
        return ...
      end
    end,
    pipe = function(self, name, ...)
      local callbacks = self:callbacks_for(name)
      local event = {
        name = name,
        cancel = false,
        dispatch = self
      }
      return self:pipe_callbacks(callbacks, 1, event, ...)
    end,
    trigger = function(self, name, ...)
      local count = 0
      local e = {
        name = name,
        cancel = false,
        dispatch = self
      }
      local _list_0 = self:callbacks_for(name)
      for _index_0 = 1, #_list_0 do
        local c = _list_0[_index_0]
        c(e, ...)
        count = count + 1
        if e.cancel then
          break
        end
      end
      return count > 0, e
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.callbacks = { }
    end,
    __base = _base_0,
    __name = "Dispatch"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Dispatch = _class_0
end
return {
  Dispatch = Dispatch
}
