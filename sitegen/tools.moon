
system_command = (cmd, ext) ->
  (input, output) =>
    output = output and @real_output_path_for(output) or @real_output_path_for(input, ext)
    real_cmd = cmd\format input, output
    real_cmd\match"^%w+", real_cmd, os.execute real_cmd

{
  :system_command
}
