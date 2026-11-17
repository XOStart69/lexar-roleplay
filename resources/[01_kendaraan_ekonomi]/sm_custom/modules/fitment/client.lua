local config = require('config.client').fitment

local SHARE_DELAY <const> = 150

---@class FitmentClient
local fitment = {}

---@type table<string, FitmentValues>
local stored = {}
---@type table<string, true>?
local fresh = {}
---@type table<number, FitmentValues>
local held = {}
---@type table<integer, { values: FitmentValues, shop: string }>
local previews = {}
---@type { entity: number, values: FitmentValues }[]
local nearby = {}
local sharing = false

---@param values any
---@return FitmentValues?
local function valid(values)
    if type(values) == 'table' and type(values.offset) == 'table' and type(values.rotation) == 'table' then
        return values
    end
end

---@param vehicle number
---@return FitmentValues?
local function paid(vehicle)
    return stored[modules.wheels.key(vehicle) or '']
end

---@param vehicle number
---@return FitmentValues?
local function previewed(vehicle)
    if not next(previews) or not NetworkGetEntityIsNetworked(vehicle) then return end

    local entry = previews[NetworkGetNetworkIdFromEntity(vehicle)]

    return entry and entry.values
end

---@param vehicle number
---@return FitmentValues?
local function valuesOf(vehicle)
    return held[vehicle] or previewed(vehicle) or paid(vehicle)
end

---@param vehicle number
local function reapply(vehicle)
    local values = valuesOf(vehicle) or modules.wheels.probe(vehicle)

    if values and DoesEntityExist(vehicle) then
        modules.wheels.apply(vehicle, values)
    end
end

---@param id integer
local function reset(id)
    if not NetworkDoesEntityExistWithNetworkId(id) then return end

    local vehicle = NetToVeh(id)

    if vehicle ~= 0 and not held[vehicle] then
        reapply(vehicle)
    end
end

local function scan()
    local origin = GetEntityCoords(cache.ped)
    local list = {}

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if #(GetEntityCoords(vehicle) - origin) < config.distance then
            local values = valuesOf(vehicle)

            if values then
                modules.wheels.apply(vehicle, values)
                list[#list + 1] = { entity = vehicle, values = values }
            end
        end
    end

    nearby = list
end

if config.enable then
    CreateThread(function()
        while true do
            scan()
            Wait(config.scan)
        end
    end)

    CreateThread(function()
        while true do
            for _, entry in ipairs(nearby) do
                if DoesEntityExist(entry.entity) then
                    modules.wheels.hold(entry.entity, entry.values)
                end
            end

            Wait(#nearby > 0 and 0 or 500)
        end
    end)
end

---@param vehicle number
---@return FitmentValues?
function fitment.get(vehicle)
    return paid(vehicle)
end

---@param vehicle number
---@param values FitmentValues
function fitment.hold(vehicle, values)
    held[vehicle] = values
    modules.wheels.apply(vehicle, values)
    scan()
end

---@param vehicle number
function fitment.share(vehicle)
    if sharing then return end

    sharing = true

    SetTimeout(SHARE_DELAY, function()
        sharing = false

        local values = held[vehicle]

        if values then
            modules.net.emitLatentServer('sm_custom:server:fitmentPreview', values)
        end
    end)
end

---@param vehicle number
---@param restore FitmentValues
function fitment.release(vehicle, restore)
    held[vehicle] = nil

    if DoesEntityExist(vehicle) then
        modules.wheels.apply(vehicle, restore)
    end

    scan()
end

---@param vehicle number
function fitment.refresh(vehicle)
    local values = valuesOf(vehicle)

    if values then
        modules.wheels.apply(vehicle, values)
    end
end

RegisterNetEvent('sm_custom:client:fitments', function(saved, unowned)
    if source == '' then return end

    local skip = fresh or {}

    fresh = nil

    for _, list in ipairs({ saved, unowned }) do
        if type(list) == 'table' then
            for key, values in pairs(list) do
                if type(key) == 'string' and not skip[key] then
                    stored[key] = valid(values)
                end
            end
        end
    end

    scan()
end)

RegisterNetEvent('sm_custom:client:fitment', function(key, values)
    if source == '' or type(key) ~= 'string' then return end

    if fresh then fresh[key] = true end

    stored[key] = valid(values)

    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if not held[vehicle] and modules.wheels.key(vehicle) == key then
            reapply(vehicle)
        end
    end

    scan()
end)

RegisterNetEvent('sm_custom:client:fitmentPreview', function(id, shop, values)
    if source == '' or math.type(id) ~= 'integer' or type(shop) ~= 'string' then return end

    local clean = valid(values)

    if clean and modules.areas.inside(shop) then
        previews[id] = { values = clean, shop = shop }
    else
        previews[id] = nil
        reset(id)
    end

    scan()
end)

modules.areas.watch(function(key, inside)
    if inside then return end

    local gone = {}

    for id, entry in pairs(previews) do
        if entry.shop == key then
            gone[#gone + 1] = id
            previews[id] = nil
        end
    end

    if #gone == 0 then return end

    CreateThread(function()
        for _, id in ipairs(gone) do
            reset(id)
        end

        scan()
    end)
end)

if config.enable then TriggerServerEvent('sm_custom:server:fitments') end

return fitment
