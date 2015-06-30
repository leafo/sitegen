
-- A renderer is reponsible for loading a template source file, extracting any
-- metadata, and providing a function to render the template to string

class Renderer
  new: (@site) =>

  extract_header: (text) =>
    import extract_header from require "sitegen.header"
    extract_header text

  can_load: (fname) =>
    return nil unless @source_ext
    import convert_pattern from require "sitegen.common"
    pattern = convert_pattern "*.#{@source_ext}$"
    not not fname\match pattern

  -- if the source can be loaded, returns a function that takes render context
  -- to render, and the parsed header
  load: (source) =>
    content, meta = @extract_header source
    (-> content), meta

{
  :Renderer
}
