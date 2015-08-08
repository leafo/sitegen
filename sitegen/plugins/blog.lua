local Plugin
Plugin = require("sitegen.plugin").Plugin
local html = require("sitegen.html")
local cosmo = require("cosmo")
local query = require("sitegen.query")
local copy, bind_methods
do
  local _obj_0 = require("moon")
  copy, bind_methods = _obj_0.copy, _obj_0.bind_methods
end
local insert
insert = table.insert
local render_feed
render_feed = require("sitegen.plugins.feed").render_feed
local BlogPlugin
do
  local _parent_0 = Plugin
  local _base_0 = {
    mixin_funcs = {
      "blog_feed"
    },
    blog_feed = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.create_feed = true
      for k, v in pairs(opts) do
        self.opts[k] = v
      end
    end,
    write = function(self)
      if not (self.create_feed) then
        return 
      end
      self.posts = self.site:query_pages(self.opts.filter, {
        sort = query.sort.date()
      })
      if not (self.posts[1]) then
        return 
      end
      self.site.logger:plain("blog posts:", #self.posts)
      local title, url, description
      do
        local _obj_0 = self.site.user_vars
        title, url, description = _obj_0.title, _obj_0.url, _obj_0.description
      end
      local feed_posts
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self.posts
        for _index_0 = 1, #_list_0 do
          local page = _list_0[_index_0]
          local meta = page.meta
          local _value_0 = self.opts.prepare(page, {
            title = meta.title,
            date = meta.date,
            link = page:url_for(true),
            description = rawget(meta, "description")
          })
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        feed_posts = _accum_0
      end
      local rss_text = render_feed({
        title = self.opts.title or title,
        description = self.opts.description or description,
        link = self.opts.url or url,
        unpack(feed_posts)
      })
      return self.site:write_file(self.opts.out_file, rss_text)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, site)
      self.site = site
      self.opts = {
        out_file = "feed.xml",
        filter = {
          is_a = query.filter.contains("blog_post")
        },
        prepare = function(page, ...)
          return ...
        end
      }
    end,
    __base = _base_0,
    __name = "BlogPlugin",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        return _parent_0[name]
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  BlogPlugin = _class_0
  return _class_0
end
