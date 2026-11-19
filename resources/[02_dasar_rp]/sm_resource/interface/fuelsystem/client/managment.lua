if not interface.init() then return end

sm_fuel.management = {}

local config = localmodule 'config.station'
local mission_price = localmodule 'config.management'.mission?.fuel_price
local pedModule = require 'modules.pedHandle.client'

local function openFuelManagement(stationid)
    local mdata = lib.cblt.await('fuelsystem:getmdata', 1500, stationid)
    if not mdata then return end

    mdata.stationid = playerState.fuel_station_id
    mdata.mycitizenid = QBPlayerData.citizenid
    mdata.mission_price = mission_price

    interface.send({
        action = 'setManagement',
        data = mdata
    })
    interface.focus(true, true)
end

local function loadStation(station)
    local stationId = station.id
    local stationPed = station.ped
    local stationLabel = station.label

    sm_fuel.management[stationId] = {}

    if stationPed?.model and IsModelInCdimage(stationPed.model) then
        sm_fuel.management[stationId].ped = pedModule:new({
            coords = vec(stationPed.coords.x, stationPed.coords.y, stationPed.coords.z + 1.0, stationPed.coords.w),
            model = stationPed.model,
            renderDistance = 30,
            target = {
                {
                    label = 'Manage Station',
                    icon = 'fas fa-gas-pump',
                    distance = 1.5,
                    onSelect = function ()
                        openFuelManagement(stationId)
                    end
                }
            }
        })
        sm_fuel.management[stationId].label = stationLabel
    end

    if sm_fuel.blips[stationId] then
        sm_fuel.blips[stationId]:setLabel(stationLabel)
    end
end

local function setup(management)
    array.forEach(config.location, function (station)
        local stationId = station.id
        local mdata = management[stationId]

        if mdata and not sm_fuel.management[stationId] then
            loadStation({
                id = stationId, ped = station.ped, label = mdata.setting?.label or 'Pom bensin'
            })
        end
    end)
end

interface.callback('startMission', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:startMission', 1500, data) })
end)

interface.callback('exitmanagement', function (data, cb)
    interface.focus(false, false)
    TriggerServerEvent('fuelsystem:closeManage', playerState.fuel_station_id)
    cb('ok')
end)

interface.callback('saveLabel', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:updateLabel', 1500, data) })
end)

interface.callback('savePrice', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:updatePrice', 1500, data) })
end)

interface.callback('toggleStatus', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:toggleStatus', 1500, data) })
end)

interface.callback('addRole', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:addRole', 1500, data) })
end)

interface.callback('updateRoleAccess', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:updateRoleAccess', 1500, data) })
end)

interface.callback('deleteRole', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:deleteRole', 1500, data) })
end)

interface.callback('withdraw', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:withdraw', 1500, data) })
end)

interface.callback('deposit', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:deposit', 1500, data) })
end)

interface.callback('hireEmployee', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:hireEmployee', 1500, data) })
end)

interface.callback('fireEmployee', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:fireEmployee', 1500, data) })
end)

interface.callback('setRole', function (data, cb)
    cb({ success = lib.callback.await('fuelsystem:setRole', 1500, data) })
end)

interface.callback('getNearbyPlayers', function (data, cb)
    local players = lib.getNearbyPlayers(RHDCache.coords.xyz, 5.0, true)
    local playerOptions = {}
    
    array.forEach(players, function (player)
        local playerId = player.id
        local serverId = GetPlayerServerId(playerId)

        playerOptions[#playerOptions+1] = {
            value = tostring(serverId),
            label = Player(serverId)?.state?.name or ('Player (%s)'):format(serverId)
        }
    end)

    cb({ players = playerOptions })
end)

RegisterNetEvent('fuelsystem:syncManagementData', function (management)
    if source == '' then return end

    local mdata = management
    
    mdata.stationid = playerState.fuel_station_id
    mdata.mycitizenid = QBPlayerData.citizenid
    mdata.mission_price = mission_price

    interface.send({
        action = 'updateManagementData',
        data = mdata
    })
end)

RegisterNetEvent('fuelsystem:setupmanagement', function(management)
    if source == '' then return end

    setup(management)
end)

RegisterNetEvent('fuelsystem:loadStation', function (management)
    if source == '' or not management then return end

    local station = array.find(config.location, function (station)
        return station.id == management.stationid
    end)

    if not station then
        return
    end

    if sm_fuel.management[station.id] then
        return
    end

    loadStation({id = station.id, ped = station.ped, label = management.setting?.label or 'Pom bensin'})
end)

RegisterNetEvent('fuelsystem:removeStation', function(stationid)
    if source == '' then return end

    local mdata = sm_fuel.management[stationid]

    if mdata then
        if mdata.ped then
            mdata.ped:remove()
        end
        sm_fuel.management[stationid] = nil
    end

    if sm_fuel.blips[stationid] then
        sm_fuel.blips[stationid]:setLabel('Pom Bensin')
    end

    if playerState.fuel_station_id == stationid then
        playerState.fuel_station_id = nil
    end
end)

RegisterNetEvent('fuelsystem:updateManagementLabel', function(stationid, label)
    if source == '' then return end

    if sm_fuel.blips[stationid] then
        sm_fuel.blips[stationid]:setLabel(label)
    end
end)