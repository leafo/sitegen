
Site = require "sitegen.site"
import SiteFile from require "sitegen.site_file"
import actions from require "sitegen.cmd.actions"

TEST_FILES = "spec/test_files"

MODULE_NAME = "spec_test_site"

describe "actions", ->
  describe "render", ->
    local site, old_stdout, captured_output

    before_each ->
      -- capture stdout
      captured_output = {}
      old_stdout = io.stdout
      io.stdout = {
        write: (self, ...) ->
          for i = 1, select("#", ...)
            table.insert captured_output, select(i, ...)
      }

    after_each ->
      io.stdout = old_stdout
      package.loaded[MODULE_NAME] = nil

    get_output = ->
      table.concat captured_output

    inject_site = (setup==>) ->
      package.preload[MODULE_NAME] = =>
        sitegen = require "sitegen"
        sitegen.create setup

    it "renders a markdown file without template", ->
      inject_site!

      actions.render {
        site_module_name: "spec_test_site"
        file: "#{TEST_FILES}/simple.md"
        no_template: true
      }

      output = get_output!
      assert.truthy output\match "<em>world</em>"

    it "renders a markdown file with template defined in site #ddd", ->
      inject_site =>
        config {
          template_dir: "#{TEST_FILES}/templates/"
          default_template: "simple"
        }

      actions.render {
        site_module_name: "spec_test_site"
        file: "#{TEST_FILES}/simple.md"
      }

      output = get_output!
      assert.truthy output\match "TEMPLATE TOP"
      assert.truthy output\match "TEMPLATE BOTTOM"
      assert.truthy output\match "<em>world</em>"

    it "renders html file", ->
      inject_site!

      actions.render {
        site_module_name: "spec_test_site"
        file: "#{TEST_FILES}/simple.html"
        no_template: true
      }

      output = get_output!
      assert.same "<div>static content</div>\n", output

    it "renders moon file", ->
      inject_site!

      actions.render {
        site_module_name: "spec_test_site"
        file: "#{TEST_FILES}/dynamic.moon"
        no_template: true
      }

      output = get_output!
      assert.same "dynamic: 3", output

    it "can access site variables in render", ->
      inject_site =>
        @title = "My Cool Site"

      actions.render {
        site_module_name: "spec_test_site"
        file: "#{TEST_FILES}/with_var.html"
        no_template: true
      }

      output = get_output!
      assert.same "title: My Cool Site\n", output

