
class Plugin
  -- events: {}
  -- tpl_helpers: { "some_method" }
  -- mixin_funcs: { "some_method" }
  -- write: =>

  new: (@site) =>
    if @events
      @event_callbacks = {}
      for event_name, func in pairs @events
        callback = (...) -> func @, ...
        @site.events\on event_name, callback
        table.insert @event_callbacks, {event_name, callback}

  -- unregisters the handlers added for @events
  detach: =>
    return unless @event_callbacks
    for {event_name, callback} in *@event_callbacks
      @site.events\off event_name, callback

    @event_callbacks = nil

{
  :Plugin
}
