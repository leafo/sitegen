
    ```moon
    -- site.moon
    require "sitegen"
    site = sitegen.create_site =>
      deploy_to "leaf@leafo.net", "www/sitegen"

      @title = "Sitegen"
      @url = "http://leafo.net/sitegen/"

      add "index.html"
      add "doc/ref.md"

    site\write!
    ```
