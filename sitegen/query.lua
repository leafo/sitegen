local array_includes
array_includes = function(array, val)
  if array == val then
    return true
  end
  if not (type(array) == "table") then
    return false
  end
  for _index_0 = 1, #array do
    local array_val = array[_index_0]
    if array_val == val then
      return true
    end
  end
  return false
end
local query_page_match
query_page_match = function(page, query)
  if not query or not next(query) then
    return true
  end
  for k, query_val in pairs(query) do
    local page_val = page.meta[k]
    if type(query_val) == "function" then
      if not (query_val(page_val)) then
        return false
      end
    else
      if not (page_val == query_val) then
        return false
      end
    end
  end
  return true
end
local query_pages
query_pages = function(pages, query, opts)
  if query == nil then
    query = { }
  end
  if opts == nil then
    opts = { }
  end
  local out
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #pages do
      local _continue_0 = false
      repeat
        local page = pages[_index_0]
        if not (query_page_match(page, query)) then
          _continue_0 = true
          break
        end
        local _value_0 = page
        _accum_0[_len_0] = _value_0
        _len_0 = _len_0 + 1
        _continue_0 = true
      until true
      if not _continue_0 then
        break
      end
    end
    out = _accum_0
  end
  if opts.sort then
    table.sort(out, opts.sort)
  end
  return out
end
local cmp = {
  date = function(dir)
    if dir == nil then
      dir = "desc"
    end
    local date = require("date")
    return function(a, b)
      if dir == "asc" then
        return date(a) < date(b)
      else
        return date(a) > date(b)
      end
    end
  end
}
local filter = {
  contains = function(val)
    return function(page_val)
      return array_includes(page_val, val)
    end
  end,
  is_set = function()
    return function(page_val)
      return page_val ~= nil
    end
  end
}
local sort = {
  date = function(key, dir)
    if key == nil then
      key = "date"
    end
    return function(p1, p2)
      return cmp.date(dir)(p1.meta[key], p2.meta[key])
    end
  end
}
return {
  query_pages = query_pages,
  cmp = cmp,
  filter = filter,
  sort = sort
}
