_G.unpack = _G.unpack or require("sitegen.common").unpack
_G.loadstring = _G.loadstring or function(str, chunkname)
  return load(coroutine.wrap(function()
    return coroutine.yield(str)
  end), chunkname)
end
return require("cosmo")
