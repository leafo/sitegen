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
	-- "luayaml"
}

build = {
	type = "builtin",
	modules = {
		["sitegen"] = "sitegen.lua",
		["sitegen.html"] = "sitegen/html.lua",
		["sitegen.indexer"] = "sitegen/indexer.lua",
		["sitegen.extra"] = "sitegen/extra.lua",
		["sitegen.common"] = "sitegen/common.lua",
		-- TODO rename one of these
		["sitegen.default.templates"] = "sitegen/default/templates.lua",
		["sitegen.formatters.default"] = "sitegen/formatters/default.lua",

		["sitegen.deploy"] = "sitegen/deploy.lua",
		["sitegen.watch"] = "sitegen/watch.lua",
		["sitegen.blog"] = "sitegen/blog.lua",
		["sitegen.feed"] = "sitegen/feed.lua",
		["sitegen.cache"] = "sitegen/cache.lua",
	},
	install = {
		bin = { "bin/sitegen" },
	},
}

