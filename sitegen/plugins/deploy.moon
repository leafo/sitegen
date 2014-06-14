import Plugin from require "sitegen.plugin"

class DeployPlugin extends Plugin
  -- 'rsync -arvuz www/ leaf@leafo.net:www/test'
  @sync = (host, path) =>
    os.execute table.concat {
      'rsync -rvuzL www/ ', host ,':', path
    }

  mixin_funcs: { "deploy_to" }

  help: [[
    This is how you use this plugin....
  ]]

  deploy_to: (@host=error"need host", @path=error"need path") =>

