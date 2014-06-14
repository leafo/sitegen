local system_command
system_command = function(cmd, ext)
  return function(self, input, output)
    output = output and self:real_output_path_for(output) or self:real_output_path_for(input, ext)
    local real_cmd = cmd:format(input, output)
    return real_cmd:match("^%w+"), real_cmd, os.execute(real_cmd)
  end
end
return {
  system_command = system_command
}
