RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    ShutdownLoadingScreenNui()
    if not QBConfig.Server.PVP then return end
    SetCanAttackFriendly(PlayerPedId(), true, false)
    NetworkSetFriendlyFireOption(true)
end)

RegisterNetEvent('QBCore:Client:PvpHasToggled', function(pvp_state)
    SetCanAttackFriendly(PlayerPedId(), pvp_state, false)
    NetworkSetFriendlyFireOption(pvp_state)
end)

RegisterNetEvent('qb_event_client:tptocoords', function(coords)
    if source == '' then return end

    local x, y, z, h = table.unpack(coords)
    if not h then h = GetEntityHeading(cache.ped) end
    SetPedCoordsKeepVehicle(cache.ped, x, y, z)
    SetEntityHeading(cache.ped, h)
end)

RegisterNetEvent('qb_event_client:gotoMarker', function()
    if source == '' then return end

    local GetEntityCoords = GetEntityCoords
    local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord

    local blipMarker <const> = GetFirstBlipInfoId(8)

    if not DoesBlipExist(blipMarker) then
        QBCore.Functions.Notify(Lang:t('error.no_waypoint'), 'error', 5000)
        return
    end

    -- Fade screen to hide how clients get teleported.
    DoScreenFadeOut(650)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local ped, coords <const> = cache.ped, GetBlipInfoIdCoord(blipMarker)
    local vehicle = GetVehiclePedIsIn(ped, false)
    local oldCoords <const> = GetEntityCoords(ped)

    -- Unpack coords instead of having to unpack them while iterating.
    -- 825.0 seems to be the max a player can reach while 0.0 being the lowest.
    local x, y, groundZ, Z_START = coords['x'], coords['y'], 850.0, 950.0
    local found = false
    if vehicle > 0 then
        FreezeEntityPosition(vehicle, true)
    else
        FreezeEntityPosition(ped, true)
    end

    for i = Z_START, 0, -25.0 do
        local z = i
        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        local curTime = GetGameTimer()
        while IsNetworkLoadingScene() do
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end
        NewLoadSceneStop()
        SetPedCoordsKeepVehicle(ped, x, y, z)

        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x, y, z)
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end

        -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false);
        if found then
            Wait(0)
            SetPedCoordsKeepVehicle(ped, x, y, groundZ)
            break
        end
        Wait(0)
    end

    -- Remove black screen once the loop has ended.
    DoScreenFadeIn(650)
    if vehicle > 0 then
        FreezeEntityPosition(vehicle, false)
    else
        FreezeEntityPosition(ped, false)
    end

    if not found then
        -- If we can't find the coords, set the coords to the old ones.
        -- We don't unpack them before since they aren't in a loop and only called once.
        SetPedCoordsKeepVehicle(ped, oldCoords['x'], oldCoords['y'], oldCoords['z'] - 1.0)
        QBCore.Functions.Notify(Lang:t('error.tp_error'), 'error', 5000)
    end

    -- If Z coord was found, set coords in found coords.
    SetPedCoordsKeepVehicle(ped, x, y, groundZ)
    QBCore.Functions.Notify(Lang:t('success.teleported_waypoint'), 'success', 5000)
end)

RegisterNetEvent('qb_event_client:spawnVehicle', function(vehName, serverPlate)
    if source == '' then return end

    local ok, hash = pcall(function ()
        return lib.requestModel(vehName)
    end)

    if not ok then
        if hash then
            lib.print.warn(hash)
        end
        return
    end

    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local vehicle = QBCore.Functions.SpawnVehicle(hash, nil, vec(coords.x, coords.y, coords.z, heading), true, true)

    if not (vehicle and DoesEntityExist(vehicle)) then
        return
    end

    SetEntityHeading(vehicle, heading)
    local plate = serverPlate or ('SM ' .. lib.string.random('.....'))
    SetVehicleNumberPlateText(vehicle, plate)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', plate)
end)

RegisterNetEvent('qb_event_client:deleteVehicle', function()
    if source == '' then return end

    local coords = GetEntityCoords(cache.ped)
    
    if cache.vehicle then
        SetEntityAsMissionEntity(cache.vehicle, true, true)
        DeleteEntity(cache.vehicle)
        return
    end

    local vehicle = lib.getClosestVehicle(coords, 3.0)
    if not vehicle then
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteEntity(vehicle)
end)

local eventHooks = require 'modules.hooks'

RegisterNetEvent('QBCore:Player:setPData', function(key, val, subVal)
    if source == '' then return end

    if key == 'all' then
        QBCore.PlayerData = val
        goto skip
    end

    if not QBCore.PlayerData[key] then
        QBCore.PlayerData[key] = (subVal ~= nil) and {} or val
    end

    if subVal ~= nil then
        if type(QBCore.PlayerData[key]) ~= 'table' then
            QBCore.PlayerData[key] = {}
        end
        QBCore.PlayerData[key][val] = subVal
    else
        QBCore.PlayerData[key] = val
    end

    ::skip::

    TriggerEvent('QBCore:Player:SetPlayerData', QBCore.PlayerData)
    eventHooks('core:updatePlayerData', QBCore.PlayerData)
    eventHooks('core:updatePlayerDataBykey', key, val, subVal)
end)

local blockedWords = {
    'crytxontop', 'crytx', 'hama kontol', 'dev magang',
    'discord.gg', 'p5uquhsukq',
    'ngentot', 'lonte', 'goblok', 'kontol', 'tolol', 'tonggos',
}

local function containsBlocked(text)
    if not text then return false end
    local lower = string.lower(tostring(text))
    for _, word in ipairs(blockedWords) do
        if string.find(lower, word, 1, true) then
            return true
        end
    end
    return false
end

RegisterNetEvent('QBCore:Notify', function(text, type, length, icon)
    if containsBlocked(text) then return end
    QBCore.Functions.Notify(text, type, length, icon)
end)

RegisterNUICallback('getNotifyConfig', function(_, cb)
    cb(QBConfig.Notify)
end)

RegisterNetEvent('rhd_spawn:client:onSpawn', function(data)
    local metadata = QBCore.PlayerData.metadata

    local health = metadata.health
    local armour = metadata.armor

    Wait(1500)
    if health and type(health) == "number" then
        SetEntityMaxHealth(cache.ped, 200)
        SetEntityHealth(cache.ped, health)
    end

    if armour and type(armour) == "number" then
        SetPedArmour(cache.ped, armour)
    end
end)


---@SpawnVehicle

-- Set vehicle props
---@param netId number
---@param props table<any, any>
RegisterNetEvent('sm_core:client:setVehicleProperties', function(netId, props)
    if not props then return end
    local timeOut = GetGameTimer() + 1000
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    while true do
        if NetworkGetEntityOwner(vehicle) == cache.playerId then
            if lib.setVehicleProperties(vehicle, props) then
                return
            end
        end
        if GetGameTimer() > timeOut then
            return
        end

        Wait(50)
    end
end)

-- Clear vehicle peds
---@param vehicle number
---@param init boolean
qbLib.entityStateHandler('initVehicle', function(vehicle, _, init)
    if not init then return end

    for i = -1, 0 do
        local ped = GetPedInVehicleSeat(vehicle, i)
        if ped ~= cache.ped and ped > 0 and NetworkGetEntityOwner(ped) == cache.playerId then
            DeleteEntity(ped)
        end
    end

    lib.waitFor(function()
        return not IsEntityWaitingForWorldCollision(vehicle)
    end)

    if NetworkGetEntityOwner(vehicle) ~= cache.playerId then return end

    local state = Entity(vehicle).state

    SetVehicleOnGroundProperly(vehicle);

    SetTimeout(0, function()
        state:set('initVehicle', nil, true)
    end)
end)