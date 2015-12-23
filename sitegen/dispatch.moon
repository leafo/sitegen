-- originally from saltw-bot
class Dispatch
  new: =>
    @callbacks = {}

  _parse_name: (name) =>
    assert type(name) == "string", "event name must be string"
    parts = [p for p in name\gmatch "[^.]+"]
    assert next(parts), "invalid name"
    parts

  on: (name, callback) =>
    parts = @_parse_name name

    callbacks = @callbacks
    for p in *parts
      callbacks[p] or= {}
      callbacks = callbacks[p]

    table.insert callbacks, callback

  off: (name) =>
    parts = @_parse_name name
    last = parts[#parts]
    table.remove parts

    callbacks = @callbacks
    for p in *parts
      callbacks = callbacks[p]
    
    callbacks[last] = nil

  callbacks_for: (name) =>
    -- find all the matching callbacks
    matched = {}

    callbacks = @callbacks
    for p in *@_parse_name name
      callbacks = callbacks[p]
      break unless callbacks
      for c in *callbacks
        table.insert matched, c

    matched

  trigger: (name, ...) =>
    count = 0
    e = {
      :name
      cancel: false
      dispatch: @
    }

    for c in *@callbacks_for name
      c e, ...
      count += 1
      break if e.cancel

    count > 0, e

{ :Dispatch }
