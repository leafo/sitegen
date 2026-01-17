
import SiteFile from require "sitegen.site_file"
Path = require "sitegen.path"
lfs = require "lfs"

describe "SiteFile", ->
  describe "with site_module_name", ->
    local sitefile

    before_each ->
      sitefile = SiteFile {
        site_module_name: "some.test.module"
        logger_opts: { silent: true }
      }

    it "should set rel_path to empty string", ->
      assert.same "", sitefile.rel_path

    it "should have io object initialized", ->
      assert.truthy sitefile.io

    it "should have site_module_name set", ->
      assert.same "some.test.module", sitefile.site_module_name

    it "should not have file_path set", ->
      assert.is_nil sitefile.file_path

    describe "io object", ->
      it "should generate relative paths via full_path", ->
        assert.same "hello.md", sitefile.io.full_path "hello.md"
        assert.same "www/posts/article.html", sitefile.io.full_path "www/posts/article.html"

    describe "relativeize", ->
      it "should convert absolute path to relative from current directory", ->
        cwd = lfs.currentdir!
        test_path = cwd .. "/sitegen/cmd/actions.moon"

        result = sitefile\relativeize test_path
        assert.same "sitegen/cmd/actions.moon", result

      it "should handle nested paths", ->
        cwd = lfs.currentdir!
        test_path = cwd .. "/sitegen/init.moon"

        result = sitefile\relativeize test_path
        assert.same "sitegen/init.moon", result

  describe "with rel_path", ->
    local sitefile

    before_each ->
      sitefile = SiteFile {
        rel_path: "sitegen/cmd"
        logger_opts: { silent: true }
      }

    it "should set rel_path correctly", ->
      assert.same "sitegen/cmd", sitefile.rel_path

    it "should have io object initialized", ->
      assert.truthy sitefile.io

    it "should set file_path", ->
      assert.same "sitegen/cmd/site.moon", sitefile.file_path

    describe "relativeize", ->
      it "should convert path relative to site directory", ->
        cwd = lfs.currentdir!
        test_path = cwd .. "/sitegen/cmd/actions.moon"

        result = sitefile\relativeize test_path
        assert.same "actions.moon", result

      it "should handle nested paths relative to site directory", ->
        cwd = lfs.currentdir!
        test_path = cwd .. "/sitegen/cmd/util.moon"

        result = sitefile\relativeize test_path
        assert.same "util.moon", result
