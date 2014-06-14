local concat
do
  local _obj_0 = table
  concat = _obj_0.concat
end
local run_with_scope, defaultbl
do
  local _obj_0 = require("moon")
  run_with_scope, defaultbl = _obj_0.run_with_scope, _obj_0.defaultbl
end
local escape_patt
do
  local _obj_0 = require("sitegen.common")
  escape_patt = _obj_0.escape_patt
end
local html_encode_entities, html_decode_entities, html_encode_pattern, encode, escape, decode, unescape, strip_tags, is_list, render_list, render_tag, Text, CData, Tag, tag, builders, build
html_encode_entities = {
  ['&'] = '&amp;',
  ['<'] = '&lt;',
  ['>'] = '&gt;',
  ['"'] = '&quot;',
  ["'"] = '&#039;'
}
html_decode_entities = { }
for key, value in pairs(html_encode_entities) do
  html_decode_entities[value] = key
end
html_encode_pattern = "[" .. concat((function()
  local _accum_0 = { }
  local _len_0 = 1
  for char in pairs(html_encode_entities) do
    _accum_0[_len_0] = escape_patt(char)
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)()) .. "]"
encode = function(text)
  return (text:gsub(html_encode_pattern, html_encode_entities))
end
escape = encode
decode = function(text)
  return (text:gsub("(&[^&]-;)", function(enc)
    local decoded = html_decode_entities[enc]
    if decoded then
      return decoded
    else
      return enc
    end
  end))
end
unescape = decode
strip_tags = function(html)
  return html:gsub("<[^>]+>", "")
end
is_list = function(t)
  return type(t) == "table" and t.type ~= "tag"
end
render_list = function(list, delim)
  local escaped
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #list do
      local item = list[_index_0]
      if type(item) == "string" then
        _accum_0[_len_0] = encode(item)
      elseif is_list(item) then
        _accum_0[_len_0] = render_list(item, delim)
      elseif type(item) == "function" then
        _accum_0[_len_0] = build(item)
      elseif item ~= nil then
        _accum_0[_len_0] = tostring(item)
      else
        _accum_0[_len_0] = error("unknown item")
      end
      _len_0 = _len_0 + 1
    end
    escaped = _accum_0
  end
  return table.concat(escaped, delim)
end
render_tag = function(name, inner, attributes)
  if inner == nil then
    inner = ""
  end
  if attributes == nil then
    attributes = { }
  end
  local formatted_attributes = { }
  for attr_name, attr_value in pairs(attributes) do
    if not attr_name:match("^__") then
      table.insert(formatted_attributes, ('%s="%s"'):format(attr_name, encode(attr_value)))
    end
  end
  if is_list(inner) then
    inner = render_list(inner, "\n")
  else
    inner = tostring(inner)
  end
  local open = table.concat({
    "<",
    name,
    (function()
      if #formatted_attributes > 0 then
        return " " .. table.concat(formatted_attributes, " ")
      else
        return ""
      end
    end)(),
    ">"
  })
  local close = table.concat({
    "</",
    name,
    ">"
  })
  if attributes.__breakclose then
    close = "\n" .. close
  end
  return open .. inner .. close
end
do
  local _base_0 = {
    __tostring = function(self)
      return self.text
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, text)
      self.text = text
      self.type = "tag"
    end,
    __base = _base_0,
    __name = "Text"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Text = _class_0
end
do
  local _base_0 = {
    __tostring = function(self)
      return "<![CDATA[" .. self.text .. "]]>"
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, text)
      self.text = text
      self.type = "tag"
    end,
    __base = _base_0,
    __name = "CData"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  CData = _class_0
end
do
  local _base_0 = {
    __tostring = function(self)
      return render_tag(self.name, self.inner, self.attributes)
    end,
    __call = function(self, arg)
      local t = type(arg)
      if not is_list(arg) then
        arg = {
          arg
        }
      end
      local attributes = { }
      local inner = { }
      if is_list(arg) then
        local len = #arg
        for k, v in pairs(arg) do
          if type(k) == "number" then
            table.insert(inner, v)
          else
            attributes[k] = v
          end
        end
      end
      return Tag(self.name, inner, attributes)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, name, inner, attributes)
      self.name, self.inner, self.attributes = name, inner, attributes
      self.type = "tag"
    end,
    __base = _base_0,
    __name = "Tag"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Tag = _class_0
end
tag = nil
builders = defaultbl({
  text = function()
    return function(str)
      return Text(str)
    end
  end,
  cdata = function()
    return function(str)
      return CData(str)
    end
  end,
  tag = function()
    return tag
  end
}, function()
  return Tag
end)
builders.raw = builders.text
tag = setmetatable({ }, {
  __index = function(self, name)
    return builders[name](name)
  end
})
build = function(fn, delim)
  if delim == nil then
    delim = "\n"
  end
  local source_env = getfenv(fn)
  local result = run_with_scope(fn, setmetatable({ }, {
    __index = function(self, name)
      if name == "tag" then
        return tag
      end
      if source_env[name] ~= nil then
        return source_env[name]
      end
      return builders[name](name)
    end
  }))
  if is_list(result) then
    result = render_list(result, delim)
  end
  return tostring(result)
end
return {
  encode = encode,
  decode = decode,
  strip_tags = strip_tags,
  build = build,
  builders = builders,
  escape = escape,
  unescape = unescape,
  tag = tag
}
