local lfs = require("lfs")
local Path
Path = require("sitegen.common").Path
local Site = require("sitegen.site")
local extend, run_with_scope
do
  local _obj_0 = require("moon")
  extend, run_with_scope = _obj_0.extend, _obj_0.run_with_scope
end
local moonscript = require("moonscript.base")
Path = require("sitegen.path")
local throw_error, trim, escape_patt
do
  local _obj_0 = require("sitegen.common")
  throw_error, trim, escape_patt = _obj_0.throw_error, _obj_0.trim, _obj_0.escape_patt
end
local Logger
Logger = require("sitegen.output").Logger
local SiteFile
do
  local _base_0 = {
    find_root = function(self)
      local dir = lfs.currentdir()
      local depth = 0
      while dir do
        local path = Path.join(dir, self.name)
        if Path.exists(path) then
          self.file_path = path
          self:set_rel_path(depth)
          return 
        end
        dir = Path.up(dir)
        depth = depth + 1
      end
      return throw_error("failed to find sitefile `" .. tostring(self.name) .. "`")
    end,
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
      self.io = Path:relative_to(self.rel_path)
    end,
    get_site = function(self)
      self.logger:notice("Using", Path.join(self.rel_path, self.name))
      local fn = assert(moonscript.loadfile(self.file_path))
      local sitegen = require("sitegen")
      local old_write = Site.write
      local site_ref, site
      Site.__base.write = function(site)
        site_ref = site
        return site
      end
      do
        local old_master = self.__class.master
        self.__class.master = self
        site = run_with_scope(fn, {
          sitegen = require("sitegen")
        })
        self.__class.master = old_master
      end
      Site.__base.write = old_write
      return assert(site, "Failed to load site from sitefile, make sure site is returned")
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.name = opts.name or "site.moon"
      self.logger = Logger(opts.logger_opts)
      if opts.rel_path then
        self.rel_path = opts.rel_path
        self.file_path = Path.join(self.rel_path, self.name)
        return self:make_io()
      else
        return self:find_root()
      end
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
  local self = _class_0
  self.master = nil
  SiteFile = _class_0
end
return {
  SiteFile = SiteFile
}
