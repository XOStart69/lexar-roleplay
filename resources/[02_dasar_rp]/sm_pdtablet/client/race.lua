local raceCfg = Config.Race
local propCfg = Config.Props
local blipCfg = Config.Blips
local markerCfg = Config.Marker
local ghostCfg = Config.Ghosting
local flareCfg = Config.Flare
local airCfg = Config.AirTrack

local checkpointModel = joaat(propCfg.checkpoint)
local startFinishModel = joaat(propCfg.startFinish)

local markerColor = markerCfg.color
local distanceColor = markerCfg.distanceColor
local primaryColor = markerCfg.primaryColor
local checkpointsAhead = raceCfg.checkpointsAhead
local buffer = raceCfg.checkpointBuffer

local min, max, floor = math.min, math.max, math.floor
local format = string.format

Race = {
    active = false,
    started = false,
    finished = false,
    raceId = nil,
    trackName = nil,
    isHost = false,
    checkpoints = {},
    current = 1,
    lap = 1,
    totalLaps = 0,
    startTime = 0,
    lapTime = 0,
    racers = {},
    countdown = 0,
    ghosting = -1,
    ghosted = false,
    trackType = 'ground',
}

local function isAirRace()
    return Race.trackType == 'air'
end

local props = {}
local blips = {}

local function setGhosted(enabled)
    if Race.ghosted == enabled then return end

    Race.ghosted = enabled
    SetLocalPlayerAsGhost(enabled)

    if enabled then
        SetGhostedEntityAlpha(ghostCfg.alpha)
    else
        ResetGhostedEntityAlpha()
    end
end

local function initGhosting()
    if not ghostCfg.enabled or Race.ghosting < 0 then return end

    setGhosted(true)

    CreateThread(function()
        while Race.active and Race.started and not Race.finished do
            if Race.ghosting > 0 and (GetGameTimer() - Race.startTime) >= Race.ghosting then
                setGhosted(false)
                Notify('Ghosting ended, collisions are active again.', 'inform')
                return
            end

            Wait(ghostCfg.loopTime)
        end
    end)
end

---@param ms number
---@return string
function FormatTime(ms)
    if not ms or ms <= 0 then return '00:00.000' end

    local totalSeconds = floor(ms / 1000)
    local minutes = floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local millis = ms % 1000

    return format('%02d:%02d.%03d', minutes, seconds, millis)
end

---@param model number
local function loadModel(model)
    if HasModelLoaded(model) then return true end

    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(10) end

    return HasModelLoaded(model)
end

---@param coords table
---@param model number
local function spawnProp(coords, model)
    if not loadModel(model) then return end

    local object = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    SetEntityAsMissionEntity(object, true, true)
    SetEntityCollision(object, false, true)
    SetEntityCanBeDamaged(object, false)
    SetEntityInvincible(object, true)
    props[#props + 1] = object
end

local function clearProps()
    for i = 1, #props do
        local object = props[i]
        if DoesEntityExist(object) then DeleteObject(object) end
    end
    props = {}
end

local function clearBlips()
    for i = 1, #blips do
        if DoesBlipExist(blips[i]) then RemoveBlip(blips[i]) end
    end
    blips = {}
end

---@param coords table
---@return number|nil
local function startFlare(coords)
    if not HasNamedPtfxAssetLoaded(flareCfg.dict) then
        RequestNamedPtfxAsset(flareCfg.dict)

        local timeout = GetGameTimer() + 3000
        while not HasNamedPtfxAssetLoaded(flareCfg.dict) and GetGameTimer() < timeout do
            Wait(0)
        end

        if not HasNamedPtfxAssetLoaded(flareCfg.dict) then return end
    end

    UseParticleFxAssetNextCall(flareCfg.dict)

    local handle = StartParticleFxLoopedAtCoord(flareCfg.name, coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0, flareCfg.scale, false, false, false, 0)

    SetParticleFxLoopedColour(handle, flareCfg.color.r, flareCfg.color.g, flareCfg.color.b)

    return handle
end

---@param index number
local function flareCheckpoint(index)
    if not flareCfg.enabled or isAirRace() then return end

    local checkpoint = Race.checkpoints[index]
    if not checkpoint then return end

    local left = startFlare(checkpoint.offset.left)
    local right = startFlare(checkpoint.offset.right)

    SetTimeout(flareCfg.time, function()
        if left then StopParticleFxLooped(left, false) end
        if right then StopParticleFxLooped(right, false) end
    end)
end

---@param coords vector3
---@param text string
---@param scale number
---@param color table
local function draw3DText(coords, text, scale, color)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

---@param coords table
---@param id number
local function addBlip(coords, id)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipCfg.size)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, blipCfg.color)
    ShowNumberOnBlip(blip, id)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Checkpoint ' .. id)
    EndTextCommandSetBlipName(blip)

    blips[#blips + 1] = blip
end

---@param index number
---@return number|nil
local function previewIndex(index)
    local total = #Race.checkpoints

    if Race.totalLaps == 0 then
        return index <= total and index or nil
    end

    if index > total then
        local lapsDone = Race.lap + floor((index - 1) / total) - 1
        if lapsDone >= Race.totalLaps and index > total + 1 then return nil end
        return (index - 1) % total + 1
    end

    return index
end

local function refreshRouteAndProps()
    clearProps()
    ClearGpsMultiRoute()
    StartGpsMultiRoute(blipCfg.color, true, true)

    local checkpoints = Race.checkpoints
    local total = #checkpoints

    for offset = 0, checkpointsAhead - 1 do
        local index = previewIndex(Race.current + offset)
        if not index then break end

        local checkpoint = checkpoints[index]
        local coords = checkpoint.coords

        AddPointToGpsMultiRoute(coords.x, coords.y, coords.z)

        if not isAirRace() then
            local model = (index == 1 or index == total) and startFinishModel or checkpointModel
            spawnProp(checkpoint.offset.left, model)
            spawnProp(checkpoint.offset.right, model)
        end
    end

    SetGpsMultiRouteRender(true)
end

---@param checkpoint table
---@return number
local function getPassDistance(checkpoint)
    if isAirRace() then
        return (checkpoint.radius or airCfg.defaultRadius) + buffer
    end

    local coords = checkpoint.coords
    local left = checkpoint.offset.left
    local center = vec3(coords.x, coords.y, coords.z)

    return #(center - vec3(left.x, left.y, left.z)) + buffer
end

---@return number
local function targetIndex()
    if Race.totalLaps > 0 and Race.current > #Race.checkpoints then
        return 1
    end

    return Race.current
end

---@return boolean
local function isFinalTarget()
    if Race.totalLaps == 0 then
        return Race.current >= #Race.checkpoints
    end

    return Race.lap >= Race.totalLaps and Race.current > #Race.checkpoints
end

local function sendUpdate(finished)
    local elapsed = Race.started and (GetGameTimer() - Race.startTime) or 0
    TriggerTokenEvent('sm_pdtablet:server:updateRacer', Race.current, Race.lap, finished, elapsed)
end

local function releasePlayer()
    if ForceClearTabletProp then ForceClearTabletProp() end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        FreezeEntityPosition(vehicle, false)
        SetEntityCollision(vehicle, true, true)
        SetEntityInvincible(vehicle, false)
        SetVehicleGravity(vehicle, true)
    end

    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
end

local function stopRace()
    clearProps()
    clearBlips()
    ClearGpsMultiRoute()
    setGhosted(false)
    releasePlayer()

    Race.active = false
    Race.started = false
    Race.finished = false
    Race.raceId = nil
    Race.checkpoints = {}
    Race.racers = {}
    Race.countdown = 0

    SendNUIMessage({ action = 'race', active = false })
end

local function finishRace()
    Race.finished = true
    Race.started = false

    clearProps()
    clearBlips()
    ClearGpsMultiRoute()
    setGhosted(false)
    releasePlayer()

    PlaySoundFrontend(-1, 'ScreenFlash', 'MissionFailedSounds', true)
    Notify(format('Finished! Time: %s', FormatTime(GetGameTimer() - Race.startTime)), 'success')
end

---@param index number
---@param offset number
---@return string
local function checkpointLabel(index, offset)
    local total = #Race.checkpoints

    if Race.totalLaps == 0 then
        if index == total then return 'FINISH' end
    elseif index == 1 and Race.current > 1 then
        if Race.lap >= Race.totalLaps then return 'FINISH' end
        return 'NEXT LAP'
    end

    if offset == 0 then return 'NEXT' end

    return 'CP ' .. index
end

local function drawMarkers()
    local coords = GetEntityCoords(PlayerPedId())
    local checkpoints = Race.checkpoints
    local baseSize = markerCfg.baseSize

    for offset = 0, 2 do
        local index = previewIndex(Race.current + offset)
        if not index then break end

        local checkpoint = checkpoints[index]
        local point = checkpoint.coords
        local distance = #(coords - vec3(point.x, point.y, point.z))
        local top

        if isAirRace() then
            local radius = checkpoint.radius or airCfg.defaultRadius
            local color = offset == 0 and airCfg.marker.nextColor or airCfg.marker.color

            DrawMarker(airCfg.marker.type, point.x, point.y, point.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                radius, radius, radius, color.r, color.g, color.b, color.a,
                false, false, 2, false, nil, nil, false)

            top = point.z + radius
        else
            local height = min(markerCfg.maxHeight, max(markerCfg.minHeight, distance / 2.5))
            local alpha = offset == 0 and markerColor.a or floor(markerColor.a * 0.45)

            DrawMarker(markerCfg.type, point.x, point.y, point.z,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                baseSize, baseSize, height,
                markerColor.r, markerColor.g, markerColor.b, alpha,
                false, true, 2, false, nil, nil, false)

            top = point.z + height
        end

        local color = offset == 0 and primaryColor or distanceColor

        draw3DText(vec3(point.x, point.y, top + 1.2),
            checkpointLabel(index, offset), 0.25, color)

        draw3DText(vec3(point.x, point.y, top + 0.5),
            format('%.0fm', distance), 0.5, distanceColor)
    end
end

local function raceThread()
    CreateThread(function()
        while Race.active do
            if Race.started and not Race.finished then
                drawMarkers()

                local checkpoints = Race.checkpoints
                local total = #checkpoints
                local checkpoint = checkpoints[targetIndex()]
                local point = checkpoint.coords
                local coords = GetEntityCoords(PlayerPedId())

                if #(coords - vec3(point.x, point.y, point.z)) < getPassDistance(checkpoint) then
                    if isFinalTarget() then
                        sendUpdate(true)
                        finishRace()
                    else
                        if Race.totalLaps > 0 and Race.current > total then
                            Race.current = 2
                            Race.lap = Race.lap + 1
                            Race.lapTime = GetGameTimer()
                            Notify(format('Lap %d/%d', Race.lap, Race.totalLaps), 'inform')
                        else
                            Race.current = Race.current + 1
                        end

                        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
                        sendUpdate(false)
                        refreshRouteAndProps()
                        flareCheckpoint(targetIndex())
                    end
                end

                Wait(0)
            else
                Wait(250)
            end
        end
    end)

    CreateThread(function()
        while Race.active do
            if IsEntityDead(PlayerPedId()) then
                LeaveCurrentRace()
                Notify('You died and were removed from the session.', 'error')
                return
            end

            local elapsed = Race.started and (GetGameTimer() - Race.startTime) or 0
            local lapElapsed = Race.started and (GetGameTimer() - Race.lapTime) or 0

            SendNUIMessage({
                action = 'race',
                active = true,
                data = {
                    trackName = Race.trackName,
                    started = Race.started,
                    finished = Race.finished,
                    isHost = Race.isHost,
                    checkpoint = min(Race.current, #Race.checkpoints),
                    totalCheckpoints = #Race.checkpoints,
                    lap = Race.lap,
                    totalLaps = Race.totalLaps,
                    time = FormatTime(elapsed),
                    lapTime = FormatTime(lapElapsed),
                    countdown = Race.countdown,
                    ghosted = Race.ghosted,
                    racers = Race.racers,
                },
            })

            Wait(200)
        end
    end)
end

RegisterNetEvent('sm_pdtablet:client:joinRace', function(data, checkpoints)
    if Race.active then stopRace() end

    Race.active = true
    Race.started = false
    Race.finished = false
    Race.raceId = data.RaceId
    Race.trackName = data.TrackName
    Race.isHost = data.IsHost
    Race.totalLaps = data.Laps
    Race.checkpoints = checkpoints
    Race.current = 1
    Race.lap = 1
    Race.racers = {}
    Race.countdown = 0
    Race.ghosting = data.Ghosting or -1
    Race.trackType = data.TrackType or 'ground'

    for i = 1, #checkpoints do
        addBlip(checkpoints[i].coords, i)
    end

    refreshRouteAndProps()
    raceThread()

    Notify(format('Joined session "%s". Waiting for the host to start.', data.TrackName), 'success')
end)

RegisterNetEvent('sm_pdtablet:client:leaveRace', function()
    if not Race.active then return end
    stopRace()
end)

RegisterNetEvent('sm_pdtablet:client:updateRacers', function(raceId, racers)
    if Race.raceId ~= raceId then return end
    Race.racers = racers
end)

RegisterNetEvent('sm_pdtablet:client:racerFinished', function(name, position)
    if not Race.active then return end
    Notify(format('%s finished in position %d', name, position), 'inform')
end)

RegisterNetEvent('sm_pdtablet:client:startCountdown', function()
    if not Race.active then return end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    Race.countdown = raceCfg.countdown

    while Race.countdown > 0 do
        if not Race.active then return end

        if vehicle ~= 0 then FreezeEntityPosition(vehicle, true) end
        PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', true)

        Wait(1000)
        Race.countdown = Race.countdown - 1
    end

    if not Race.active then return end

    if vehicle ~= 0 then FreezeEntityPosition(vehicle, false) end
    PlaySoundFrontend(-1, 'ScreenFlash', 'WastedSounds', true)

    Race.started = true
    Race.startTime = GetGameTimer()
    Race.lapTime = Race.startTime

    initGhosting()
    refreshRouteAndProps()
    flareCheckpoint(1)
    flareCheckpoint(targetIndex())
    Notify('Go!', 'success')
end)

function IsRaceActive()
    return Race.active
end

function LeaveCurrentRace()
    if not Race.active then return end
    TriggerTokenEvent('sm_pdtablet:server:leaveRace')
    stopRace()
end


AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearProps()
    clearBlips()
    ClearGpsMultiRoute()
    setGhosted(false)
end)
