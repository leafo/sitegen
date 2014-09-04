local Plugin
Plugin = require("sitegen.plugin").Plugin
local DeployPlugin
do
  local _parent_0 = Plugin
  local _base_0 = {
    mixin_funcs = {
      "deploy_to"
    },
    help = [[    This is how you use this plugin....
  ]],
    deploy_to = function(self, host, path)
      if host == nil then
        host = error("need host")
      end
      if path == nil then
        path = error("need path")
      end
      self.host, self.path = host, path
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
    end,
    __base = _base_0,
    __name = "DeployPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
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
  self.sync = function(self, host, path)
    return os.execute(table.concat({
      'rsync -rvuzL www/ ',
      host,
      ':',
      path
    }))
  end
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  DeployPlugin = _class_0
  return _class_0
end
