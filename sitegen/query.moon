
array_includes = (array, val) ->
  for array_val in *array
    return true if array_val == val
  false

query_page_match = (page, query) ->
  -- empty query matches all
  return true if not query or not next query

  for k,query_val in pairs query
    page_val = page.meta[k]

    if type(page_val) == "table"
      if array_includes page_val, query_val
        continue

    if page_val != query_val
      return false

  true

query_pages = (pages, query={}, opts={}) ->
  out = for page in *pages
    continue unless query_page_match page, query
    page

  -- sort..
  if opts.sort
    nil

  out

{ :query_pages }
