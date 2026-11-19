---@class FitmentServer
local fitment = {}

local QBCore = exports['qb-core']:GetCoreObject()

local RANGE <const> = 30.0

local function trim(value)
    return ((value or ''):gsub('^%s*(.-)%s*$', '%1'))
end

---@param vehicle number
---@return FitmentValues
function fitment.probe(vehicle)
    local values = { height = GetVehicleSuspensionHeight(vehicle) }
    local rim = modules.wheels.rim(vehicle)

    if rim then
        values.rim = rim
        values.size = GetVehicleWheelSize(vehicle)
        values.width = GetVehicleWheelWidth(vehicle)
    end

    values.offset = {}
    values.rotation = {}

    for wheel = 0, modules.wheels.count(vehicle) - 1 do
        values.offset[tostring(wheel)] = GetVehicleWheelXOffset(vehicle, wheel)
        values.rotation[tostring(wheel)] = GetVehicleWheelYRotation(vehicle, wheel)
    end

    return values
end

---@param key string
---@param plate string
---@param values FitmentValues
function fitment.set(key, plate, values)
    if type(key) ~= 'string' then return end

    MySQL.update.await(
        'INSERT INTO sm_custom_fitments (`key`, plate, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)',
        { key, trim(plate), json.encode(values) }
    )
end

---@param citizenid string
---@return table<string, FitmentValues>
local function savedOf(citizenid)
    local rows = MySQL.query.await(
        'SELECT f.`key` AS k, f.data AS d FROM sm_custom_fitments f INNER JOIN player_vehicles v ON v.plate = f.plate WHERE v.citizenid = ?',
        { citizenid }
    ) or {}

    local map = {}

    for i = 1, #rows do
        local ok, decoded = pcall(json.decode, rows[i].d or '')

        if ok and type(decoded) == 'table' then map[rows[i].k] = decoded end
    end

    return map
end

---@param src number
local function push(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    modules.net.emitLatentClient('sm_custom:client:fitments', src, savedOf(player.PlayerData.citizenid), {})
end

---@param src number
---@return number?
local function vehicleOf(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then vehicle = GetVehiclePedIsUsing(ped) end

    return vehicle ~= 0 and vehicle or nil
end

RegisterNetEvent('sm_custom:server:fitments', function()
    push(source)
end)

RegisterNetEvent('sm_custom:server:fitment', function(values)
    if type(values) ~= 'table' then return end

    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local vehicle = vehicleOf(src)
    if not vehicle then return end

    local plate = trim(GetVehicleNumberPlateText(vehicle))
    local row = MySQL.scalar.await(
        'SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND plate = ?',
        { player.PlayerData.citizenid, plate }
    )

    if not row or row == 0 then return end

    fitment.set(modules.wheels.key(vehicle), plate, values)
    push(src)
end)

RegisterNetEvent('sm_custom:server:fitmentPreview', function(values)
    if type(values) ~= 'table' then return end

    local src = source
    local zone = modules.booth.of(src)
    if not zone then return end

    local vehicle = vehicleOf(src)
    if not vehicle then return end

    local netId = VehToNet(vehicle)
    if netId == 0 then return end

    local targets = {}

    for _, target in ipairs(lib.getNearbyPlayers(GetEntityCoords(vehicle), RANGE)) do
        targets[#targets + 1] = target
    end

    modules.net.emitLatentClients('sm_custom:client:fitmentPreview', targets, netId, zone.key, values)
end)

return fitment