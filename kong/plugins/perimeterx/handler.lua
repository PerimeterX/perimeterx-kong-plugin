local BasePlugin = require "kong.plugins.base_plugin"
local PXHandler = BasePlugin:extend()
local pxconfig = require("px.pxconfig")
local pxtimer = require("px.utils.pxtimer")
local pxconstants = require("px.utils.pxconstants")
local px = require("px.pxnginx")
local MODULE_VERSION = 'Kong Plugin v1.0.0'

function PXHandler:new()
    PXHandler.super.new(self, "perimeterx-plugin")
end

function PXHandler:init_worker(config)
    PXHandler.super.init_worker(self)
    pxconstants.MODULE_VERSION = MODULE_VERSION
    pxtimer.application()
end

function PXHandler:access(config)
    PXHandler.super.access(self)
    for key,value in pairs(config) do
        pxconfig[key] = value
    end
    px.application()
end

return PXHandler