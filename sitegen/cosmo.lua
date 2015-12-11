_G.unpack = _G.unpack or require("sitegen.common").unpack
_G.loadstring = _G.loadstring or function(str, chunkname)
  return load(coroutine.wrap(function()
    return coroutine.yield(str)
  end), chunkname)
end
_G.getfenv = _G.getfenv or require("moonscript.util").getfenv
_G.setfenv = _G.setfenv or require("moonscript.util").setfenv
return require("cosmo")
