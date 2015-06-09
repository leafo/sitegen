
import
  trim_leading_white
  trim
  from require "sitegen.common"

describe "sitegen.header", ->
  it "should trim front", ->
    indented = [[
  hello world
    another test
  test
]]

    assert.same [[
hello world
  another test
test]], trim_leading_white indented

  it "extracts yaml header", ->
    import extract_header from require "sitegen.header"
    body, header = extract_header [[
      color: blue
      --
      Hello!
    ]]

    assert.same "Hello!", trim body
    assert.same { color: "blue" }, header

  it "extracts empty moonscript header", ->
    import extract_header from require "sitegen.header"
    body, header = extract_header [[{}hello world]]
    assert.same "hello world", body
    assert.same {}, header

  it "extracts complex moonscript header", ->
    import extract_header from require "sitegen.header"
    body, header = extract_header [[
      {color: "blue", height: 1, things: {1,2,3,4}}
      hello world test test
      yeah
    ]]

    assert.same {
      color: "blue"
      height: 1
      things: {1,2,3,4}
    }, header

    assert.same [[hello world test test
      yeah]], trim body

