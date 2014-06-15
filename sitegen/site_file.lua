local lfs = require("lfs")
local Path
do
  local _obj_0 = require("sitegen.common")
  Path = _obj_0.Path
end
local Site = require("sitegen.site")
local extend, run_with_scope
do
  local _obj_0 = require("moon")
  extend, run_with_scope = _obj_0.extend, _obj_0.run_with_scope
end
local moonscript = require("moonscript.base")
local throw_error, trim, escape_patt
do
  local _obj_0 = require("sitegen.common")
  Path, throw_error, trim, escape_patt = _obj_0.Path, _obj_0.throw_error, _obj_0.trim, _obj_0.escape_patt
end
local bright_yellow
do
  local _obj_0 = require("sitegen.output")
  bright_yellow = _obj_0.bright_yellow
end
local SiteFile
do
  local _base_0 = {
    relativeize = function(self, path)
      local exec
      exec = function(cmd)
        local p = io.popen(cmd)
        do
          local _with_0 = trim(p:read("*a"))
          p:close()
          return _with_0
        end
      end
      local rel_path
      if self.rel_path == "" then
        rel_path = "."
      else
        rel_path = self.rel_path
      end
      self.prefix = self.prefix or exec("realpath " .. rel_path) .. "/"
      local realpath = exec("realpath " .. path)
      return realpath:gsub("^" .. escape_patt(self.prefix), "")
    end,
    set_rel_path = function(self, depth)
      self.rel_path = ("../"):rep(depth)
      self:make_io()
      package.path = self.rel_path .. "?.lua;" .. package.path
      package.moonpath = self.rel_path .. "?.moon;" .. package.moonpath
    end,
    make_io = function(self)
      self.io = {
        open = function(fname, ...)
          return io.open(self.io.real_path(fname), ...)
        end,
        real_path = function(fname)
          return Path.join(self.rel_path, fname)
        end
      }
    end,
    get_site = function(self)
      print(bright_yellow("Using:"), Path.join(self.rel_path, self.name))
      local fn = moonscript.loadfile(self.file_path)
      local site = nil
      local sitegen = require("sitegen")
      run_with_scope(fn, {
        sitegen = extend({
          create_site = function(fn)
            site = sitegen.create_site(fn, Site(self))
            site.write = function() end
            return site
          end
        }, sitegen)
      })
      site.write = nil
      return site
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, name)
      if name == nil then
        name = "site.moon"
      end
      self.name = name
      local dir = lfs.currentdir()
      local depth = 0
      while dir do
        local path = Path.join(dir, name)
        if Path.exists(path) then
          self.file_path = path
          self:set_rel_path(depth)
          return 
        end
        dir = Path.up(dir)
        depth = depth + 1
      end
      return throw_error("failed to find sitefile: " .. name)
    end,
    __base = _base_0,
    __name = "SiteFile"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SiteFile = _class_0
end
return {
  SiteFile = SiteFile
}
