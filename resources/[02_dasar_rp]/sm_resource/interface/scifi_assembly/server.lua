--[[
    scifi_assembly :: server
    Perakitan kendaraan sci-fi: aktif/nonaktif oleh job kontrol, pilih blueprint,
    konsumsi material, lalu spawn kendaraan dengan plat SCIFI.
]]

local Config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local BLUEPRINTS = Config.Blueprints or {}
local CONTROL = Config.ControlJob or {}

local state = {
    enabled = false,
    stage = false,
    model = false,
    owner = nil
}

local lastAt = 0

local function publish()
    GlobalState.scifiAssembly = state
end

local function notify(src, message, nType)
    lib.notify(src, { title = 'Perakitan Sci-Fi', description = message, type = nType or 'inform' })
end

local function blueprint(model)
    for i = 1, #BLUEPRINTS do
        if BLUEPRINTS[i].model == model then return BLUEPRINTS[i] end
    end
end

local function isControl(src)
    local player = QBCore.Functions.GetPlayer(src)
    local job = player and player.PlayerData.job
    if not job or job.name ~= CONTROL.name then return false end

    local grade = tonumber(type(job.grade) == 'table' and job.grade.level or job.grade) or 0

    return grade >= (CONTROL.minGrade or 0)
end

local function hasMaterials(src, blueprint_)
    local counts = exports.ox_inventory:Search(src, 'count', (function()
        local list = {}
        for i = 1, #blueprint_.materials do list[#list + 1] = blueprint_.materials[i].item end
        return list
    end)()) or {}

    for i = 1, #blueprint_.materials do
        local need = blueprint_.materials[i]
        if (counts[need.item] or 0) < need.count then return false end
    end

    return true
end

local function clearStage()
    state.stage = false
    state.model = false
    state.owner = nil
    publish()
end

local function randomPlate()
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local out = { Config.PlatePrefix or 'SCIFI' }

    for _ = 1, 4 do
        local i = math.random(1, #charset)
        out[#out + 1] = charset:sub(i, i)
    end

    return table.concat(out)
end

lib.callback.register('scifi_assembly:select', function(src, model)
    if not state.enabled then return false, 'disabled' end
    if state.stage and state.stage ~= 'preview' then return false, 'busy' end

    local now = GetGameTimer()
    if now - lastAt < 400 then return false, 'throttle' end
    lastAt = now

    if type(model) ~= 'string' then return false, 'invalid' end

    local blueprint_ = blueprint(model)
    if not blueprint_ then return false, 'invalid' end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - Config.Station) > (Config.StationUseDistance or 6.0) then
        return false, 'far'
    end

    state.stage = 'preview'
    state.model = model
    state.owner = src
    publish()

    return true
end)

lib.callback.register('scifi_assembly:build', function(src, model)
    if not state.enabled then return false, 'disabled' end
    if state.stage ~= 'preview' then return false, 'nobuild' end
    if state.owner ~= src then return false, 'busy' end

    local blueprint_ = blueprint(model or state.model)
    if not blueprint_ then return false, 'invalid' end

    if not hasMaterials(src, blueprint_) then return false, 'materials' end

    for i = 1, #blueprint_.materials do
        local need = blueprint_.materials[i]
        if not exports.ox_inventory:RemoveItem(src, need.item, need.count) then
            for j = 1, i - 1 do
                exports.ox_inventory:AddItem(src, blueprint_.materials[j].item, blueprint_.materials[j].count)
            end
            return false, 'materials'
        end
    end

    state.stage = 'building'
    state.model = blueprint_.model
    state.owner = src
    publish()

    return true, Config.BuildDuration or 30000, blueprint_.name
end)

lib.callback.register('scifi_assembly:finish', function(src, restZ)
    if state.stage ~= 'building' then return false, 'nobuild' end
    if state.owner ~= src then return false, 'busy' end

    local blueprint_ = blueprint(state.model)
    if not blueprint_ then
        clearStage()
        return false, 'invalid'
    end

    local point = blueprint_.spawn or Config.SpawnPoint
    local hash = joaat(blueprint_.model)

    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        clearStage()
        return false, 'spawnfail'
    end

    local vehicle = CreateVehicle(hash, point.x, point.y, point.z, point.w or 0.0, true, true)

    if not vehicle or vehicle == 0 then
        for i = 1, #blueprint_.materials do
            local need = blueprint_.materials[i]
            exports.ox_inventory:AddItem(src, need.item, need.count)
        end

        clearStage()
        return false, 'spawnfail'
    end

    local plate = randomPlate()

    SetVehicleNumberPlateText(vehicle, plate)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetEntityAsMissionEntity(vehicle, true, true)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    TriggerClientEvent('scifi_assembly:settle', -1, netId)
    TriggerClientEvent('scifi_assembly:completed', -1, blueprint_.model)

    local player = QBCore.Functions.GetPlayer(src)
    if player then
        TriggerEvent('sm_vehiclekeys:server:setVehicleOwner', src, plate)

        if player.Functions.AddVehicle then
            player.Functions.AddVehicle(blueprint_.model, point, plate)
        end
    end

    clearStage()

    return true, blueprint_.name
end)

RegisterNetEvent('scifi_assembly:release', function()
    local src = source
    if state.stage == 'preview' and state.owner == src then clearStage() end
end)

RegisterNetEvent('scifi_assembly:cancelBuild', function()
    local src = source
    if state.stage ~= 'building' or state.owner ~= src then return end

    local blueprint_ = blueprint(state.model)

    if blueprint_ then
        for i = 1, #blueprint_.materials do
            local need = blueprint_.materials[i]
            exports.ox_inventory:AddItem(src, need.item, need.count)
        end
    end

    clearStage()
    notify(src, 'Perakitan dibatalkan, material dikembalikan.', 'error')
end)

lib.addCommand(Config.Command or 'rakitscifi', {
    help = 'Aktifkan/nonaktifkan stasiun perakitan sci-fi',
    restricted = 'admin'
}, function(src)
    if not isControl(src) and not IsPlayerAceAllowed(src, 'admin') then
        return notify(src, 'Job kamu tidak mengontrol stasiun ini.', 'error')
    end

    state.enabled = not state.enabled
    if not state.enabled then clearStage() else publish() end

    notify(src, state.enabled and 'Stasiun perakitan diaktifkan.' or 'Stasiun perakitan dinonaktifkan.',
        state.enabled and 'success' or 'error')
end)

CreateThread(function()
    publish()

    while true do
        Wait(5000)

        if state.stage == 'preview' and state.owner then
            if not GetPlayerName(state.owner) then clearStage() end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if state.owner == src then clearStage() end
end)