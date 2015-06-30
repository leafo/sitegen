local cosmo = require("cosmo")
local html = require("sitegen.html")
local moonscript = require("moonscript.base")
local extend
extend = require("moon").extend
local Path = require("sitegen.path")
local fill_ignoring_pre, throw_error, flatten_args
do
  local _obj_0 = require("sitegen.common")
  fill_ignoring_pre, throw_error, flatten_args = _obj_0.fill_ignoring_pre, _obj_0.throw_error, _obj_0.flatten_args
end
local Templates
do
  local _base_0 = {
    defaults = require("sitegen.default.templates"),
    templates_path = function(self, subpath)
      return Path.join(self.site.config.template_dir, subpath)
    end,
    find_by_name = function(self, name)
      if self.template_cache[name] then
        return self.template_cache[name]
      end
      local _list_0 = self.site.renderers
      for _index_0 = 1, #_list_0 do
        local _continue_0 = false
        repeat
          local renderer = _list_0[_index_0]
          if not (renderer.source_ext) then
            _continue_0 = true
            break
          end
          local fname = self:templates_path(tostring(name) .. "." .. tostring(renderer.source_ext))
          if self.io.exists(fname) then
            self.template_cache[name] = renderer:load(self.io.read_file(fname))
            break
          end
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      return self.template_cache[name]
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      self.io = assert(self.site.io, "site missing io")
      self.template_cache = { }
    end,
    __base = _base_0,
    __name = "Templates"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Templates = _class_0
end
return {
  Templates = Templates
}
