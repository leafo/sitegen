    template: home
--

## About

Sitegen assembles webpages through a pipeline consisting of templates and
pages.

Pages and templates can be written in html or markdown. The site is defined
through the `site.moon` file, which is written in [MoonScript][2]. It describes all
pages that need to be brought in, it can also specify configuration variables
accessible within pages and templates. 

Pages can be assigned any number of **types**, which lets your aggregate pages
into groups. Enabling you to create blogs, among other things.

Sitegen has a [plugin system][3] that lets you transform the page as it travels
through the pipeline. Letting you do things like syntax highlighting and
automatically generated headers.

Sitegen uses the [cosmo templating language][1] to inject variables, run
functions, and trigger actions in the body of the page as it is being created.


## Install

    ```bash
    $ luarocks build https://raw.github.com/leafo/sitegen/master/sitegen-dev-1.rockspec
    ```

  [View source on GitHub](https://github.com/leafo/sitegen).

  [1]: http://cosmo.luaforge.net/
  [2]: http://moonscript.org/
  [3]: ./doc/plugins.html

