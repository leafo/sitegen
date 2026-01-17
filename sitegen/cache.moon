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
  new: (@site, @fname=".sitegen_cache") =>
    @finalize = {}
    @disabled = false

  load_cache: =>
    return if @loaded
    @loaded = true

    if @disabled
      @cache = CacheTable!
      return

    @cache = if @site.io.exists @fname
      content = @site.io.read_file @fname

      cache, err = unserialize content

      unless cache
        error "could not load cache `#{@fname}`, delete and try again: #{err}"
      cache
    else
      {}

    CacheTable\inject @cache

  write: =>
    fn self for fn in *@finalize

    return if @disabled

    text = serialize @cache
    error "failed to serialize cache" if not text
    @site.io.write_file @fname, text

  set: (...) =>
    @load_cache!
    @cache\set ...

  get: (...) =>
    @load_cache!
    @cache\get ...

{
  :Cache
  :CacheTable
}

