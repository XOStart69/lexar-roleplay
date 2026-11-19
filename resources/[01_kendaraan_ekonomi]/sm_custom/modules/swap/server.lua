---@class SwapServer
local swap = {}

local QBCore = exports['qb-core']:GetCoreObject()
local data = lib.load('data.menu.engines')

local RANGE <const> = 30.0

---@param value string?
---@return string
local function trim(value)
    return ((value or ''):gsub('^%s*(.-)%s*$', '%1'))
end

---@param model string
---@return string[]?
local function allowed(model)
    local list = data.models[model]
    if list then return list end

    local class = GetVehicleClassFromName(joaat(model))

    if class and data.classes[class] then return data.classes[class] end
end

---@param citizenid string
---@return table<string, string>
local function savedOf(citizenid)
    local rows = MySQL.query.await(
        'SELECT v.plate AS plate, s.sound AS sound FROM player_vehicles v INNER JOIN sm_custom_swaps s ON s.plate = v.plate WHERE v.citizenid = ?',
        { citizenid }
    ) or {}

    local map = {}

    for i = 1, #rows do
        if rows[i].sound then map[trim(rows[i].plate)] = rows[i].sound end
    end

    return map
end

---@param citizenid string
---@return table<string, string>
local function unownedOf(citizenid)
    local rows = MySQL.query.await('SELECT plate, vehicle FROM player_vehicles WHERE citizenid = ?', { citizenid }) or {}
    local map = {}

    for i = 1, #rows do
        local list = allowed(rows[i].vehicle)

        if list and list[1] then map[trim(rows[i].plate)] = list[1] end
    end

    return map
end

---@param src number
local function push(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid

    modules.net.emitLatentClient('sm_custom:client:swaps', src, savedOf(citizenid), unownedOf(citizenid))
end

---@param plate string
---@param sound string?
function swap.set(plate, sound)
    plate = trim(plate)
    if plate == '' then return end

    if sound then
        MySQL.update.await(
            'INSERT INTO sm_custom_swaps (plate, sound) VALUES (?, ?) ON DUPLICATE KEY UPDATE sound = VALUES(sound)',
            { plate, sound }
        )
    else
        MySQL.update.await('DELETE FROM sm_custom_swaps WHERE plate = ?', { plate })
    end
end

---@param plate string
---@return string?
function swap.get(plate)
    return MySQL.scalar.await('SELECT sound FROM sm_custom_swaps WHERE plate = ?', { trim(plate) })
end

RegisterNetEvent('sm_custom:server:swaps', function()
    push(source)
end)

RegisterNetEvent('sm_custom:server:swap', function(plate, sound)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    plate = trim(plate)
    if plate == '' then return end

    local row = MySQL.single.await(
        'SELECT vehicle FROM player_vehicles WHERE citizenid = ? AND plate = ?',
        { player.PlayerData.citizenid, plate }
    )

    if not row then return end

    if sound then
        local list = allowed(row.vehicle)

        if list then
            local found = false

            for i = 1, #list do
                if list[i] == sound then found = true break end
            end

            if not found then return end
        end
    end

    swap.set(plate, sound)

    push(src)
end)

RegisterNetEvent('sm_custom:server:swapPreview', function(sound)
    local src = source
    local zone = modules.booth.of(src)
    if not zone then return end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return end

    local netId = VehToNet(vehicle)
    if netId == 0 then return end

    local targets = {}

    for _, target in ipairs(lib.getNearbyPlayers(GetEntityCoords(vehicle), RANGE)) do
        targets[#targets + 1] = target
    end

    modules.net.emitLatentClients('sm_custom:client:swapPreview', targets, netId, zone.key, sound)
end)

return swap