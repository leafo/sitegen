
array_includes = (array, val) ->
  return true if array == val
  return false unless type(array) == "table"

  for array_val in *array
    return true if array_val == val

  false

query_page_match = (page, query) ->
  -- empty query matches all
  return true if not query or not next query

  for k, query_val in pairs query
    page_val = page.meta[k]
    if type(query_val) == "function"
      return false unless query_val page_val
    else
      return false unless page_val == query_val

  true

query_pages = (pages, query={}, opts={}) ->
  out = for page in *pages
    continue unless query_page_match page, query
    page

  -- sort..
  if opts.sort
    nil

  out


cmp = {
  date: (dir="desc") ->
    date = require "date"
    (a, b) ->
      if dir == "asc"
        date(a) < date(b)
      else
        date(a) > date(b)
}

filter = {
  -- sees if value is argument, or value contains argument
  -- { tag: contains "hello" } --> tag == "hello", tag = {"hello", ...}
  contains: (val) ->
    (page_val) -> array_includes page_val, val
}

{ :query_pages, :cmp, :filter }
