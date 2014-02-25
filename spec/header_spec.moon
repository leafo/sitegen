
require "sitegen.common"


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

  it "should load extract header", ->
    import extract_header from require "sitegen.header"
    body, header = extract_header [[
      color: blue
      --
      Hello!
    ]]

    assert.same "Hello!", trim body
    assert.same { color: "blue" }, header

