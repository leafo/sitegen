
class Plugin
  -- events: {}
  -- tpl_helpers: { "some_method" }
  -- mixin_funcs: { "some_method" }
  -- write: =>

  new: (@site) =>
    if @events
      for event_name, func in pairs @events
        @site.events\on event_name, (...) -> func @, ...

{
  :Plugin
}
