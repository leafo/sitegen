local Plugin
do
  local _base_0 = { }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, tpl_scope)
      self.tpl_scope = tpl_scope
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
