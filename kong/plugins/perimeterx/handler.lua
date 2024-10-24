local pxconfig = require("px.pxconfig")
local pxtimer = require("px.utils.pxtimer")
local pxconstants = require("px.utils.pxconstants")
local px = require("px.pxnginx")
local MODULE_VERSION = "3.1.2"
local MODULE_VERSION_FULL = "Kong Plugin v" .. MODULE_VERSION
local ngx_now = ngx.now

local PXHandler = {
    VERSION = MODULE_VERSION,
    PRIORITY = 2500,
}

-- Example: additional_activity_handler() function
--function additional_activity_handler(event_type, ctx, details)
--	local cjson = require "cjson"
--	if (event_type == 'block') then
--		ngx.log(ngx.ERR, "PerimeterX: [" .. event_type .. "] blocked with score: " .. ctx.block_score .. ". Details: " .. cjson.encode(details))
--	else
--		ngx.log(ngx.ERR, "PerimeterX: [" .. event_type .. "]. Details: " .. cjson.encode(details))
--	end
--end

-- Example: enrich_custom_parameters() function
--function enrich_custom_parameters(px_custom_params)
    -- here we have an access to `ngx` object.
    -- e.g.: ngx.req.get_headers()["x-user-id"]
--    px_custom_params["custom_param1"] = "user_id"
--    return px_custom_params
--end


local function get_now()
    return ngx_now() * 1000
end

function PXHandler:init_worker()
     pxconstants.MODULE_VERSION = MODULE_VERSION_FULL
     pxtimer.application(pxconfig)
end

function PXHandler:access(config)
    local ngx_ctx = ngx.ctx
    ngx_ctx.KONG_HEADER_FILTER_STARTED_AT = get_now()
    config.additional_activity_handler = additional_activity_handler
    config.enrich_custom_parameters = enrich_custom_parameters
    px.application(config)
end

return PXHandler

