---@class NitrousServer
local nitrous = {}

local QBCore = exports['qb-core']:GetCoreObject()

local RANGE <const> = 60.0

local function trim(value)
    return ((value or ''):gsub('^%s*(.-)%s*$', '%1'))
end

---@param netId number
---@return number?
local function vehicleOf(netId)
    if math.type(netId) ~= 'integer' then return end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    local vehicle = NetToVeh(netId)

    return vehicle ~= 0 and vehicle or nil
end

---@param citizenid string
---@return table<string, { level: number }>
local function tanksOf(citizenid)
    local rows = MySQL.query.await(
        'SELECT n.plate AS plate, n.level AS level FROM sm_custom_nitrous n INNER JOIN player_vehicles v ON v.plate = n.plate WHERE v.citizenid = ?',
        { citizenid }
    ) or {}

    local map = {}

    for i = 1, #rows do
        map[trim(rows[i].plate)] = { level = tonumber(rows[i].level) or 0 }
    end

    return map
end

---@param src number
local function push(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    modules.net.emitLatentClient('sm_custom:client:tanks', src, tanksOf(player.PlayerData.citizenid))
end

---@param plate string
---@param level number
function nitrous.set(plate, level)
    plate = trim(plate)
    if plate == '' then return end

    MySQL.update.await(
        'INSERT INTO sm_custom_nitrous (plate, level) VALUES (?, ?) ON DUPLICATE KEY UPDATE level = VALUES(level)',
        { plate, math.max(math.min(tonumber(level) or 0, 100), 0) }
    )
end

---@param plate string
---@param level number
function nitrous.ensure(plate, level)
    plate = trim(plate)
    if plate == '' then return end

    MySQL.update.await('INSERT IGNORE INTO sm_custom_nitrous (plate, level) VALUES (?, ?)', { plate, level })
end

---@param plate string
---@return number?
function nitrous.get(plate)
    return MySQL.scalar.await('SELECT level FROM sm_custom_nitrous WHERE plate = ?', { trim(plate) })
end

RegisterNetEvent('sm_custom:server:tanks', function()
    push(source)
end)

RegisterNetEvent('sm_custom:server:nitrous', function(plate, level)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    plate = trim(plate)
    if plate == '' then return end

    local owned = MySQL.scalar.await(
        'SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND plate = ?',
        { player.PlayerData.citizenid, plate }
    )

    if not owned or owned == 0 then return end

    nitrous.set(plate, level)

    modules.net.emitLatentClient('sm_custom:client:tank', src, plate, { level = tonumber(level) or 0 })
end)

RegisterNetEvent('sm_custom:server:nitrousFx', function(netId, kind, state, level)
    if kind ~= 'flame' and kind ~= 'purge' then return end

    local vehicle = vehicleOf(netId)
    local plate = vehicle and trim(GetVehicleNumberPlateText(vehicle)) or nil
    local targets = {}

    if vehicle then
        for _, target in ipairs(lib.getNearbyPlayers(GetEntityCoords(vehicle), RANGE)) do
            targets[#targets + 1] = target
        end
    else
        for _, id in ipairs(GetPlayers()) do
            targets[#targets + 1] = tonumber(id)
        end
    end

    modules.net.emitLatentClients('sm_custom:client:nitrousFx', targets, netId, kind, state == true, plate, level)
end)

RegisterNetEvent('sm_custom:server:nitrousPreview', function(kind, colour)
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

    modules.net.emitLatentClients('sm_custom:client:nitrousPreview', targets, netId, zone.key, kind, colour)
end)

return nitrous
