
module "sitegen.cache", package.seeall

import concat from table
export Cache, CacheTable

require "cjson"

serialize = (obj) -> cjson.encode obj
unserialize = (text) -> cjson.decode text

class CacheTable
  __tostring: => "<CacheTable>"

  @inject = (tbl) =>
    setmetatable tbl, self.__base

  get: (name, default=(-> CacheTable!)) =>
    val = self[name]

    if type(val) == "table" and getmetatable(val) != @@__base
      @@inject val

    if val == nil
      val = default!
      self[name] = val
      val
    else
      val

  set: (name, value) =>
    self[name] = value

class Cache
  @clear = =>
    c = Cache nil, true
    c\clear!

  new: (@fname=".sitegen_cache", skip_load=false) =>
    @finalize = {}
    @cache = {}
    if not skip_load
      f = io.open @fname
      if f
        @cache, err = unserialize f\read"*a"
        if not @cache
          error concat {
            "Could not load cache, "
            @fname
            ", please delete and try again: "
            err
          }
        f\close!

    CacheTable\inject @cache

  write: =>
    fn self for fn in *@finalize
    text = serialize @cache
    error "Failed to serialize cache" if not text
    with io.open @fname, "w"
      \write text
      \close!


  clear: =>
    os.remove @fname

  set: (...) => @cache\set ...
  get: (...) => @cache\get ...

