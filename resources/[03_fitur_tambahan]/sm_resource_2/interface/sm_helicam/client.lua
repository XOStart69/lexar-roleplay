local config = localmodule 'config'

interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetEntitySpeed = GetEntitySpeed
local GetEntityHeading = GetEntityHeading
local GetEntityHeightAboveGround = GetEntityHeightAboveGround
local DoesEntityExist = DoesEntityExist
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local GetDisabledControlNormal = GetDisabledControlNormal
local GetCamRot = GetCamRot
local GetCamCoord = GetCamCoord
local GetCamFov = GetCamFov
local SetCamRot = SetCamRot
local SetCamFov = SetCamFov
local DrawSpotLight = DrawSpotLight
local DrawMarker = DrawMarker
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetVehiclePedIsIn = GetVehiclePedIsIn
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetToVeh = NetToVeh
local DecorGetFloat = DecorGetFloat
local DecorSetFloat = DecorSetFloat
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local rad, sin, cos, abs, floor, ceil, max, min = math.rad, math.sin, math.cos, math.abs, math.floor, math.ceil, math.max, math.min
local sformat = string.format

local keys = config.keys
local fovMax, fovMin = config.fovMax, config.fovMin
local zoomSpeed, panSpeed = config.zoomSpeed, config.panSpeed
local minHeight = config.minHeight
local maxTargetDistance = config.maxTargetDistance
local losFlags = config.losBlockFlags
local spotCfg = config.spotlight
local markerCfg = config.marker
local speedFactor = config.speedUnit == 'MPH' and 2.236936 or 3.6

local DECOR_X, DECOR_Y, DECOR_Z = 'smHeliSpotX', 'smHeliSpotY', 'smHeliSpotZ'
local DECOR_INTERVAL_MS = 100
local UI_INTERVAL_MS = 100
local SELECT_SOUND, SELECT_SET = 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET'

DecorRegister(DECOR_X, 1)
DecorRegister(DECOR_Y, 1)
DecorRegister(DECOR_Z, 1)

local heliModels = {}
for i = 1, #config.helicopters do
    heliModels[joaat(config.helicopters[i])] = true
end

local myServerId = cache.serverId
local camActive = false
local camHandle
local fov = (fovMax + fovMin) * 0.5
local visionState = 0
local vehicleDisplay = 0
local targetVehicle
local spotMode = 'off'
local spotPaused = false
local markers = {}
local markerBlips = {}

local uiData = {
    heliZ = 0,
    camZ = 0,
    vehicle_display = 0,
    vehicle_info = { plate = nil, speed = 0, model = nil },
    vision_state = 0,
    speed_measure = config.speedUnit,
    zoom_value = 0,
    camFov = 0,
    fov_min = fovMin,
    fov_max = fovMax,
    locked = false,
    theme = config.theme,
}

---@return boolean
local function isPolice()
    local job = QBPlayerData.job
    return job ~= nil and config.jobs[job.name] == true
end

---@param heli number
---@return boolean
local function highEnough(heli)
    return GetEntityHeightAboveGround(heli) > minHeight
end

local function playSelect()
    PlaySoundFrontend(-1, SELECT_SOUND, SELECT_SET, false)
end

---@param rot vector3
---@return vector3
local function rotToDirection(rot)
    local z, x = rad(rot.z), rad(rot.x)
    local horizontal = abs(cos(x))
    return vector3(-sin(z) * horizontal, cos(z) * horizontal, sin(x))
end

---@param from vector3
---@param to vector3
---@param flags number
---@param ignore number
---@return boolean hit
---@return vector3 coords
---@return number entity
local function raycast(from, to, flags, ignore)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignore, 4)
    local _, hit, coords, _, entity = GetShapeTestResult(handle)
    return hit == true or hit == 1, coords, entity
end

---@param mode string
---@param paused? boolean
local function setSpot(mode, paused)
    paused = paused == true
    if mode == spotMode and paused == spotPaused and mode ~= 'track' then return end
    spotMode, spotPaused = mode, paused

    local netId = mode == 'track' and targetVehicle and DoesEntityExist(targetVehicle) and NetworkGetNetworkIdFromEntity(targetVehicle) or nil
    if mode == 'track' and not netId then
        spotMode = 'off'
        mode = 'off'
    end
    TriggerTokenEvent('sm_helicam:server:spot', mode, netId, paused)
end

local function releaseTarget()
    targetVehicle = nil
    uiData.locked = false
    if spotMode == 'track' then
        setSpot('off')
    end
end

---@param vehicle number
local function renderVehicleInfo(vehicle)
    local info = uiData.vehicle_info
    info.model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    info.plate = GetVehicleNumberPlateText(vehicle)
    info.speed = ceil(GetEntitySpeed(vehicle) * speedFactor)
end

---@param coord number
---@return string
local function toDms(coord)
    local degrees = floor(coord)
    local minutesFull = (coord - degrees) * 60
    local minutes = floor(minutesFull)
    local seconds = (minutesFull - minutes) * 60
    return sformat('%02d° %02d\' %05.2f"', degrees, minutes, seconds)
end

local function changeVision()
    if visionState == 0 then
        SetNightvision(true)
        visionState = 1
    elseif visionState == 1 then
        SetNightvision(false)
        SetSeethrough(true)
        SeethroughSetMaxThickness(config.thermalMaxThickness)
        visionState = 2
    else
        SetSeethrough(false)
        SeethroughSetMaxThickness(10000.0)
        visionState = 0
    end
    uiData.vision_state = visionState
end

local function hideHud()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(11)
    HideHudComponentThisFrame(12)
    HideHudComponentThisFrame(13)
    HideHudComponentThisFrame(15)
    HideHudComponentThisFrame(18)
    HideHudComponentThisFrame(19)
end

---@param cam number
---@param zoomValue number
local function rotateCam(cam, zoomValue)
    local axisX = GetDisabledControlNormal(0, 220)
    local axisY = GetDisabledControlNormal(0, 221)
    if axisX == 0.0 and axisY == 0.0 then return end

    local rot = GetCamRot(cam, 2)
    local factor = panSpeed * (zoomValue + 0.1)
    SetCamRot(cam, max(min(20.0, rot.x - axisY * factor), -89.5), 0.0, rot.z - axisX * factor, 2)
end

---@param cam number
local function handleZoom(cam)
    if IsDisabledControlJustPressed(0, 241) then
        fov = max(fov - zoomSpeed, fovMin)
    elseif IsDisabledControlJustPressed(0, 242) then
        fov = min(fov + zoomSpeed, fovMax)
    end

    local current = GetCamFov(cam)
    if abs(fov - current) < 0.1 then return end
    local nextFov = current + (fov - current) * 0.05
    SetCamFov(cam, nextFov)
    uiData.camFov = nextFov
end

---@param cam number
---@param heli number
---@param vehicle number
---@return boolean
local function hasLineOfSight(cam, heli, vehicle)
    local target = GetEntityCoords(vehicle)
    local origin = GetCamCoord(cam)
    local delta = target - origin
    local length = #delta
    if length < 1.0 then return true end

    local hit, _, entity = raycast(origin + (delta / length) * 3.0, target, losFlags, heli)
    return not hit or entity == vehicle
end

---@param cam number
---@param heli number
---@return number?
local function vehicleInView(cam, heli)
    local origin = GetCamCoord(cam)
    local hit, _, entity = raycast(origin, origin + rotToDirection(GetCamRot(cam, 2)) * maxTargetDistance, 10, heli)
    if hit and entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
        return entity
    end
end

---@param cam number
---@param heli number
local function updateUi(cam, heli)
    local rot = GetCamRot(cam, 2)
    local heliCoords = GetEntityCoords(heli)

    local heading = floor(360.0 - ((rot.z + 360.0) % 360.0) + 0.5)
    uiData.camZ = heading == 360 and 0 or heading
    uiData.heliZ = heliCoords.z
    uiData.latitude = toDms(heliCoords.x)
    uiData.longitude = toDms(heliCoords.y)
    uiData.heliSpeed = GetEntitySpeed(heli) * speedFactor

    local bearing = rot.z < 0 and -rot.z + abs(-rot.z - 180.0) * 2 or rot.z
    bearing = (bearing - 360) * -1
    local heliHeading = GetEntityHeading(heli) - rot.z
    if heliHeading > 360 then heliHeading = heliHeading - 360 end

    uiData.cameraPitch = sformat('%.0f', rot.x)
    uiData.cameraBearing = sformat('%.0f', bearing)
    uiData.heliHeading = sformat('%.0f', heliHeading)
end

local function syncMarkers()
    TriggerTokenEvent('sm_helicam:server:markers', markers)
end

local function toggleMarker()
    if not camActive or not camHandle then return end

    local origin = GetCamCoord(camHandle)
    local hit, coords = raycast(origin, origin + rotToDirection(GetCamRot(camHandle, 2)) * 424.0, -1, cache.vehicle or 0)
    if not hit then return end

    local point = vector3(coords.x, coords.y, coords.z + 0.25)
    local radius = markerCfg.circle.scale + 0.5
    for i = 1, #markers do
        if #(markers[i] - point) < radius then
            table.remove(markers, i)
            return syncMarkers()
        end
    end

    if #markers >= markerCfg.maxAmount then
        table.remove(markers, 1)
    end
    markers[#markers + 1] = point
    syncMarkers()
end

local function drawMarkers(heliCoords)
    local circle, number = markerCfg.circle, markerCfg.number
    local drawDistance = markerCfg.drawDistance
    for i = 1, #markers do
        local c = markers[i]
        if #(heliCoords - c) < drawDistance then
            DrawMarker(circle.type, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circle.scale, circle.scale, circle.scale, circle.r, circle.g, circle.b, circle.a, false, true, 2, false, nil, nil, false)
            if number.display then
                DrawMarker(i + 10, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, number.scale, number.scale, number.scale, number.r, number.g, number.b, number.a, false, true, 2, false, nil, nil, false)
            end
        end
    end
end

local function refreshMarkerBlips()
    local blipCfg = markerCfg.blip
    for i = #markerBlips, 1, -1 do
        RemoveBlip(markerBlips[i])
        markerBlips[i] = nil
    end
    if not blipCfg.display or not isPolice() then return end

    for i = 1, #markers do
        local c = markers[i]
        local blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(blip, blipCfg.sprite)
        SetBlipScale(blip, blipCfg.scale)
        SetBlipColour(blip, blipCfg.colour)
        if blipCfg.number then
            ShowNumberOnBlip(blip, i)
        end
        markerBlips[i] = blip
    end
end

---@param value any
---@return vector3[]
local function readMarkers(value)
    local list = {}
    if type(value) ~= 'table' then return list end
    for i = 1, #value do
        local c = value[i]
        local x, y, z = c and tonumber(c.x), c and tonumber(c.y), c and tonumber(c.z)
        if x and y and z then
            list[#list + 1] = vector3(x, y, z)
        end
    end
    return list
end

AddStateBagChangeHandler('helicamMarkers', 'global', function(_, _, value)
    markers = readMarkers(value)
    refreshMarkerBlips()
end)

CreateThread(function()
    markers = readMarkers(GlobalState.helicamMarkers)
    refreshMarkerBlips()
end)

---@param ped number
---@param heli number
local function runCamera(ped, heli)
    camActive = true
    playSelect()
    lib.notify({
        title = 'Helicam',
        description = 'E: tutup kamera | Klik kanan: mode visi | G: spotlight | Space: kunci target | Q: info kendaraan | Klik tengah: marker | Y/Panah bawah: terang | CapsLock/Shift: radius',
        duration = 6000,
    })

    interface.show()
    interface.send({ action = 'ui:setVisible', data = true })
    SetTimecycleModifier('heliGunCam')
    SetTimecycleModifierStrength(0.3)

    local cam = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)
    camHandle = cam
    AttachCamToEntity(cam, heli, 0.0, 0.0, -1.5, true)
    SetCamRot(cam, 0.0, 0.0, GetEntityHeading(heli), 2)
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, true, false)

    local lockedVehicle
    local modeBeforeManual = 'off'
    local nextUi, nextDecor = 0, 0

    Wait(0)

    local function step()
        local now = GetGameTimer()

        if IsDisabledControlJustPressed(0, keys.toggleCam) then
            playSelect()
            camActive = false
        end

        if IsDisabledControlJustPressed(0, keys.vision) then
            playSelect()
            changeVision()
        end

        if IsDisabledControlJustPressed(0, keys.spotlight) then
            playSelect()
            if spotMode == 'manual' then
                setSpot(modeBeforeManual == 'track' and targetVehicle and 'track' or 'off')
            else
                modeBeforeManual = spotMode
                setSpot('manual')
            end
        end

        if IsDisabledControlJustPressed(0, keys.lightUp) then
            TriggerTokenEvent('sm_helicam:server:adjust', 'brightness', 1)
        elseif IsDisabledControlJustPressed(0, keys.lightDown) then
            TriggerTokenEvent('sm_helicam:server:adjust', 'brightness', -1)
        end

        if IsDisabledControlJustPressed(0, keys.radiusUp) then
            TriggerTokenEvent('sm_helicam:server:adjust', 'radius', 1)
        elseif IsDisabledControlJustPressed(0, keys.radiusDown) then
            TriggerTokenEvent('sm_helicam:server:adjust', 'radius', -1)
        end

        if IsDisabledControlJustPressed(0, keys.display) then
            vehicleDisplay = vehicleDisplay == 0 and 1 or 0
            uiData.vehicle_display = vehicleDisplay
        end

        if lockedVehicle then
            local release = not DoesEntityExist(lockedVehicle)
                or IsDisabledControlJustPressed(0, keys.lockOn)
                or #(GetEntityCoords(heli) - GetEntityCoords(lockedVehicle)) > maxTargetDistance
                or not hasLineOfSight(cam, heli, lockedVehicle)

            if release then
                playSelect()
                lockedVehicle = nil
                releaseTarget()

                local rot = GetCamRot(cam, 2)
                local currentFov = GetCamFov(cam)
                local oldCam = cam
                cam = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)
                camHandle = cam
                AttachCamToEntity(cam, heli, 0.0, 0.0, -1.5, true)
                SetCamRot(cam, rot.x, rot.y, rot.z, 2)
                SetCamFov(cam, currentFov)
                RenderScriptCams(true, false, 0, true, false)
                DestroyCam(oldCam, false)
            else
                PointCamAtEntity(cam, lockedVehicle, 0.0, 0.0, 0.0, true)
                renderVehicleInfo(lockedVehicle)
                uiData.locked = true
            end
        else
            local zoomValue = (fov - fovMin) / (fovMax - fovMin)
            uiData.zoom_value = zoomValue
            rotateCam(cam, zoomValue)

            local detected = vehicleInView(cam, heli)
            if detected then
                renderVehicleInfo(detected)
                if IsDisabledControlJustPressed(0, keys.lockOn) then
                    playSelect()
                    lockedVehicle = detected
                    targetVehicle = detected
                    uiData.locked = true
                    if spotMode == 'track' then
                        setSpot('track', spotPaused)
                    end
                end
            end
        end

        handleZoom(cam)
        hideHud()
        drawMarkers(GetEntityCoords(heli))

        if spotMode == 'manual' then
            local direction = rotToDirection(GetCamRot(cam, 2))
            local origin = GetCamCoord(cam)
            local spot = LocalPlayer.state.heliSpot
            DrawSpotLight(origin.x, origin.y, origin.z, direction.x, direction.y, direction.z, 255, 255, 255, spotCfg.drawRange, 10.0,
                spot and spot.brightness or spotCfg.brightness.default, spot and spot.radius or spotCfg.radius.default, 1.0, 1.0)

            if now >= nextDecor then
                nextDecor = now + DECOR_INTERVAL_MS
                DecorSetFloat(ped, DECOR_X, direction.x)
                DecorSetFloat(ped, DECOR_Y, direction.y)
                DecorSetFloat(ped, DECOR_Z, direction.z)
            end
        end

        if now >= nextUi then
            nextUi = now + UI_INTERVAL_MS
            updateUi(cam, heli)
            interface.send({ action = 'ui:update', data = uiData })
        end

    end

    while camActive and not IsEntityDead(ped) and GetVehiclePedIsIn(ped, false) == heli and highEnough(heli) do
        local ok, err = xpcall(step, debug.traceback)
        if not ok then
            print(('^1[sm_helicam] %s^0'):format(err))
            camActive = false
        end
        Wait(0)
    end

    if spotMode == 'manual' then
        setSpot(targetVehicle and 'track' or 'off')
    end

    camActive = false
    camHandle = nil
    fov = (fovMax + fovMin) * 0.5
    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    SetNightvision(false)
    SetSeethrough(false)
    SeethroughSetMaxThickness(10000.0)
    visionState = 0
    uiData.vision_state = 0
    interface.send({ action = 'ui:setVisible', data = false })
    interface.hide()
end

local pilotLoop = false

---@param heli number
local function startPilotLoop(heli)
    if pilotLoop then return end
    pilotLoop = true

    CreateThread(function()
        while pilotLoop and cache.vehicle == heli and isPolice() do
            local ped = cache.ped
            local isDriver = GetPedInVehicleSeat(heli, -1) == ped

            if highEnough(heli) then
                if IsDisabledControlJustPressed(0, keys.toggleCam) then
                    runCamera(ped, heli)
                elseif IsDisabledControlJustPressed(0, keys.rappel) then
                    if GetPedInVehicleSeat(heli, 1) == ped or GetPedInVehicleSeat(heli, 2) == ped then
                        playSelect()
                        TaskRappelFromHeli(ped, 1)
                    else
                        lib.notify({ description = 'Tidak bisa rappel dari kursi ini', type = 'error' })
                    end
                end
            end

            if isDriver and IsDisabledControlJustPressed(0, keys.spotlight) then
                playSelect()
                if targetVehicle then
                    if spotMode == 'track' then
                        setSpot('track', not spotPaused)
                    else
                        setSpot('track')
                    end
                else
                    setSpot(spotMode == 'forward' and 'off' or 'forward')
                end
            end

            if targetVehicle and isDriver then
                if not DoesEntityExist(targetVehicle)
                    or IsDisabledControlJustPressed(0, keys.lockOn)
                    or #(GetEntityCoords(heli) - GetEntityCoords(targetVehicle)) > maxTargetDistance then
                    playSelect()
                    releaseTarget()
                end
            end

            if #markers > 0 then
                drawMarkers(GetEntityCoords(heli))
            end

            Wait(0)
        end

        pilotLoop = false
        targetVehicle = nil
        uiData.locked = false
        if spotMode ~= 'off' then
            setSpot('off')
        end
    end)
end

lib.onCache('vehicle', function(vehicle)
    if not vehicle then
        pilotLoop = false
        return
    end
    if heliModels[GetEntityModel(vehicle)] and isPolice() then
        SetTimeout(0, function()
            startPilotLoop(vehicle)
        end)
    end
end)

RegisterCommand('helicam_toggle_marker', function()
    if camActive and isPolice() then
        toggleMarker()
    end
end, false)
RegisterKeyMapping('helicam_toggle_marker', 'Helicam - Tambah/Hapus Marker', 'MOUSE_BUTTON', 'MOUSE_MIDDLE')

---@type table<number, table>
local remoteSpots = {}
local renderLoop = false

local function startRenderLoop()
    if renderLoop then return end
    renderLoop = true

    CreateThread(function()
        while next(remoteSpots) do
            local needFrame = false

            for serverId, spot in pairs(remoteSpots) do
                local player = GetPlayerFromServerId(serverId)
                local ped = player ~= -1 and GetPlayerPed(player) or 0
                local heli = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0

                if heli ~= 0 then
                    local mode = spot.mode
                    if mode == 'forward' then
                        if not spot.applied then
                            SetVehicleSearchlight(heli, true, false)
                            spot.applied = heli
                        end
                    elseif mode == 'track' and not spot.paused then
                        needFrame = true
                        local target = NetworkDoesNetworkIdExist(spot.target) and NetToVeh(spot.target) or 0
                        if target ~= 0 then
                            local from = GetEntityCoords(heli)
                            local delta = GetEntityCoords(target) - from
                            DrawSpotLight(from.x, from.y, from.z, delta.x, delta.y, delta.z, 255, 255, 255, #delta + 20.0, 10.0, spot.brightness, 4.0, 1.0, 0.0)
                        end
                    elseif mode == 'manual' and serverId ~= myServerId then
                        needFrame = true
                        local from = GetEntityCoords(heli)
                        DrawSpotLight(from.x, from.y, from.z - 1.5, DecorGetFloat(ped, DECOR_X), DecorGetFloat(ped, DECOR_Y), DecorGetFloat(ped, DECOR_Z),
                            255, 255, 255, spotCfg.drawRange, 10.0, spot.brightness, spot.radius, 1.0, 1.0)
                    end
                elseif spot.applied then
                    spot.applied = nil
                end
            end

            Wait(needFrame and 0 or 500)
        end
        renderLoop = false
    end)
end

AddStateBagChangeHandler('heliSpot', nil, function(bagName, _, value)
    local serverId = tonumber(bagName:match('^player:(%d+)$'))
    if not serverId then return end

    local previous = remoteSpots[serverId]
    if previous and previous.applied and (not value or value.mode ~= 'forward') then
        if DoesEntityExist(previous.applied) then
            SetVehicleSearchlight(previous.applied, false, false)
        end
    end

    if not value or value.mode == 'off' then
        remoteSpots[serverId] = nil
        return
    end

    remoteSpots[serverId] = {
        mode = value.mode,
        target = value.target,
        paused = value.paused,
        brightness = value.brightness or spotCfg.brightness.default,
        radius = value.radius or spotCfg.radius.default,
        applied = previous and value.mode == 'forward' and previous.applied or nil,
    }
    startRenderLoop()
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= cache.resource then return end
    if camActive then
        RenderScriptCams(false, false, 0, true, false)
        ClearTimecycleModifier()
        SetNightvision(false)
        SetSeethrough(false)
    end
    for i = 1, #markerBlips do
        RemoveBlip(markerBlips[i])
    end
end)
