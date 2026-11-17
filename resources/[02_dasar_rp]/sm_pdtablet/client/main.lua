local tabletOpen = false
local tabletProp = nil

local animCfg = Config.Animation

---@param message string
---@param kind string|nil
function Notify(message, kind)
    lib.notify({
        title = 'PD Pursuit',
        description = message,
        type = kind or 'inform',
    })
end

local function clearTabletProp()
    if tabletProp and DoesEntityExist(tabletProp) then
        DetachEntity(tabletProp, true, true)
        DeleteEntity(tabletProp)
    end
    tabletProp = nil

    local ped = PlayerPedId()
    local model = joaat(animCfg.prop)

    for _, object in ipairs(GetGamePool('CObject')) do
        if GetEntityModel(object) == model and IsEntityAttachedToEntity(object, ped) then
            DetachEntity(object, true, true)
            DeleteEntity(object)
        end
    end
end

local function startTabletAnimation()
    if not animCfg.enabled then return end

    local ped = PlayerPedId()

    if lib.requestAnimDict(animCfg.dict, 5000) then
        lib.playAnim(ped, animCfg.dict, animCfg.clip, 5.0, 5.0, -1, 51, 0, false, 0, false)
    end

    clearTabletProp()

    local model = joaat(animCfg.prop)
    if not lib.requestModel(model, 5000) then return end

    local bone = GetPedBoneIndex(ped, animCfg.bone)
    local coords = GetEntityCoords(ped)

    tabletProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    SetEntityAsMissionEntity(tabletProp, true, true)

    AttachEntityToEntity(tabletProp, ped, bone,
        animCfg.offset.x, animCfg.offset.y, animCfg.offset.z,
        animCfg.rotation.x, animCfg.rotation.y, animCfg.rotation.z,
        true, true, false, true, 1, true)

    SetModelAsNoLongerNeeded(model)
end

local function stopTabletAnimation()
    if not animCfg.enabled then return end

    StopAnimTask(PlayerPedId(), animCfg.dict, animCfg.clip, 1.0)
    clearTabletProp()
    RemoveAnimDict(animCfg.dict)
end

function ForceClearTabletProp()
    clearTabletProp()
end

RegisterNetEvent('sm_pdtablet:client:notify', function(message, kind)
    Notify(message, kind)
end)

RegisterNetEvent('sm_pdtablet:client:setWaypoint', function(x, y)
    SetNewWaypoint(x, y)
end)

local function closeTablet()
    if not tabletOpen then return end

    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'tablet', active = false })
    stopTabletAnimation()
    TriggerTokenEvent('sm_pdtablet:server:tabletClosed')
end

local function openTablet()
    if tabletOpen then return end
    if IsCreatorActive() then
        Notify('Finish the current track first.', 'error')
        return
    end

    local data = lib.callback.await('sm_pdtablet:server:getBaseData', false)
    if not data then
        Notify('This tablet is for police personnel only.', 'error')
        return
    end

    if data.offDuty then
        Notify('You must be on duty to use this tablet.', 'error')
        return
    end

    tabletOpen = true
    startTabletAnimation()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'tablet', active = true, data = data })
end

RegisterNetEvent('sm_pdtablet:client:openTablet', openTablet)

RegisterNetEvent('sm_pdtablet:client:updateLobbies', function(lobbies)
    if not tabletOpen then return end
    SendNUIMessage({ action = 'lobbies', data = lobbies })
end)

RegisterNetEvent('sm_pdtablet:client:updateSession', function(session)
    if not tabletOpen then return end
    SendNUIMessage({ action = 'session', data = session })
end)

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb('ok')
end)

RegisterNUICallback('refresh', function(_, cb)
    local data = lib.callback.await('sm_pdtablet:server:getBaseData', false)
    cb(data or {})
end)

RegisterNUICallback('getHistory', function(_, cb)
    cb(lib.callback.await('sm_pdtablet:server:getHistory', false) or {})
end)

RegisterNUICallback('createTrack', function(data, cb)
    local ok, result, trackType = lib.callback.await('sm_pdtablet:server:canCreateTrack', false, data.name)
    if not ok then
        Notify(result, 'error')
        cb({ ok = false })
        return
    end

    closeTablet()
    StartCreator(result, nil, nil, trackType)
    cb({ ok = true })
end)

RegisterNUICallback('editTrack', function(data, cb)
    local track = lib.callback.await('sm_pdtablet:server:getTrackForEdit', false, data.trackId)
    if not track then
        Notify('This track cannot be edited.', 'error')
        cb({ ok = false })
        return
    end

    closeTablet()
    StartCreator(track.name, track.trackId, track.checkpoints, track.trackType)
    cb({ ok = true })
end)

RegisterNUICallback('setDivision', function(data, cb)
    local ok = lib.callback.await('sm_pdtablet:server:setDivision', false, data.division)
    if not ok then
        Notify('Could not switch division.', 'error')
        cb({ ok = false })
        return
    end

    local base = lib.callback.await('sm_pdtablet:server:getBaseData', false)
    cb({ ok = true, data = base })
end)

RegisterNUICallback('getLeaderboard', function(data, cb)
    cb(lib.callback.await('sm_pdtablet:server:getLeaderboard', false, data.trackId) or {})
end)

RegisterNUICallback('deleteTrack', function(data, cb)
    TriggerTokenEvent('sm_pdtablet:server:deleteTrack', data.trackId)
    cb({ ok = true })
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if data.x and data.y then
        SetNewWaypoint(data.x + 0.0, data.y + 0.0)
        Notify('Waypoint set to the starting line.', 'inform')
    end
    cb({ ok = true })
end)

RegisterNUICallback('hostRace', function(data, cb)
    local ok, result = lib.callback.await('sm_pdtablet:server:hostRace', false, data)
    if not ok then
        Notify(result, 'error')
        cb({ ok = false })
        return
    end

    local joined, message = lib.callback.await('sm_pdtablet:server:joinRace', false, result)
    if not joined then
        Notify(message, 'error')
        cb({ ok = false })
        return
    end

    cb({ ok = true })
end)

RegisterNUICallback('joinRace', function(data, cb)
    local ok, message = lib.callback.await('sm_pdtablet:server:joinRace', false, data.raceId)
    if not ok then
        Notify(message, 'error')
        cb({ ok = false })
        return
    end

    cb({ ok = true })
end)

RegisterNUICallback('startRace', function(_, cb)
    TriggerTokenEvent('sm_pdtablet:server:startRace')
    closeTablet()
    cb({ ok = true })
end)

RegisterNUICallback('leaveRace', function(_, cb)
    LeaveCurrentRace()
    cb({ ok = true })
end)

RegisterCommand('pdcancel', function()
    if IsCreatorActive() then
        CancelCreator()
        return
    end

    if IsRaceActive() then
        LeaveCurrentRace()
        return
    end

    Notify('Nothing to cancel.', 'inform')
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)
    StopAnimTask(PlayerPedId(), animCfg.dict, animCfg.clip, 1.0)
    clearTabletProp()
end)
