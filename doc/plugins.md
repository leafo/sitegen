
## Plugin Lifespan

The lifespan of a plugin is started by registering a plugin using
`sitegen.register_plugin()`

* The plugin is registered...
  * `on_register` class method called if exists
* The site is created...
  * If the *plugin class* has field `type_name`, plugin is saved as an
	aggregator for that type. (may be a list of types)
  * `on_site` class method called if exists, passed in site instance
* The site is prepared to be initialized from function...
  * The *plugin class* is checked for field `mixin_funcs`, which is an optional
	list of function names in the class that are inserted into the site scope.
	The functions are guaranteed to be called with *plugin class* as first
	argument
* `write` is called on the site...
  * for every page...
	* Page is checked for an `is_a` meta field, if it exists and matches one
	  of the aggregator types mentioned above, `on_aggregate` is called on the
	  corresponding *plugin class* with the page instance as the argument
	* The page is written (rendered)...
	  * template helpers are extracted from the plugin if it has a
		`tpl_helpers` field. If there are helpers, the plugin is instanced. The
		constructor is passed the `tpl_scope`. All the `tpl_helpers` inserted
		into site scope automatically, and are guaranteed to be called with
		*plugin instance* as first object
  * `write` class method is called if exists

### Terminology

**site scope**: the object that represents the function environment that is used
when running the initialize function.

**template scope**: the object that holds all the fields available to any
template rendered for that page. It is made of, in order, the page meta data,
the site's user vars, and finally the template helpers.
