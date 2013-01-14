
module "sitegen.html", package.seeall
require "moon"

export encode, decode, strip_tags, build, builders
export escape, unescape
export tag

import concat from table
import run_with_scope, defaultbl from moon

punct = "[%^$()%.%[%]*+%-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

html_encode_entities = {
  ['&']: '&amp;'
  ['<']: '&lt;'
  ['>']: '&gt;'
  ['"']: '&quot;'
  ["'"]: '&#039;'
}

html_decode_entities = {}
for key,value in pairs html_encode_entities
  html_decode_entities[value] = key

html_encode_pattern = "[" .. concat([escape_patt char for char in pairs html_encode_entities]) .. "]"

encode = (text) ->
  (text\gsub html_encode_pattern, html_encode_entities)

escape = encode

decode = (text) ->
  (text\gsub "(&[^&]-;)", (enc) ->
    decoded = html_decode_entities[enc]
    decoded if decoded else enc)

unescape = decode

strip_tags = (html) ->
  html\gsub "<[^>]+>", ""

is_list = (t) ->
  type(t) == "table" and t.type != "tag"

render_list = (list, delim) ->
  escaped = for item in *list
    if type(item) == "string"
      encode item
    elseif is_list item
      render_list item, delim
    elseif type(item) == "function"
      build item
    elseif item != nil
      tostring item
    else
      error "unknown item"

  table.concat escaped, delim

render_tag = (name, inner="", attributes={}) ->
  formatted_attributes = {}
  for attr_name, attr_value in pairs attributes
    if not attr_name\match"^__"
      table.insert formatted_attributes,
        ('%s="%s"')\format attr_name, encode attr_value

  if is_list inner
    inner = render_list inner, "\n"
  else
    inner = tostring inner

  open = table.concat {
    "<", name

    if #formatted_attributes > 0
      " " .. table.concat formatted_attributes, " "
    else ""

    ">"
  }

  close = table.concat { "</", name, ">"}
  close = "\n" .. close if attributes.__breakclose
  open .. inner .. close

class Text
  new: (@text) => @type = "tag"
  __tostring: => @text

class CData
  new: (@text) => @type = "tag"
  __tostring: =>
    "<![CDATA[" .. @text .. "]]>"

class Tag
  new: (@name, @inner, @attributes) => @type = "tag"
  __tostring: => render_tag @name, @inner, @attributes
  __call: (arg) =>
    t = type arg
    if not is_list arg then arg = {arg}
    attributes = {}
    inner = {}

    if is_list arg
      len = #arg
      for k,v in pairs arg
        if type(k) == "number"
          table.insert inner, v
        else
          attributes[k] = v

    Tag @name, inner, attributes

tag = nil
builders = defaultbl {
  text: -> (str) -> Text str
  cdata: -> (str) -> CData str
  tag: -> tag
}, -> Tag

builders.raw = builders.text

tag = setmetatable {}, {
  __index: (name) => builders[name] name
}

build = (fn, delim="\n") ->
  source_env = getfenv fn
  result = run_with_scope fn, setmetatable {}, {
    __index: (name) =>
      return tag if name == "tag"
      return source_env[name] if source_env[name] != nil
      builders[name] name
  }

  result = render_list result, delim if is_list result
  tostring result


nil
