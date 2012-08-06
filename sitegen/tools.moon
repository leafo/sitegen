
module ..., package.seeall

export system_command = (cmd, ext) ->
  (input, output) =>
    output = output and @real_output_path_for(output) or @real_output_path_for(input, ext)
    cmd = cmd\format input, output
    cmd\match"^%w+", cmd, os.execute cmd

export lessphp = (input, output) =>
  cmd  = "plessc -r < " .. input .. " > " .. output
  "lessphp", cmd, os.execute cmd

