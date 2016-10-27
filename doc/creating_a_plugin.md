{
  target: "doc/creating-a-plugin"
  id: "creating_a_plugin"
  title: "Creating a plugin - Sitegen"
}

# Creating a Plugin

$index{min_depth = 2}

Much of the built in functionality in Sitegen is implemented by plugins. You
can create your own plugins to add custom functionality to the various steps of
building the site. A plugin is implemented as a MoonScript class. Functionality
is injected into the build by implemending certain properties or methods.  The
*Plugin Lifecycle* describes what happens to a plugin when Sitegen builds the
site.

## Plugin Lifecycle

* Each plugin is instantiated for the site being compiling. The constructor receives one argument, the instance of the site. The instances of the plugins are stored in the site.
* Before Sitegen reads `site.moon`...
  * For each plugin that provides a `mixin_funcs` property:
    *  Each method listed in `mixin_funcs` is copied to the site's config scope. These methods can be called from `site.moon`, they are bound to the instance of the plugin
  * For each plugin with a `type_name` property:
    * Plugin is saved as an aggregator for that type
* As Sitegen renders each page...
  * For each page that has an `is_a` property:
    * Any plugins marked as aggregators with a `type_name` matching a value in `is_a` are called via the `on_aggregate` method. The current page is passed to the method as the first argument
  * For each plugin that provides a `tpl_helpers` property:
    * Each method listed in `tpl_helpers` is made available to be called in any template, the methods are bound the instance of the plugin. They will also receive an instance of a page before any arguments passed to the method.
* After Sitegen has rendered all the pages...
  * Any plugins implementing a `write` method are called. The `write` method is called with no arguments. This is when a plugin can create any necessary side effect files

### Terminology

**site scope**: the object that represents the function environment that is
used when running the initialize function. The `mixin_funcs` property on a
plugin is used to extend this scope.

**template scope**: the object that holds all the fields available to any
template rendered for that page. The `tpl_helpers` property on a plugin is used
to extend this scope.

