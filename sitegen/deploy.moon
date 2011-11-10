
module "sitegen.deploy", package.seeall
require "sitegen.common"

export ^

-- 'rsync -arvuz www/ leaf@leafo.net:www/test_page'
class Sync
  new: (@host, @path) =>
  upload: =>
    os.execute table.concat {
      'rsync -arvuz --delete www/ ', @host ,':', @path
    }

class DeployPlugin
  help: [[
    This is how you use this plugin....
  ]]

  mixin_funcs: (scope) =>
    scope.deploy_to = (host=error"need host", path=error"need path") ->
      scope._deploy = Sync host, path

sitegen.register_plugin DeployPlugin

