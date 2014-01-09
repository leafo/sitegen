module(..., package.seeall)
local html = require("sitegen.html")
local extend, bind_methods
do
  local _table_0 = require("moon")
  extend, bind_methods = _table_0.extend, _table_0.bind_methods
end
local scope = {
  write = function(self, ...)
    local _list_0 = {
      ...
    }
    for _index_0 = 1, #_list_0 do
      local thing = _list_0[_index_0]
      table.insert(self.buffer, tostring(thing))
    end
  end,
  html = function(self, ...)
    return self:write(html.build(...))
  end,
  render = function(self)
    return table.concat(self.buffer, "\n")
  end
}
make_context = function(page)
  return bind_methods(extend({
    buffer = { }
  }, scope))
end
