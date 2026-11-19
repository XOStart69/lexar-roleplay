---@class EditorServer
local editor = {}

local QBCore = exports['qb-core']:GetCoreObject()

local zones = modules.zones
local pricing = modules.pricing

---@type table<number, string>
local session = {}

---@param src number
---@return boolean
local function isAdmin(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end

    return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
end

---@param src number
---@return table?
local function groupOf(src)
    local data = pricing.data()
    local code = session[src] or 'tier_a'
    local group = data.groups and data.groups[code]

    if not group then
        for key in pairs(data.groups or {}) do
            session[src] = key

            return data.groups[key]
        end

        return nil
    end

    return group
end

---@param src number
---@return table
local function payload(src)
    local shops = {}

    for key, shop in pairs(zones.data) do
        local copy = table.clone(shop)
        copy.key = key

        shops[#shops + 1] = copy
    end

    local group = groupOf(src) or {}
    local codes = {}

    for code in pairs(pricing.data().groups or {}) do
        codes[#codes + 1] = code
    end

    table.sort(codes)

    return {
        shops = shops,
        prices = group.prices or {},
        vehicles = group.vehicles or {},
        grouping = group.grouping or {},
        group = session[src],
        codes = codes,
    }
end

---@param src number
---@param group? string
---@return boolean
function editor.open(src, group)
    if not isAdmin(src) then return false end

    if type(group) == 'string' and group ~= '' then
        if not (pricing.data().groups or {})[group] then return false end

        session[src] = group
    end

    modules.net.emitLatentClient('sm_custom:client:editor', src, payload(src))

    return true
end

---@param src number
local function saved(src)
    modules.net.emitLatentClient('sm_custom:client:editorSaved', src, { ok = true })
end

RegisterNetEvent('sm_custom:server:editorPrices', function(_, data)
    local src = source
    if not isAdmin(src) or type(data) ~= 'table' then return end

    local group = groupOf(src)
    if not group then return end

    if type(data.prices) == 'table' then group.prices = data.prices end
    if type(data.vehicles) == 'table' then group.vehicles = data.vehicles end
    if type(data.grouping) == 'table' then group.grouping = data.grouping end

    pricing.save()
    saved(src)
end)

RegisterNetEvent('sm_custom:server:editorSave', function(shop, previous)
    local src = source
    if not isAdmin(src) or type(shop) ~= 'table' then return end
    if type(shop.key) ~= 'string' or shop.key == '' then return end

    if type(previous) == 'string' and previous ~= shop.key then zones.data[previous] = nil end

    local key = shop.key
    local copy = table.clone(shop)
    copy.key = nil

    zones.data[key] = copy
    zones.load(zones.data)
    zones.save()

    saved(src)
end)

RegisterNetEvent('sm_custom:server:editorDelete', function(key)
    local src = source
    if not isAdmin(src) or type(key) ~= 'string' then return end

    zones.data[key] = nil
    zones.load(zones.data)
    zones.save()

    saved(src)
end)

AddEventHandler('playerDropped', function()
    session[source] = nil
end)

RegisterCommand('customeditor', function(src, args)
    if src == 0 then return end

    editor.open(src, args[1])
end, false)

return editor