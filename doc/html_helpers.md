{
  target: "doc/html-helpers"
  id: "html_helpers"
  title: "HTML Variables & Helpers"
}

# HTML &amp; Markdown Helpers

Both HTML and Markdown templates and pages are passed through [cosmo][] to
interpolate any variables or call any helper functions.

For Markdown, the cosmo interpolation happens after the text is compiled to
HTML.

## Variables

Any variables set in your `site.moon` or in the header of your page can be
accessed directly by name when prefixed with `$`:


```html
{
  title: "Hello and welcome to the page"
  date: "June 5th, 2022"
}

<h1>$title</h1>
<h2 class="post_date">$date</h2>

<p>Hello!</p>
```


### Built in variables

There are a few variables that are always available, here they are:

* `$root` -- a relative path prefix that points back to the top level directory of your site. For example, if the current page is `wwww/hello/world.html`, the `$root` would be `../`. This make it easy to built URLs to other pages without being concerned about where your page is being rendered to.
* `$generate_date` -- a timestamp of when the page is being generated. Good for displaying on your page, and also adding to URLs of assets as a cache buster.

[Plugins][plugins] may also introduce variables, in addition to functions, that can be accessed from a page.


## Functions

In addition to variables, there are a handful of built in functions that can be
called from pages and templates. Cosmo provides syntax for calling functions.
You still prefix their name with `$` but you can pass arguments with `{}` and a
subtemplate with `[[]]`. The examples below will demonstrate.

### `$render`

Renders another template. Templates are searched relative to the directory
where `site.moon` is located. Any of the page types supported by sitegen can be
rendered.

```html
<p>Here are my favorite links:</p>
$render{"favorite_links.md"}
```

### `$markdown`

Renders markdown directly into the current page. This is useful when you have
an HTML page that you'd like to insert some formatted text into easily:

Takes one argument, a string of markdown.

```html
<div class="sidebar">
$markdown{[[
# Hello

* [Cool code][1]
* [Cool games][2]

[1]: http://leafo.net
[2]: http://itch.io
]]}
</div>
```

### `$wrap`

### `$url_for`

### `$query_pages`

### `$query_page`

Like `$query_pages` but will throw an error unless 1 page is returned from the
query.


### `$neq`

### `$eq`

### `$if`

### `$each`

### `$is_page`


[cosmo]: http://cosmo.luaforge.net/
[plugins]: $root/doc/plugins.html
