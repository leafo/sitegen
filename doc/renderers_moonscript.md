{
  id: "renderers.moonscript"
  target: "doc/renderers-moonscript"
}

# MoonScript renderer

The MoonScript renderer lets you write a page or template as MoonScript code.
You have the full power of the language to do anything you need to do to
generate the final result. This renderer is automatically used when you add a
file ending in `.moon` in your sitefile.

```moon
html ->
  h1 "Welcome to my page: #{@page_titler}"
```

