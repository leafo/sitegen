local log
log = function(...)
  return print(...)
end
local colors = {
  reset = 0,
  bright = 1,
  red = 31,
  yellow = 33
}
do
  local _tbl_0 = { }
  for name, key in pairs(colors) do
    _tbl_0[name] = string.char(27) .. "[" .. tostring(key) .. "m"
  end
  colors = _tbl_0
end
local make_bright
make_bright = function(color)
  return function(str)
    return colors.bright .. colors[color] .. tostring(str) .. colors.reset
  end
end
return {
  log = log,
  make_bright = make_bright,
  bright_red = make_bright("red"),
  bright_yellow = make_bright("yellow")
}
