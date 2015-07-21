import Plugin from require "sitegen.plugin"

class DeployPlugin extends Plugin
  mixin_funcs: { "deploy_to" }
  command_actions: { "deploy" }

  deploy_to: (@host=error"need host", @path=error"need path") =>

  deploy: =>
    import throw_error from require "sitegen.common"
    import log from require "sitegen.cmd.util"

    throw_error "need host" unless @host
    throw_error "need path" unless @path

    log "uploading to:", @host, @path

    @sync!

  -- 'rsync -arvuz www/ leaf@leafo.net:www/test'
  sync: =>
    assert @host, "missing host for deploy"
    assert @path, "missing path for deploy"

    os.execute table.concat {
      'rsync -rvuzL www/ ', @host ,':', @path
    }

