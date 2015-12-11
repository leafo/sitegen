_G.unpack or= require("sitegen.common").unpack

_G.loadstring or= (str, chunkname) ->
  load coroutine.wrap(-> coroutine.yield str), chunkname

require "cosmo"

