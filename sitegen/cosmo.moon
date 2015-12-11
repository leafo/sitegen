_G.unpack or= require("sitegen.common").unpack

_G.loadstring or= (str, chunkname) ->
  load coroutine.wrap(-> coroutine.yield str), chunkname

_G.getfenv or= require("moonscript.util").getfenv
_G.setfenv or= require("moonscript.util").setfenv

require "cosmo"

