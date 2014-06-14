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
	"yaml"
}

build = {
	type = "builtin",
	modules = {
		["sitegen"] = "sitegen/init.lua",
		["sitegen.blog"] = "sitegen/blog.lua",
		["sitegen.cache"] = "sitegen/cache.lua",
		["sitegen.common"] = "sitegen/common.lua",
		["sitegen.default.templates"] = "sitegen/default/templates.lua",
		["sitegen.deploy"] = "sitegen/deploy.lua",
		["sitegen.extra"] = "sitegen/extra.lua",
		["sitegen.feed"] = "sitegen/feed.lua",
		["sitegen.formatters.default"] = "sitegen/formatters/default.lua",
		["sitegen.header"] = "sitegen/header.lua",
		["sitegen.html"] = "sitegen/html.lua",
		["sitegen.indexer"] = "sitegen/indexer.lua",
		["sitegen.plugin"] = "sitegen/plugin.lua",
		["sitegen.plugins.analytics"] = "sitegen/plugins/analytics.lua",
		["sitegen.plugins.coffee_script"] = "sitegen/plugins/coffee_script.lua",
		["sitegen.plugins.dump"] = "sitegen/plugins/dump.lua",
		["sitegen.plugins.pygments"] = "sitegen/plugins/pygments.lua",
		["sitegen.renderer"] = "sitegen/renderer.lua",
		["sitegen.renderers.html"] = "sitegen/renderers/html.lua",
		["sitegen.renderers.markdown"] = "sitegen/renderers/markdown.lua",
		["sitegen.renderers.moon"] = "sitegen/renderers/moon.lua",
		["sitegen.tools"] = "sitegen/tools.lua",
		["sitegen.watch"] = "sitegen/watch.lua",
	},
	install = {
		bin = { "bin/sitegen" },
	},
}

