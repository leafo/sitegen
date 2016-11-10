{
  id: "renderers.markdown"
  target: "doc/renderers-markdown"
}

# Markdown renderer

The Markdown renderer renders a page using a Markdown template. It's
automatically acitvated when you add a file ending in `.md` to your sitefile.

The markdown template is compiled to HTML before any variables or cosmo
expressions are executed and replaced.

Markdown template support a *frontmatter* object that lets you add more
variables to the page while it compiles. Place a MoonScript object starting at
the first line of the file to provide additional variables:

```html
{
  title: "Hello and welcome to the page"
  date: "June 5th, 2022"
}

# $title

## $date

Hello world, here are some foots:

* Apple
* Ice cream
```



