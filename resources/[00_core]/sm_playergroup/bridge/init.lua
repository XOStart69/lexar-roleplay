---@param resource string
---@param alias string
---@return boolean|string
local function isStarted(resource, alias)
    return GetResourceState(resource) == 'started' and (alias or resource) or false
end

local qbx = isStarted('qbx_core', 'qbx')
local qb = isStarted('qb-core', 'qb')
local esx = isStarted('es_extended', 'esx')
local ox = isStarted('ox_core', 'ox')

local framework = qbx or qb or esx or ox or 'standalone'
local path = ('bridge.%s.%s'):format(framework, lib.context)

return require (path)