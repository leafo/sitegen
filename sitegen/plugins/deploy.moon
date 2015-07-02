import Plugin from require "sitegen.plugin"

class DeployPlugin extends Plugin
  mixin_funcs: { "deploy_to" }

  deploy_to: (@host=error"need host", @path=error"need path") =>

  -- 'rsync -arvuz www/ leaf@leafo.net:www/test'
  sync: =>
    assert @host, "missing host for deploy"
    assert @path, "missing path for deploy"

    os.execute table.concat {
      'rsync -rvuzL www/ ', @host ,':', @path
    }

