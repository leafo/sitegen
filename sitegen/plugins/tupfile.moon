-- This is an experimental plugin that is able to generate a tupfile for
-- building the site incrementally in a more reliable way than watch mode

-- TODO: also need to add a clean command to clean up generated files so we can easily migrate to tup where possible

import Plugin from require "sitegen.plugin"
Path = require "sitegen.path"

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

      table.insert output_lines, ": #{source} |> sitegen build %f |> #{target}"

    for buildset in *@site.scope.builds
      -- TODO: the build function might be destructive, so we need to have a
      -- way to detect the common pattern of using a system tool to convert it
      -- into a command within the tupfile
      require("moon").p buildset

    for path in @site.scope.copy_files\each!
      target = Path.join @site.config.out_dir, path
      table.insert output_lines, ": #{path} |> cp %f %o |> #{target}"

    print table.concat output_lines, "\n"


