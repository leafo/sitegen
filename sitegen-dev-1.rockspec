package = "sitegen"
version = "dev-1"

source = {
	url = "git://github.com/leafo/sitegen.git"
}

description = {
	summary = "A tool for assembling static webpages with markdown",
	homepage = "http://leafo.net/sitegen/",
	maintainer = "Leaf Corcoran <leafot@gmail.com>",
	license = "MIT"
}

dependencies = {
	"lua >= 5.1",
	"cosmo",
	"luasocket",
	"lua-discount",
	"luafilesystem >= 1.5",
	"lua-cjson",
	"date",
	"yaml", -- remove me
	"ansicolors",
}

build = {
	type = "builtin",
	modules = {
		["sitegen"] = "sitegen/init.lua",
		["sitegen.cache"] = "sitegen/cache.lua",
		["sitegen.cmd.actions"] = "sitegen/cmd/actions.lua",
		["sitegen.cmd.util"] = "sitegen/cmd/util.lua",
		["sitegen.common"] = "sitegen/common.lua",
		["sitegen.default.templates"] = "sitegen/default/templates.lua",
		["sitegen.formatters.default"] = "sitegen/formatters/default.lua",
		["sitegen.header"] = "sitegen/header.lua",
		["sitegen.html"] = "sitegen/html.lua",
		["sitegen.output"] = "sitegen/output.lua",
		["sitegen.page"] = "sitegen/page.lua",
		["sitegen.path"] = "sitegen/path.lua",
		["sitegen.plugin"] = "sitegen/plugin.lua",
		["sitegen.plugins.analytics"] = "sitegen/plugins/analytics.lua",
		["sitegen.plugins.blog"] = "sitegen/plugins/blog.lua",
		["sitegen.plugins.coffee_script"] = "sitegen/plugins/coffee_script.lua",
		["sitegen.plugins.deploy"] = "sitegen/plugins/deploy.lua",
		["sitegen.plugins.dump"] = "sitegen/plugins/dump.lua",
		["sitegen.plugins.feed"] = "sitegen/plugins/feed.lua",
		["sitegen.plugins.indexer"] = "sitegen/plugins/indexer.lua",
		["sitegen.plugins.pygments"] = "sitegen/plugins/pygments.lua",
		["sitegen.query"] = "sitegen/query.lua",
		["sitegen.renderer"] = "sitegen/renderer.lua",
		["sitegen.renderers.html"] = "sitegen/renderers/html.lua",
		["sitegen.renderers.lapis"] = "sitegen/renderers/lapis.lua",
		["sitegen.renderers.markdown"] = "sitegen/renderers/markdown.lua",
		["sitegen.renderers.moon"] = "sitegen/renderers/moon.lua",
		["sitegen.site"] = "sitegen/site.lua",
		["sitegen.site_file"] = "sitegen/site_file.lua",
		["sitegen.site_scope"] = "sitegen/site_scope.lua",
		["sitegen.templates"] = "sitegen/templates.lua",
		["sitegen.tools"] = "sitegen/tools.lua",
		["sitegen.watch"] = "sitegen/watch.lua",
	},
	install = {
		bin = { "bin/sitegen" },
	},
}

