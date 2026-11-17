local resource = GetCurrentResourceName()

if GetResourceMetadata(resource, 'name', 0) ~= 'sm_custom' then
    error(('@sm_custom/init.lua cannot be loaded by %s'):format(resource), 0)
end

---@class RhdModules
---@field areas AreasClient | AreasServer
---@field billing BillingClient | BillingServer
---@field booth BoothClient | BoothServer
---@field camera CameraClient
---@field cart CartShared
---@field catalog CatalogClient
---@field discount DiscountServer
---@field fitment FitmentClient | FitmentServer
---@field install InstallClient | InstallServer
---@field interact InteractClient
---@field jobs JobsServer
---@field logs LogsServer
---@field net NetShared
---@field nitrous NitrousClient | NitrousServer
---@field placer PlacerClient
---@field pricing PricingServer
---@field receipt ReceiptClient | ReceiptServer
---@field shops ShopsClient
---@field swap SwapClient | SwapServer
---@field wheels WheelsClient
---@field zones ZonesShared | ZonesServer

local context <const> = lib.context

---@param name string
---@param side string
---@return string?
local function locate(name, side)
    if not LoadResourceFile(resource, ('modules/%s/%s.lua'):format(name, side)) then return end

    return ('modules.%s.%s'):format(name, side)
end

---@param self table
---@param name string
---@return any
local function import(self, name)
    local shared, side = locate(name, 'shared'), locate(name, context)
    if not shared and not side then return end

    local module = shared and require(shared)

    if side then
        rawset(self, name, module)

        local extended = require(side)

        local mergeable = type(extended) == 'table' and type(module) == 'table' and extended ~= module

        if mergeable and not getmetatable(extended) then
            setmetatable(extended, { __index = module })
        end

        module = extended
    end

    rawset(self, name, module)

    return module
end

---@type RhdModules
---@diagnostic disable-next-line: lowercase-global
modules = setmetatable({}, {
    __index = function(self, name)
        return import(self, name) or error(locale('log.no_module', name, context), 2)
    end,
})

for i = 1, GetNumResourceMetadata(resource, 'rhd_module') do
    local name = GetResourceMetadata(resource, 'rhd_module', i - 1)

    if not rawget(modules, name) then import(modules, name) end
end
