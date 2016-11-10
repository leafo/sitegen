{
  id: "renderers.html"
  target: "doc/renderers-html"
}

# HTML renderer

The HTML renderer takes an HTML file and renders it after interpolating any
variables or expressions with cosmo. The HTML renderer is used when you add a
file that ends in `.html`

HTML templates also support a *frontmatter* object that lets you add more
variables to the page while it compiles. Place a MoonScript object starting at
the first line of the file to provide additional variables:

```html
{
  title: "Hello and welcome to the page"
  date: "June 5th, 2022"
}

<h1>$title</h1>
<h2 class="post_date">$date</h2>

<p>Hello!</p>
```

