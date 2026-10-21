{
  target: "doc/plugins"
  id: "plugins"
  title: "Plugins - Sitegen"
}

# Plugins

$index{min_depth = 2}

## Method Types

Plugins provide methods to different parts of the site generation pipeline. The
method types are:

* **template helpers**: Method made available in any template file (html, markdown, etc)
* **site helpers**: available in the `site.moon` initialization function.
* **command line tool**: available as an action in the command line tool, `sitegen`.

Plugins can also change other aspects of the pipeline, for example, the
[syntax highlighting](#available-plugins/syntax-highlighting) plugins add a pre-renderer to all
markdown files which let's you specify code blocks in a special syntax.

You can create your own plugins, see the [Creating a Plugin]($root/doc/creating-a-plugin.html) guide.

## Adding and Removing Plugins

A default set of plugins is loaded for every site. Use `add_plugin` and
`remove_plugin` in `site.moon` to change which ones are used. Both take the
module name of the plugin. Removing a plugin also unregisters any events it was
listening to.

For example, to highlight code with Pygments instead of the default syntax
highlighter:

```moon
sitegen.create =>
  remove_plugin "sitegen.plugins.syntaxhighlight"
  add_plugin "sitegen.plugins.pygments"
```

## Available Plugins

### Feed

Provides a site helper called `feed` that triggers a feed to be written from a
MoonScript file when the site is written. First argument is source, second is
destination.

```moon
feed "my_feed.moon", "feeds/feed.xml"
```

The feed file must return a table of feed entires:

```moon
-- my_feed.moon
date = require "date"
return {
  format: "markdown"
  title: "My Site's Title"
  {
    title: "The First Post"
    date: date 2011, 11, 26
    link: "http://example.com/my-post"
    description: [[
      The things I did.

      * ordered pizza
      * ate it
    ]]
  }
}
```


When rendering each entry, if a key is missing the entry, it will be searched
for in the root. This lets you set defaults for entries.

The `format` field is special. If it is set to `"markdown"` then all
descriptions will be rendered to html from markdown.

### Deploy

Provides site helper `deploy_to` and a command line helper `deploy`.

`deply_to` is used to configure where the site should be deployed to, it takes
two arguments, a host and a path. This can be done in the initialization
function:

```moon
deploy_to "leaf@leafo.net", "www/mysite"
```

Deploying is done over ssh with rsync. It uses the command `rsync -arvuz www/
$host:$path`.

Assuming everything is configured correctly, the site can be deployed from the
command line:

```bash
$ sitegen deploy
```

The deploy command line helper will only deploy, it will not build. Make sure
you build the site first.

### Indexer

Provides a template helper, `index`, that indexes the current page based on
headers. It scans the html for header tags (`h1`, `h2`, etc.) and inserts
anchors inside of them. It then renders the tree of headers to a list, with
links to the anchors.

An example page with a header hierarchy. The index rendered at the top:

    $index

    # My Title
    ## Sub-section
    ## Another Sub-section
    ### Deeper
    # Upper Level
    ## Cool

### Syntax Highlighting

Provides new syntax for markdown rendered files. The syntax lets you describe a
code block that should be highlighted according to a specified language.

For example, to highlight Lua code in a page:

```lua
local test = function(...)
  print("hello world", ...)
end

test("moon", 1, 2, 3)
```

The generated code does not have the colors embedded, only html tags with class
names. Colors can be added in a stylesheet.

There are two highlighting plugins, only one should be loaded at a time:

* **Syntaxhighlight** (`sitegen.plugins.syntaxhighlight`): uses the
  [syntaxhighlight](https://github.com/leafo/lua-syntaxhighlight) Lua library,
  so nothing outside of Lua needs to be installed. Class names are prefixed
  with `sh_`. The language name can be one of the aliases in the plugin's
  `language_aliases` table, eg. `moon` for `moonscript`. This is loaded by
  default.
* **Pygments** (`sitegen.plugins.pygments`): runs the [Pygments command line
  tool](https://pygments.org/docs/cmdline/), which must be installed. Results
  are cached between builds. See [Adding and Removing
  Plugins](#adding-and-removing-plugins) to use it instead of syntaxhighlight.

#### Migrating from Pygments

Older versions of Sitegen used Pygments by default. After switching to
syntaxhighlight, stylesheets need to target the new `sh_` class names, and any
`custom_highlighters` registered on `PygmentsPlugin` must be moved to
`SyntaxhighlightPlugin` (Sitegen prints a warning for highlighters registered
on a plugin that isn't loaded).

#### Custom Highlighters

The `custom_highlighters` table on either plugin class lets you replace the
output for a language entirely. The function receives the plugin instance, the
code, and the page, and returns the HTML to insert in place of the code block.

```moon
SyntaxhighlightPlugin = require "sitegen.plugins.syntaxhighlight"

SyntaxhighlightPlugin.custom_highlighters.moon = (code, page) =>
  "<div class='example'>#{@pre_tag @highlight("moon", code), "moon"}</div>"
```

### CoffeeScript

Provies a template helper, `render_coffee` that lets you embed compiled
CoffeeScript into the page from an external file. CoffeeScript must be
installed on the system for this plugin to work.

In some page:


    $render_coffee{[[my_script.coffee]]}

It will produce `script` tags embedded with the resulting JavaScript.

### Analytics

Provides a template helper, `analytics`, that lets your easily embed the Google
Analytics tracking code. Takes one argument, the measurement ID (e.g. `G-XXXXXXXXXX`) as a string.

In some page:

    $analytics{[[G-XXXXXXXXXX]]}

### Dump

Provides a template helper, `dump` that dumps the contents of a variable.
Will pretty-print tables. Useful for debugging.

In some page

    $dump{title}

