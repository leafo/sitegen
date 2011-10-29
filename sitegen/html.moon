
module "sitegen.html", package.seeall

export encode, decode, strip_tags

import concat from table

punct = "[%^$()%.%[%]*+%-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

html_encode_entities = {
  ['&']: '&amp;'
  ['<']: '&lt;'
  ['>']: '&gt;'
  ['"']: '&quot;'
  ["'"]: '&q#039;'
}

html_decode_entities = {}
for key,value in pairs html_encode_entities
  html_decode_entities[value] = key

html_encode_pattern = "[" .. concat([escape_patt char for char in pairs html_encode_entities]) .. "]"

encode = (text) ->
  (text\gsub html_encode_pattern, html_encode_entities)

decode = (text) ->
  (text\gsub "(&[^&]-;)", (enc) ->
    decoded = html_decode_entities[enc]
    decoded if decoded else enc)

strip_tags = (html) ->
  html\gsub "<[^>]+>", ""
