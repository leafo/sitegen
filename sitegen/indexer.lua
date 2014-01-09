require("sitegen.common")
local html = require("sitegen.html")
local insert, concat = table.insert, table.concat
local render_index
render_index = function(index)
  local yield_index
  yield_index = function(index)
    local _list_0 = index
    for _index_0 = 1, #_list_0 do
      local item = _list_0[_index_0]
      if item.depth then
        cosmo.yield({
          _template = 2
        })
        yield_index(item)
        cosmo.yield({
          _template = 3
        })
      else
        cosmo.yield({
          name = item[1],
          target = item[2]
        })
      end
    end
  end
  local tpl = [==[		<ul>
		$index[[
			<li><a href="#$target">$name</a></li>
		]], [[ <ul> ]] , [[ </ul> ]]
		</ul>
  ]==]
  return cosmo.f(tpl)({
    index = function()
      return yield_index(index)
    end
  })
end
local build_from_html
build_from_html = function(body, meta, opts)
  if opts == nil then
    opts = { }
  end
  local headers = { }
  opts.min_depth = opts.min_depth or 1
  opts.max_depth = opts.max_depth or 9
  local current = headers
  local fn
  fn = function(body, i)
    i = tonumber(i)
    if i >= opts.min_depth and i <= opts.max_depth then
      if not current.depth then
        current.depth = i
      else
        if i > current.depth then
          current = {
            parent = current,
            depth = i
          }
        else
          while i < current.depth and current.parent do
            insert(current.parent, current)
            current = current.parent
          end
          if i < current.depth then
            current.depth = i
          end
        end
      end
    end
    local slug = slugify(html.decode(body))
    insert(current, {
      body,
      slug
    })
    return concat({
      '<h',
      i,
      '><a name="',
      slug,
      '"></a>',
      body,
      '</h',
      i,
      '>'
    })
  end
  require("lpeg")
  local P, R, Cmt, Cs, Cg, Cb, C = lpeg.P, lpeg.R, lpeg.Cmt, lpeg.Cs, lpeg.Cg, lpeg.Cb, lpeg.C
  local nums = R("19")
  local open = P("<h") * Cg(nums, "num") * ">"
  local close = P("</h") * C(nums) * ">"
  local close_pair = Cmt(close * Cb("num"), function(s, i, a, b)
    return a == b
  end)
  local tag = open * C((1 - close_pair) ^ 0) * close
  local patt = Cs((tag / fn + 1) ^ 0)
  local out = patt:match(body)
  while current.parent do
    insert(current.parent, current)
    current = current.parent
  end
  return out, headers
end
local IndexerPlugin
do
  local _parent_0 = nil
  local _base_0 = {
    tpl_helpers = {
      "index"
    },
    index = function(self)
      if not self.current_index then
        local body
        body, self.current_index = build_from_html(self.tpl_scope.body)
        coroutine.yield(body)
      end
      return render_index(self.current_index)
    end
  }
  _base_0.__index = _base_0
  if _parent_0 then
    setmetatable(_base_0, _parent_0.__base)
  end
  local _class_0 = setmetatable({
    __init = function(self, tpl_scope)
      self.tpl_scope = tpl_scope
      self.current_index = nil
    end,
    __base = _base_0,
    __name = "IndexerPlugin",
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
  self.build_from_html = build_from_html
  if _parent_0 and _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  IndexerPlugin = _class_0
  return _class_0
end
