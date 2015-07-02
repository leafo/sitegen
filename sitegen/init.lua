local Site = require("sitegen.site")
local colors = require("ansicolors")
local create_site
create_site = function(init_fn, site)
  if site == nil then
    site = Site()
  end
  io.stderr:write(colors("%{bright}%{red}WARNING: %{reset}sitegen.create_site is deprecated, use create and add markdown files manually.\n"))
  do
    local _with_0 = site
    _with_0:init_from_fn(init_fn)
    if not (_with_0.autoadd_disabled) then
      _with_0.scope:search("*md")
    end
    return _with_0
  end
end
local create
create = function(init_fn, site)
  if site == nil then
    site = Site()
  end
  assert(init_fn, "Attempted to create site without initialization function")
  do
    local _with_0 = site
    _with_0:init_from_fn(init_fn)
    return _with_0
  end
end
return {
  create_site = create_site,
  create = create
}
