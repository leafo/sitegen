module("sitegen.extra", package.seeall)
local sitegen = require("sitegen")
local html = require("sitegen.html")
sitegen.register_plugin(DumpPlugin)
sitegen.register_plugin(AnalyticsPlugin)
sitegen.register_plugin(PygmentsPlugin)
sitegen.register_plugin(CoffeeScriptPlugin)
return nil
