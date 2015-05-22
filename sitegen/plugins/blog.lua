local Plugin
Plugin = require("sitegen.plugin").Plugin
local html = require("sitegen.html")
local date = require("date")
local cosmo = require("cosmo")
local copy, bind_methods
do
  local _obj_0 = require("moon")
  copy, bind_methods = _obj_0.copy, _obj_0.bind_methods
end
local insert
insert = table.insert
local FeedPlugin = require("sitegen.plugins.feed")
local cmp = {
  date = function(dir)
    if dir == nil then
      dir = "desc"
    end
    return function(a, b)
      if dir == "asc" then
        return date(a) < date(b)
      else
        return date(a) > date(b)
      end
    end
  end
}
local BlogPlugin
do
  local _parent_0 = Plugin
  local _base_0 = {
    posts = { },
    consumes_pages = false,
    type_name = "blog_post",
    on_site = function(self, site)
      site.templates.plugin_helpers.blog = {
        query = function(arg)
          local _list_0 = self:query()
          for _index_0 = 1, #_list_0 do
            local page = _list_0[_index_0]
            cosmo.yield(bind_methods(page))
          end
        end
      }
    end,
    on_aggregate = function(self, page)
      table.insert(self.posts, page)
      return self.consumes_pages
    end,
    write = function(self, site)
      if not (self.posts[1]) then
        return 
      end
      site.logger:plain("blog posts:", #self.posts)
      local title, url, description
      do
        local _obj_0 = site.user_vars
        title, url, description = _obj_0.title, _obj_0.url, _obj_0.description
      end
      local feed_posts
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self:query()
        for _index_0 = 1, #_list_0 do
          local page = _list_0[_index_0]
          print("*", page.title, page.date)
          local _value_0 = {
            title = page.title,
            date = page.date,
            link = page:url_for(true),
            description = rawget(page.meta, "description")
          }
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        feed_posts = _accum_0
      end
      local rss_text = FeedPlugin.render_feed({
        title = title,
        description = description,
        link = url,
        unpack(feed_posts)
      })
      return site:write_file("feed.xml", rss_text)
    end,
    query = function(self, filter)
      if filter == nil then
        filter = { }
      end
      filter.sort = {
        "date",
        cmp.date()
      }
      local posts = copy(self.posts)
      if filter.sort then
        local col, c = unpack(filter.sort)
        table.sort(posts, function(a, b)
          return c(a[col], b[col])
        end)
      end
      return posts
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  local _class_0 = setmetatable({
    __init = function(self, ...)
      return _parent_0.__init(self, ...)
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
