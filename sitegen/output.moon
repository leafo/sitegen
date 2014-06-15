log = (...) ->
  print ...

colors = {
  reset: 0
  bright: 1
  red: 31
  yellow: 33
}
colors = { name, string.char(27) .. "[" .. tostring(key) .. "m" for name, key in pairs colors }

make_bright = (color) ->
  (str) -> colors.bright .. colors[color] .. tostring(str) .. colors.reset


{
  :log
  :make_bright
  bright_red: make_bright"red"
  bright_yellow: make_bright"yellow"
}

