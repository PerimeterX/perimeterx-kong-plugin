local BasePlugin = require "kong.plugins.base_plugin"
local PXHandler = BasePlugin:extend()
local pxconfig = require("px.pxconfig")
local pxtimer = require("px.utils.pxtimer")
local pxconstants = require("px.utils.pxconstants")
local px = require("px.pxnginx")
local MODULE_VERSION = 'Kong Plugin v1.4.0'
local ngx_now = ngx.now

function PXHandler:new()
    PXHandler.super.new(self, "perimeterx-plugin")
end

local function get_now()
    return ngx_now() * 1000
end

function PXHandler:init_worker(config)
    PXHandler.super.init_worker(self)
    pxconstants.MODULE_VERSION = MODULE_VERSION
    pxtimer.application(pxconfig)
end

function PXHandler:access(config)
    local ngx_ctx = ngx.ctx
    ngx_ctx.KONG_HEADER_FILTER_STARTED_AT = get_now()
    PXHandler.super.access(self)
    config.additional_activity_handler = pxconfig.additional_activity_handler
    px.application(config)
end

return PXHandler

