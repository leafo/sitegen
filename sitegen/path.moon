io = io

needs_shell_escape = (str) ->
  not not str\match "[^%w_-]"

shell_escape = (str) ->
  str\gsub "'", "''"

local *

-- move up a directory
-- /hello/world -> /hello
up = (path) ->
  path = path\gsub "/$", ""
  path = path\gsub "[^/]*$", ""
  path if path != ""

exists = (path) ->
  file = io.open path
  file\close! and true if file

normalize = (path) ->
  (path\gsub "^%./", "")

basepath = (path) ->
  (path\match"^(.*)/[^/]*$" or ".")

filename = (path) ->
  (path\match"([^/]*)$")

-- write a file, making sure directory exists and file isn't already written
write_file_safe = (path, content, check_exists=false) ->
  if check_exists and exists path
    return nil, "file already exists `#{path}`"

  if prefix = path\match "^(.+)/[^/]+$"
    mkdir prefix unless exists prefix

  write_file path, content
  true

write_file = (path, content) ->
  assert content, "trying to write `#{path}` with no content"
  with io.open path, "w"
    \write content
    \close!

read_file = (path) ->
  file = io.open path
  error "file doesn't exist `#{path}'" unless file
  with file\read "*a"
    file\close!

mkdir = (path) ->
  os.execute "mkdir -p '#{shell_escape path}'"

rmdir = (path) ->
  os.execute "rm -r '#{shell_escape path}'"

copy = (src, dest) ->
  os.execute "cp '#{shell_escape src}' '#{shell_escape dest}'"

join = (a, b) ->
  assert a, "missing left argument to Path.join"
  assert b, "missing right argument to Path.join"

  a = a\match"^(.*)/$" or a if a != "/"
  b = b\match"^/(.*)$" or b
  return b if a == ""
  return a if b == ""
  a .. "/" .. b

_prepare_command = (cmd, ...) ->
  args = for x in *{...}
    if needs_shell_escape x
      "'#{shell_escape x}'"
    else
      x

  args = table.concat args, " "
  with out = "#{cmd} #{args}"
    print out

exec = (cmd, ...) ->
  os.execute _prepare_command cmd, ...

read_exec = (cmd, ...) ->
  f = assert io.popen _prepare_command(cmd, ...), "r"
  with f\read "*a"
    f\close!

relative_to = (prefix) =>
  methods = {"mkdir", "read_file", "write_file", "exists"}

  prefixed = (fn) ->
    (path, ...) ->
      @[fn] @.join(prefix, path), ...

  m = setmetatable {m, prefixed(m) for m in *methods}, {
    __index: @
  }

  m.full_path = (path) -> @.join prefix, path
  m.get_prefix = -> prefix
  m.set_prefix = (p) -> prefix = p

  m

annotate = =>
  wrap_module = (obj, verbs) ->
    setmetatable {}, {
      __newindex: (name, value) =>
        obj[name] = value

      __index: (name) =>
        fn =  obj[name]
        return fn if not type(fn) == "function"
        if verbs[name]
          (...) ->
            fn ...
            print verbs[name], (...)
        else
          fn
    }

  colors = require "ansicolors"
  wrap_module @, {
    mkdir: colors "%{bright}%{magenta}made directory%{reset}"
    write_file: colors "%{bright}%{yellow}wrote%{reset}"
    read_file: colors "%{bright}%{green}read%{reset}"
    exists: colors "%{bright}%{cyan}exists?%{reset}"
    exec: colors "%{bright}%{red}exec%{reset}"
    read_exec: colors "%{bright}%{red}exec%{reset}"
  }

{
  :up, :exists, :normalize, :basepath, :filename, :write_file,
  :write_file_safe, :mkdir, :rmdir, :copy, :join, :read_file, :shell_escape,
  :exec, :read_exec

  :relative_to, :annotate
}
