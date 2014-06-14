class Renderer
  new: (@pattern) =>
  render: -> error "must provide render method"
  can_render: (fname) =>
    nil != fname\match @pattern

  parse_header: (text) =>
    import extract_header from require "sitegen.header"
    extract_header text

  render: (text, site) =>
    @parse_header text


{
  :Renderer
}
