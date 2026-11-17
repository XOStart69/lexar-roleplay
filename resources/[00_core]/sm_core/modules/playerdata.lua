---@meta

if lib.context == 'server' then return end

local sm_core = exports.sm_core

local data = sm_core:GetPlayerData() or {}
local proxies = setmetatable({}, { __mode = 'k' })

local readonly

local function wrap(value)
    return type(value) == 'table' and readonly(value) or value
end

---@generic T : table
---@param source T
---@return T
function readonly(source)
    local proxy = proxies[source]
    if proxy then return proxy end

    proxy = setmetatable({}, {
        __index = function(_, key) return wrap(source[key]) end,
        __newindex = function(_, key)
            error(('cannot set values on a read-only table (%s)'):format(tostring(key)), 2)
        end,
        __len = function() return #source end,
        __pairs = function()
            return function(_, key)
                local k, v = next(source, key)
                return k, wrap(v)
            end, source, nil
        end,
        __metatable = 'readonly',
    })

    proxies[source] = proxy

    return proxy
end

QBPlayerData = readonly(data)

local function setData(payload)
    table.wipe(data)

    for key, value in pairs(payload) do
        data[key] = value
    end
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    setData(sm_core:GetPlayerData() or {})
end)

sm_core:registerHook('core:updatePlayerDataBykey', function(key, value, subValue)
    if key == 'all' then
        setData(value or {})
        return
    end

    if subValue == nil then
        data[key] = value
        return
    end

    local field = data[key]

    if type(field) ~= 'table' then
        field = {}
        data[key] = field
    end

    field[value] = subValue
end)