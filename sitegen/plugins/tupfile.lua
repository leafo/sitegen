local Plugin
Plugin = require("sitegen.plugin").Plugin
local TupfilePlugin
do
  local _class_0
  local _parent_0 = Plugin
  local _base_0 = {
    command_actions = {
      {
        method = "generate_tupfile",
        argparser = function(command)
          do
            local _with_0 = command
            _with_0:summary("Generate a tupfile for building the site")
            return _with_0
          end
        end
      }
    },
    generate_tupfile = function(self, args)
      local output_lines = { }
      local _list_0 = self.site:load_pages()
      for _index_0 = 1, #_list_0 do
        local page = _list_0[_index_0]
        local source = self.site.io.full_path(page.source)
        local target = self.site.io.full_path(page.target)
        table.insert(output_lines, ": " .. tostring(source) .. " |> sitegen build " .. tostring(source) .. " |> " .. tostring(target))
      end
      return print(table.concat(output_lines, "\n"))
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
    end,
    __base = _base_0,
    __name = "TupfilePlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
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
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  TupfilePlugin = _class_0
  return _class_0
end
