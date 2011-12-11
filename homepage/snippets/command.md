
    ```bash
    $ sitegen new
    ->  made directory  www
    ->  made directory  templates
    ->  wrote  site.moon

    $ sitegen page "Cool Things"
    ->  wrote  cool_things.md

    $ sitegen
    rendered  index.html      ->  www/index.html
    rendered  cool_things.md  ->  www/cool_things.html
    rendered  doc/ref.md      ->  www/doc/ref.html

    $ sitegen deploy
	->  uploading to:  leaf@leafo.net  www/sitegen
    ```
