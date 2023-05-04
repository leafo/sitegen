import Plugin from require "sitegen.plugin"

class DeployPlugin extends Plugin
  mixin_funcs: { "deploy_to" }
  command_actions: {
    {
      method: "deploy"
      argparser: (command) ->
        with command
          \summary "Deploy previously generated site over ssh using rsync"

          \argument("host", "Sever hostname")\args "?"
          \argument("path", "Path on server to deploy to")\args "?"
    }
  }

  deploy_to: (@host=error"need host", @path=error"need path") =>

  deploy: (args) =>
    import throw_error from require "sitegen.common"
    import log from require "sitegen.cmd.util"

    host = args.host or @host
    path = args.path or @path

    throw_error "need host" unless host
    throw_error "need path" unless path

    log "uploading to:", host, path

    @sync!

  -- 'rsync -arvuz www/ leaf@leafo.net:www/test'
  sync: =>
    assert @host, "missing host for deploy"
    assert @path, "missing path for deploy"

    os.execute table.concat {
      'rsync -rvuzL www/ ', @host ,':', @path
    }

