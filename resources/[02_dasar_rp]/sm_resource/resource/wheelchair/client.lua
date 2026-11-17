local Config = localmodule 'config.shared'
local S = Config.strings

local loopActive = false
local breakLoop = false
local inVehicle = false
local activeType = nil
local keyThreadActive = false
local remainingSeconds = 0

local function notify(desc, nType)
    lib.notify({ description = desc, duration = 3500, type = nType or 'inform' })
end

local function secondToClock(seconds)
    if seconds <= 0 then return '00', '00', '00' end
    local h = string.format('%02.f', math.floor(seconds / 3600))
    local m = string.format('%02.f', math.floor(seconds / 60 - (h * 60)))
    local s = string.format('%02.f', math.floor(seconds - h * 3600 - m * 60))
    return h, m, s
end

local function updateTimerUI()
    if remainingSeconds < 1 then
        infoUI.remove('crutch:timer')
        return
    end
    local h, m, s = secondToClock(remainingSeconds)
    local title = S.chair_added
    if activeType == 'crutch' then
        title = S.crutch_added
    elseif activeType == 'infus' then
        title = S.infus_added
    end
    infoUI.show({
        id = 'crutch:timer',
        title = title,
        icon = 'fa-solid fa-clock',
        description = ('%s Jam %s Menit %s Detik'):format(h, m, s)
    })
end

local function startKeyThread(equipType)
    if keyThreadActive then return end
    keyThreadActive = true
    CreateThread(function()
        local disableSprint = equipType == 'crutch' or equipType == 'infus'
        local isInfus = equipType == 'infus'
        while keyThreadActive do
            if disableSprint then
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 22, true)
            else
                DisableControlAction(0, 75, true)
                DisableControlAction(27, 75, true)
            end
            if isInfus then
                DisableControlAction(0, 25, true) -- Disable Aim / Right Click
            end
            DisablePlayerFiring(cache.ped, true)
            Wait(0)
        end
    end)
end

local function stopLoop()
    if not loopActive then return end
    breakLoop = true
end

local function cleanupLoop()
    loopActive = false
    breakLoop = false
    activeType = nil
    keyThreadActive = false
    remainingSeconds = 0
    infoUI.remove('crutch:timer')
end

local function attachCrutchObject()
    lib.requestModel('crutch', 5000)
    local coords = GetEntityCoords(cache.ped)
    local obj = CreateObjectNoOffset('crutch', coords.x, coords.y, coords.z + 0.5, true, false)
    SetModelAsNoLongerNeeded('crutch')
    AttachEntityToEntity(obj, cache.ped, GetPedBoneIndex(cache.ped, 43810),
        0.93, -0.15, -0.03, 9.31, -88.64, 177.48,
        true, true, false, true, 1, true)
    return obj
end

local function startCrutchLoop(time)
    CreateThread(function()
        if loopActive then stopLoop() Wait(1100) end

        notify(S.crutch_added_desc:format(time))
        loopActive, breakLoop, activeType = true, false, 'crutch'
        remainingSeconds = time * 60
        local timeSpent = 0

        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`)
        local obj = attachCrutchObject()
        lib.requestAnimSet('move_lester_CaneUp', 100)
        local oldWalk = GetPedMovementClipset(cache.ped)
        startKeyThread('crutch')

        while loopActive do
            if breakLoop then
                ResetPedMovementClipset(cache.ped)
                if obj and DoesEntityExist(obj) then DeleteObject(obj) end
                cleanupLoop()
                return
            end

            if inVehicle and obj and DoesEntityExist(obj) then
                DeleteObject(obj)
            elseif not inVehicle and (not obj or not DoesEntityExist(obj)) then
                obj = attachCrutchObject()
            end

            if IsPedArmed(cache.ped, 1) or IsPedArmed(cache.ped, 2) or IsPedArmed(cache.ped, 4) then
                notify(S.cant_wield, 'error')
                SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`)
            end

            if GetPedMovementClipset(cache.ped) == oldWalk then
                SetPedMovementClipset(cache.ped, 'move_lester_CaneUp', 1.0)
            end

            remainingSeconds = remainingSeconds - 1
            updateTimerUI()

            timeSpent = timeSpent + 1000
            if timeSpent >= 60000 then
                TriggerTokenEvent('sm_crutch:update', 'crutch', 1, cache.serverId)
                timeSpent = 0
            end

            Wait(1000)
        end
    end)
end

local function startChairLoop(time)
    CreateThread(function()
        if loopActive then stopLoop() Wait(1100) end

        notify(S.chair_added_desc:format(time))
        loopActive, breakLoop, activeType = true, false, 'chair'
        remainingSeconds = time * 60
        local timeSpent = 0
        local chairVeh
        startKeyThread('chair')

        while loopActive do
            if breakLoop then
                if chairVeh and DoesEntityExist(chairVeh) then DeleteVehicle(chairVeh) end
                cleanupLoop()
                return
            end

            if not inVehicle then
                if not chairVeh or not DoesEntityExist(chairVeh) then
                    local coords = GetEntityCoords(cache.ped)
                    local hash = `iak_wheelchair`
                    lib.requestModel(hash, 3000)
                    chairVeh = CreateVehicle(hash, coords.x, coords.y, coords.z, GetEntityHeading(cache.ped), true, false)
                    TaskWarpPedIntoVehicle(cache.ped, chairVeh, -1)
                    if Config.carKeyEvent then
                        TriggerEvent(Config.carKeyEvent, GetVehicleNumberPlateText(chairVeh))
                    end
                    SetModelAsNoLongerNeeded(hash)
                elseif not IsPedInVehicle(cache.ped, chairVeh, false) then
                    local eCoords = GetEntityCoords(chairVeh)
                    SetEntityCoords(chairVeh, eCoords.x, eCoords.y, eCoords.z + 1.0, true, false, false, false)
                    SetVehicleOnGroundProperly(chairVeh)
                    TaskWarpPedIntoVehicle(cache.ped, chairVeh, -1)
                end
            end

            if IsPedArmed(cache.ped, 1) or IsPedArmed(cache.ped, 2) or IsPedArmed(cache.ped, 4) then
                notify(S.cant_wield, 'error')
                SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`)
            end

            remainingSeconds = remainingSeconds - 1
            updateTimerUI()

            timeSpent = timeSpent + 1000
            if timeSpent >= 60000 then
                TriggerTokenEvent('sm_crutch:update', 'chair', 1, cache.serverId)
                timeSpent = 0
            end

            Wait(1000)
        end
    end)
end

local function startInfusLoop(time)
    CreateThread(function()
        if loopActive then stopLoop() Wait(1100) end

        notify(S.infus_added_desc:format(time))
        loopActive, breakLoop, activeType = true, false, 'infus'
        remainingSeconds = time * 60
        local timeSpent = 0

        SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`)
        exports.sm_emotes:EmoteCommandStart("infus")
        startKeyThread('infus')
        Wait(2000)

        while loopActive do
            if breakLoop then
                exports.sm_emotes:EmoteCancel(true)
                cleanupLoop()
                return
            end

            if IsPedArmed(cache.ped, 1) or IsPedArmed(cache.ped, 2) or IsPedArmed(cache.ped, 4) then
                notify(S.cant_wield, 'error')
                SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`)
            end

            local isPlaying = IsEntityPlayingAnim(cache.ped, "infus@writzstudio", "infus", 3)
            if not isPlaying then
                exports.sm_emotes:EmoteCancel(true)
                Wait(200)
                exports.sm_emotes:EmoteCommandStart("infus")
            end

            remainingSeconds = remainingSeconds - 1
            updateTimerUI()

            timeSpent = timeSpent + 1000
            if timeSpent >= 60000 then
                TriggerTokenEvent('sm_crutch:update', 'infus', 1, cache.serverId)
                timeSpent = 0
            end

            Wait(1000)
        end
    end)
end

local function promptTime(equipType, target, removeItem)
    local maxTime = Config.maxAssignTime[equipType]

    local dialogTitle = S.chair_time_dialog
    if equipType == 'crutch' then
        dialogTitle = S.crutch_time_dialog
    elseif equipType == 'infus' then
        dialogTitle = S.infus_time_dialog
    end

    local input = lib.inputDialog(dialogTitle, {
        { type = 'number', label = S.minutes_dialog, required = true, min = 1 }
    })
    if not input or not input[1] then return end

    local amount = math.floor(input[1])
    if amount < 1 then return notify(S.invalid_entry, 'error') end
    if maxTime and amount > maxTime then return notify(S.invalid_entry_max:format(maxTime), 'error') end

    TriggerTokenEvent('sm_crutch:assign', equipType, target, amount)
    if removeItem then
        local itemKey = equipType
        if equipType == 'chair' then itemKey = 'wheelchair' end
        TriggerTokenEvent('sm_crutch:removeItem', Config.items[itemKey].name)
    end
end

local function openAssignMenu(equipType, isItem)
    local closestPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 10.0, false)
    local options = {}

    if Config.allowSelfUse then
        options[#options + 1] = {
            title = S.self_use,
            icon = 'user-plus',
            description = S.player_id .. ' ' .. cache.serverId,
            onSelect = function() promptTime(equipType, cache.serverId, isItem) end
        }
    end

    if #closestPlayers > 0 then
        local playerList = {}
        for i = 1, #closestPlayers do
            playerList[#playerList + 1] = { id = GetPlayerServerId(closestPlayers[i].id) }
        end
        local nearbyPlayers = lib.callback.await('sm_crutch:getPlayerData', false, playerList)
        if nearbyPlayers then
            for _, v in pairs(nearbyPlayers) do
                options[#options + 1] = {
                    title = v.name,
                    icon = 'user',
                    description = S.player_id .. ' ' .. v.id,
                    onSelect = function() promptTime(equipType, v.id, isItem) end
                }
            end
        end
    end

    if #options == 0 then return notify(S.no_one_nearby, 'error') end

    lib.registerContext({ id = 'sm_crutch_menu', title = S.select_patient, options = options })
    lib.showContext('sm_crutch_menu')
end

RegisterNetEvent('sm_crutch:start', function(equipType, time)
    if equipType == 'crutch' then startCrutchLoop(time)
    elseif equipType == 'chair' then startChairLoop(time)
    elseif equipType == 'infus' then startInfusLoop(time) end
end)

RegisterNetEvent('sm_crutch:stop', function(message)
    stopLoop()
    if message then notify(message, 'success') end
end)

RegisterNetEvent('sm_crutch:openMenu', function(equipType, isItem)
    openAssignMenu(equipType, isItem)
end)

lib.onCache('vehicle', function(vehicle) inVehicle = vehicle ~= false end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(5000)
    local data = lib.callback.await('sm_crutch:checkInjuryTime', false)
    if not data then return end
    if data.crutch then startCrutchLoop(data.time)
    elseif data.chair then startChairLoop(data.time)
    elseif data.infus then startInfusLoop(data.time) end
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource or not LocalPlayer.state.isLoggedIn then return end
    Wait(5000)
    local data = lib.callback.await('sm_crutch:checkInjuryTime', false)
    if not data then return end
    if data.crutch then startCrutchLoop(data.time)
    elseif data.chair then startChairLoop(data.time)
    elseif data.infus then startInfusLoop(data.time) end
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    local victim, died = data[1], data[4]
    if not died or not IsPedAPlayer(victim) then return end
    if NetworkGetPlayerIndexFromPed(victim) ~= PlayerId() then return end
    if not IsPedDeadOrDying(victim, true) and not IsPedFatallyInjured(victim) then return end
    if Config.disableOnDeath.crutch then TriggerTokenEvent('sm_crutch:update', 'crutch', false, cache.serverId) end
    if Config.disableOnDeath.wheelchair then TriggerTokenEvent('sm_crutch:update', 'chair', false, cache.serverId) end
    if Config.disableOnDeath.infus then TriggerTokenEvent('sm_crutch:update', 'infus', false, cache.serverId) end
end)

exports('OpenCrutchMenu', function() openAssignMenu('crutch', false) end)
exports('OpenChairMenu', function() openAssignMenu('chair', false) end)
exports('OpenInfusMenu', function() openAssignMenu('infus', false) end)
exports('RemoveCrutch', function(target) TriggerTokenEvent('sm_crutch:update', 'crutch', false, target) end)
exports('RemoveChair', function(target) TriggerTokenEvent('sm_crutch:update', 'chair', false, target) end)
exports('RemoveInfus', function(target) TriggerTokenEvent('sm_crutch:update', 'infus', false, target) end)
exports('SetCrutchTime', function(target, amount) TriggerTokenEvent('sm_crutch:assign', 'crutch', target, amount) end)
exports('SetChairTime', function(target, amount) TriggerTokenEvent('sm_crutch:assign', 'chair', target, amount) end)
exports('SetInfusTime', function(target, amount) TriggerTokenEvent('sm_crutch:assign', 'infus', target, amount) end)




--- SPEED LIMIT
local function setLimit(veh)
    if not veh then return end
    Wait(100)

    local vehModel = GetEntityModel(veh)

    if vehModel ~= joaat('iak_wheelchair') then
        return
    end

    CreateThread(function ()
        while cache.vehicle do
            local entitySpeed = GetEntitySpeed(cache.vehicle)
            local kmhspeed = entitySpeed * 3.6

            if math.floor(kmhspeed) >= 10 then
                SetEntityMaxSpeed(cache.vehicle, entitySpeed)
            end
            
            Wait(50)
        end
    end)
end

lib.onCache('vehicle', setLimit)