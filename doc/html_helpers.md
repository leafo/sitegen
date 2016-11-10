{
  target: "doc/html-helpers"
  id: "html_helpers"
  title: "HTML Variables & Helpers"
}

## Variables

When a page is rendering it has access to a set of variables and helper
functions. They can be provided in three scopes, with lowest precednece first:

* Built in variables -- provided by `sitegen`
* Site level variables -- set in `site.moon`
* Page level variables -- set in the page


The variables can be accessed depending on the page renderer used. In the
[Markdown][markdown-renderer] and [HTML renderers][html-renderer], the templating language cosmo is used. You can
access variables by prefixing them with `$`:


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

### `$if{cond}[[subtemplate]]`

### `$each{items, "name"}[[subtemplate]]`

Iterates through the array `items` executing the subtemplate each time. The
current item is assigned to `name` within the subtemplate.


### `$is_page{query_args}[[subtemplate]]`

Runs the subtemplate if if `query_args` matches the current page.


[cosmo]: http://cosmo.luaforge.net/
[plugins]: $root/doc/plugins.html
[markdown-renderer]: $url_for{id="renderers.markdown"}
[html-renderer]: $url_for{id="renderers.html"}

