local function isStarted(resource, alias)
    return GetResourceState(resource) == 'started' and (alias or resource)
end

local qb = isStarted('qb-core', 'qb')
local esx = isStarted('es_extended', 'esx')
local qbox = isStarted('qbx_core', 'qbox')

local framework = qbox or qb or esx

local path = ('framework.%s.%s'):format(framework, lib.context)

require(path)