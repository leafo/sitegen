require("sitegen.common")
local DeployPlugin
do
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
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "DeployPlugin"
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
  self.sync = function(self, host, path)
    return os.execute(table.concat({
      'rsync -rvuzL www/ ',
      host,
      ':',
      path
    }))
  end
  DeployPlugin = _class_0
  return _class_0
end
