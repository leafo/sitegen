
module "sitegen.deploy", package.seeall
require "sitegen.common"

export ^

-- 'rsync -arvuz www/ leaf@leafo.net:www/test'
class Sync
  new: (@host, @path) =>
  upload: =>
    os.execute table.concat {
      'rsync -arvuz www/ ', @host ,':', @path
    }

class DeployPlugin
  mixin_funcs: { "deploy_to" }

  help: [[
    This is how you use this plugin....
  ]]

  deploy_to: (@host=error"need host", @path=error"need path") =>

sitegen.register_plugin DeployPlugin

