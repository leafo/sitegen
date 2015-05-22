import concat from table

json = require "cjson"

serialize = (obj) -> json.encode obj
unserialize = (text) -> json.decode text

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

  new: (@site, @fname=".sitegen_cache", skip_load=false) =>
    @finalize = {}
    @cache = {}

    unless skip_load
      @load_cache!

    CacheTable\inject @cache

  load_cache: =>
    return unless @site.io.exists @fname
    content = @site.io.read_file @fname
    @cache, err = unserialize content
    unless @cache
      error "could not load cache `#{@fname}`, delete and try again: #{err}"

  write: =>
    fn self for fn in *@finalize
    text = serialize @cache
    error "failed to serialize cache" if not text
    @site.io.write_file @fname, text

  clear: =>
    error "FIXXME" -- needs to be relative
    os.remove @fname

  set: (...) => @cache\set ...
  get: (...) => @cache\get ...


{
  :Cache
  :CacheTable
}

