# Sitegen

Sitegen assembles static webpages through a pipeline consisting of templates and
pages. If you're looking for something dynamic try out [Lapis](http://leafo.net/lapis).

Pages and templates can be written in html or markdown. The site is defined
through the `site.moon` file, which is written in [MoonScript][2]. It describes
all pages that need to be brought in, it can also specify configuration
variables accessible within pages and templates. 

Pages can be assigned any number of **types**, which lets your aggregate pages
into groups. Enabling you to create blogs, among other things.

Sitegen has a [plugin system][3] that lets you transform the page as it travels
through the pipeline. Letting you do things like syntax highlighting and
automatically generated headers.

Sitegen uses the [cosmo templating language][1] to inject variables, run
functions, and trigger actions in the body of the page as it is being created.

$index

## Install

```bash
$ luarocks install sitegen
```

[Get source on GitHub](https://github.com/leafo/sitegen).

## Quick start

### Basic site

To create a new site we just need to create a `site.moon` file in a directory
of our choosing. We'll call the `create` function on the `sitegen` module to
initialize the site. `create` takes one argument, a function that will be used
to initialize the site. An empty function, `=>`, is perfectly valid.

```moonscript
-- site.moon
sitegen = require "sitegen"

sitegen.create =>
```

We can tell our site to build by using the `sitegen` command, run it from the
same directory as `site.moon`. (You can also run it in any child directories,
but we don't have any yet.)

```bash
$ sitegen
```

Since our site file is empty it won't do anything except create a cache file.

Sitegen works great with markdown, lets create a new page in markdown,
`index.md`:

    Hello, and welcome to *my homepage!*

Update `site.moon` to have that file:

```moonscript
-- site.moon
sitegen = require "sitegen"

sitegen.create =>
  add "index.md"
```

And now tell it to build:

```bash
$ sitegen
```

Every time you edit the markdown file you'll have to tell Sitegen to rebuild.
That can be annoying. Start *watch* mode to have it listen for file changes and
automatically rebuild:

```bash
$ sitegen watch
```

Whenever you edit an input file, the corresponding output file will be built.
If you edit `site.moon` you'll have to restart watch mode, sorry!

### Variables

Sometimes you want to share a piece of data across many pages, say a
*version_number* for a open source project's homepage. Just assign the variable
on `self`:

```moonscript
sitegen = require "sitegen"

sitegen.create =>
  @version = "1.2.3-alpha-gamma"
  add "index.md"
```

Then reference it with `$` in your page, here's `index.md`:

    # Welcome
    The current version is $version



### Templates

If you looked at the compiled output of any of the examples above you may have
noticed that each page got wrapped in an `<html>` tag along with a `<head>` and
`<body>`. The *template* defines what wraps each page's contents, there's a
default one that adds those tags. The default one doesn't add much, so you'll
want to create your own.

Here's what the default template looks like:

```html
<!DOCTYPE HTML>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
</head>
<body>
  $body
</body>
</html>
```

The `$body` variable gets the contents of the page, the `$title` variable lets
you set the title of the page. It's `nil` by default, but you can set it in
your `site.moon`

Templates live in the `templates/` directory next to `site.moon`. If you name a
template `index` then it will take place of the default one provided by
Sitegen. Here's a custom default template:

```html
<!-- templates/index.html -->
<html>
<body>
  <h1>GREETINGS</h1>
  $body
</body>
</html>
```

Make sure to include `$body`, otherwise the contents of your page will not be
visible.

### Page options

You can pass individual pages custom options to control how they are rendered,
like where they are written to and what template they use. You can pass these
options to the `add` function in `site.moon`:

```moonscript
sitegen = require "sitegen"

sitegen.create =>
  add "home.md", template: "jumbo_layout", target: "index.html"
```

This will cause the page to be written to `www/index.html`, and it will use the
template located in `templates/jumbo_layout.html`.

### Page types

In all the previous examples we've used Markdown files for our pages. You can
also use HTML files.

All pages are passed through a preprocessor that fills in the variables and
runs any functions, so HTML pages can access the same things as Markdown pages.

To create an HTML page we just give it the extension `html`:

```moonscript
sitegen = require "sitegen"

sitegen.create =>
  add "about.html"
```

```html
<!-- about.html -->
<p>This page was generated on $generate_date, <a href="$root">Go home</a></p>
```

## Next

Now that you know how Sitegen works, you'll want to look over the [plugins][3]
to learn about the additional functionality. All plugins and enabled by default
so no extra steps are required to use them.

## License

MIT License, Copyright (C) 2015 by Leaf Corcoran


[1]: http://cosmo.luaforge.net/
[2]: http://moonscript.org/
[3]: $root/doc/plugins.html

