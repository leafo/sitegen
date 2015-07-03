local array_includes
array_includes = function(array, val)
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
    local _continue_0 = false
    repeat
      local page_val = page.meta[k]
      if type(page_val) == "table" then
        if array_includes(page_val, query_val) then
          _continue_0 = true
          break
        end
      end
      if page_val ~= query_val then
        return false
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
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
    local _ = nil
  end
  return out
end
return {
  query_pages = query_pages
}
