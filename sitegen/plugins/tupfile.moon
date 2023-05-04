-- This is an experimental plugin that is able to generate a tupfile for
-- building the site incrementally in a more reliable way than watch mode

import Plugin from require "sitegen.plugin"

class TupfilePlugin extends Plugin
  command_actions: {
    {
      method: "generate_tupfile"
      argparser: (command) ->
        with command
          \summary "Generate a tupfile for building the site"
    }
  }

  new: (@site) =>

  generate_tupfile: (args) =>
    output_lines = {}

    -- this needs to implement everything from Site:write
    -- [ ] render pages
    -- [ ] run build commands
    -- [ ] run copy commands
    -- [ ] execute plugin writes

    for page in *@site\load_pages!
      source = @site.io.full_path page.source
      target = @site.io.full_path page.target

      table.insert output_lines, ": #{source} |> sitegen build #{source} |> #{target}"

    print table.concat output_lines, "\n"


