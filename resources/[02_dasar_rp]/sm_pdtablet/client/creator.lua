local trackCfg = Config.Track
local keys = Config.Keys
local propCfg = Config.Props
local blipCfg = Config.Blips
local markerCfg = Config.Marker
local gateCfg = Config.GateMarker
local airCfg = Config.AirTrack

local markerColor = markerCfg.color
local distanceColor = markerCfg.distanceColor
local primaryColor = markerCfg.primaryColor

local min, max, floor = math.min, math.max, math.floor

local checkpointModel = joaat(propCfg.checkpoint)
local startFinishModel = joaat(propCfg.startFinish)

local format = string.format

Creator = {
    active = false,
    name = nil,
    trackId = nil,
    trackType = 'ground',
    checkpoints = {},
    tireDistance = trackCfg.defaultTireDistance,
    radius = airCfg.defaultRadius,
    closest = 0,
    confirmExit = false,
}

local function isAirTrack()
    return Creator.trackType == 'air'
end

local props = {}

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
---@return number|nil
local function spawnProp(coords, model)
    if not loadModel(model) then return end

    local object = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    PlaceObjectOnGroundProperly(object)
    FreezeEntityPosition(object, true)
    SetEntityCollision(object, false, false)
    props[#props + 1] = object

    return object
end

local function clearProps()
    for i = 1, #props do
        local object = props[i]
        if DoesEntityExist(object) then DeleteObject(object) end
    end
    props = {}
end

---@param coords table
---@param id number
---@return number
local function createBlip(coords, id)
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

    return blip
end

local function clearBlips()
    local checkpoints = Creator.checkpoints
    for i = 1, #checkpoints do
        local blip = checkpoints[i].blip
        if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end

local function redrawBlips()
    local checkpoints = Creator.checkpoints
    for i = 1, #checkpoints do
        local checkpoint = checkpoints[i]
        if checkpoint.blip and DoesBlipExist(checkpoint.blip) then RemoveBlip(checkpoint.blip) end
        checkpoint.blip = createBlip(checkpoint.coords, i)
    end
end

local function refreshProps()
    clearProps()

    if isAirTrack() then return end

    local checkpoints = Creator.checkpoints
    local total = #checkpoints

    for i = 1, total do
        local checkpoint = checkpoints[i]
        local model = (i == 1 or i == total) and startFinishModel or checkpointModel
        spawnProp(checkpoint.offset.left, model)
        spawnProp(checkpoint.offset.right, model)
    end
end

---@param vehicle number
---@return table
local function getOffsets(vehicle)
    local distance = Creator.tireDistance
    local left = GetOffsetFromEntityInWorldCoords(vehicle, -distance, 0.0, 0.0)
    local right = GetOffsetFromEntityInWorldCoords(vehicle, distance, 0.0, 0.0)

    return {
        left = { x = left.x, y = left.y, z = left.z },
        right = { x = right.x, y = right.y, z = right.z },
    }
end

local function addCheckpoint()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        Notify('You must be inside a vehicle.', 'error')
        return
    end

    local checkpoints = Creator.checkpoints
    if trackCfg.maxCheckpoints > 0 and #checkpoints >= trackCfg.maxCheckpoints then
        Notify(format('Maximum %d checkpoints.', trackCfg.maxCheckpoints), 'error')
        return
    end

    local coords = GetEntityCoords(ped)

    if isAirTrack() then
        if airCfg.minAltitude > 0 then
            if GetEntityHeightAboveGround(vehicle) < airCfg.minAltitude then
                Notify(format('Fly at least %dm above ground.', airCfg.minAltitude), 'error')
                return
            end
        end

        checkpoints[#checkpoints + 1] = {
            coords = { x = coords.x, y = coords.y, z = coords.z },
            radius = Creator.radius,
        }
    else
        checkpoints[#checkpoints + 1] = {
            coords = { x = coords.x, y = coords.y, z = coords.z },
            offset = getOffsets(vehicle),
        }
    end

    redrawBlips()
    refreshProps()
end

local function deleteClosestCheckpoint()
    local checkpoints = Creator.checkpoints
    local index = Creator.closest

    if index == 0 or not checkpoints[index] then
        Notify('No checkpoint nearby.', 'error')
        return
    end

    local blip = checkpoints[index].blip
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end

    table.remove(checkpoints, index)
    Creator.closest = 0

    redrawBlips()
    refreshProps()
end

local function findClosest()
    local checkpoints = Creator.checkpoints
    local total = #checkpoints
    if total == 0 then
        Creator.closest = 0
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    local closest, shortest = 0, nil

    for i = 1, total do
        local point = checkpoints[i].coords
        local distance = #(coords - vec3(point.x, point.y, point.z))
        if not shortest or distance < shortest then
            shortest = distance
            closest = i
        end
    end

    Creator.closest = closest
end

local function stopCreator()
    clearBlips()
    clearProps()

    Creator.active = false
    Creator.name = nil
    Creator.trackId = nil
    Creator.checkpoints = {}
    Creator.closest = 0
    Creator.confirmExit = false

    SendNUIMessage({ action = 'creator', active = false })
end

local function saveTrack()
    local checkpoints = Creator.checkpoints
    if #checkpoints < trackCfg.minCheckpoints then
        Notify(format('Minimum %d checkpoints required.', trackCfg.minCheckpoints), 'error')
        return
    end

    local payload = {}
    for i = 1, #checkpoints do
        payload[i] = {
            coords = checkpoints[i].coords,
            offset = checkpoints[i].offset,
            radius = checkpoints[i].radius,
        }
    end

    TriggerTokenEvent('sm_pdtablet:server:saveTrack', {
        Name = Creator.name,
        TrackId = Creator.trackId,
        Checkpoints = payload,
    })

    stopCreator()
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

local function drawCheckpointMarkers()
    local checkpoints = Creator.checkpoints
    local total = #checkpoints
    if total == 0 then return end

    local coords = GetEntityCoords(PlayerPedId())
    local baseSize = markerCfg.baseSize
    local closest = Creator.closest

    for i = 1, total do
        local point = checkpoints[i].coords
        local distance = #(coords - vec3(point.x, point.y, point.z))

        if distance <= trackCfg.markerRenderDistance then
            local isClosest = i == closest
            local label = i == 1 and 'START' or (i == total and 'FINISH' or ('CP ' .. i))
            local top

            if isAirTrack() then
                local radius = checkpoints[i].radius or airCfg.defaultRadius
                local color = isClosest and airCfg.marker.nextColor or airCfg.marker.color

                DrawMarker(airCfg.marker.type, point.x, point.y, point.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    radius, radius, radius, color.r, color.g, color.b, color.a,
                    false, false, 2, false, nil, nil, false)

                top = point.z + radius
            else
                local height = min(markerCfg.maxHeight, max(markerCfg.minHeight, distance / 2.5))
                local alpha = isClosest and markerColor.a or floor(markerColor.a * 0.5)

                DrawMarker(markerCfg.type, point.x, point.y, point.z,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    baseSize, baseSize, height,
                    markerColor.r, markerColor.g, markerColor.b, alpha,
                    false, true, 2, false, nil, nil, false)

                top = point.z + height
            end

            draw3DText(vec3(point.x, point.y, top + 1.2), label, 0.25,
                isClosest and primaryColor or distanceColor)

            draw3DText(vec3(point.x, point.y, top + 0.5),
                format('%.0fm', distance), 0.5, distanceColor)
        end
    end
end

---@param vehicle number
local function drawAirPreview(vehicle)
    local coords = GetEntityCoords(vehicle)
    local radius = Creator.radius
    local color = airCfg.marker.nextColor

    DrawMarker(airCfg.marker.type, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        radius, radius, radius, color.r, color.g, color.b, color.a,
        false, false, 2, false, nil, nil, false)

    local altitude = GetEntityHeightAboveGround(vehicle)
    local ok = altitude >= airCfg.minAltitude

    draw3DText(vec3(coords.x, coords.y, coords.z + radius + 3.0),
        format('RADIUS %.0fm', radius), 0.4, primaryColor)

    draw3DText(vec3(coords.x, coords.y, coords.z + radius + 1.8),
        format('ALT %.0fm%s', altitude, ok and '' or ' (TOO LOW)'),
        0.35, ok and distanceColor or { r = 200, g = 80, b = 60, a = 255 })
end

---@param vehicle number
local function drawGatePreview(vehicle)
    local offsets = getOffsets(vehicle)
    local left = offsets.left
    local right = offsets.right
    local gate = gateCfg

    DrawMarker(gate.type, left.x, left.y, left.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        gate.scale.x, gate.scale.y, gate.scale.z,
        gate.color.r, gate.color.g, gate.color.b, gate.color.a,
        false, true, 0, false, nil, nil, false)

    DrawMarker(gate.type, right.x, right.y, right.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        gate.scale.x, gate.scale.y, gate.scale.z,
        gate.color.r, gate.color.g, gate.color.b, gate.color.a,
        false, true, 0, false, nil, nil, false)
end

local function creatorThread()
    CreateThread(function()
        while Creator.active do
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            drawCheckpointMarkers()

            if vehicle ~= 0 then
                if isAirTrack() then
                    drawAirPreview(vehicle)
                else
                    drawGatePreview(vehicle)
                end
            end

            if IsControlJustPressed(0, keys.addCheckpoint) then addCheckpoint() end
            if IsControlJustPressed(0, keys.deleteCheckpoint) then deleteClosestCheckpoint() end
            if IsControlJustPressed(0, keys.saveTrack) then saveTrack() end

            if IsControlJustPressed(0, keys.increaseDistance) or IsControlJustPressed(0, keys.increaseAlt) then
                if isAirTrack() then
                    Creator.radius = min(airCfg.maxRadius, Creator.radius + airCfg.radiusStep)
                elseif Creator.tireDistance < trackCfg.maxTireDistance then
                    Creator.tireDistance = Creator.tireDistance + 1.0
                    refreshProps()
                end
            end

            if IsControlJustPressed(0, keys.decreaseDistance) or IsControlJustPressed(0, keys.decreaseAlt) then
                if isAirTrack() then
                    Creator.radius = max(airCfg.minRadius, Creator.radius - airCfg.radiusStep)
                elseif Creator.tireDistance > trackCfg.minTireDistance then
                    Creator.tireDistance = Creator.tireDistance - 1.0
                    refreshProps()
                end
            end

            if IsControlJustPressed(0, keys.exit) then
                if Creator.confirmExit then
                    Notify('Track creation cancelled.', 'error')
                    stopCreator()
                else
                    Creator.confirmExit = true
                    Notify('Press again to cancel this track.', 'error')
                    SetTimeout(4000, function() Creator.confirmExit = false end)
                end
            end

            Wait(0)
        end
    end)

    CreateThread(function()
        while Creator.active do
            findClosest()

            SendNUIMessage({
                action = 'creator',
                active = true,
                data = {
                    name = Creator.name,
                    trackType = Creator.trackType,
                    checkpoints = #Creator.checkpoints,
                    minCheckpoints = trackCfg.minCheckpoints,
                    tireDistance = Creator.tireDistance,
                    radius = Creator.radius,
                    closest = Creator.closest,
                    isEdit = Creator.trackId ~= nil,
                    keys = Config.KeyLabels,
                },
            })

            Wait(250)
        end
    end)
end

---@param name string
---@param trackId string|nil
---@param existing table|nil
function StartCreator(name, trackId, existing, trackType)
    if Creator.active then
        Notify('You are already building a track.', 'error')
        return
    end

    Creator.active = true
    Creator.name = name
    Creator.trackId = trackId
    Creator.trackType = trackType or 'ground'
    Creator.checkpoints = {}
    Creator.tireDistance = trackCfg.defaultTireDistance
    Creator.radius = airCfg.defaultRadius
    Creator.confirmExit = false

    if existing then
        for i = 1, #existing do
            Creator.checkpoints[i] = {
                coords = existing[i].coords,
                offset = existing[i].offset,
                radius = existing[i].radius,
            }
        end
        redrawBlips()
        refreshProps()
    end

    if isAirTrack() then
        Notify(format('Air track editor active. Fly above %dm and press E at each point.', airCfg.minAltitude), 'inform')
    else
        Notify('Track editor active. Get in a vehicle and press E at each point.', 'inform')
    end

    creatorThread()
end

function IsCreatorActive()
    return Creator.active
end

function CancelCreator()
    if not Creator.active then return end

    stopCreator()
    Notify('Track creation cancelled.', 'error')
end

function SaveCreatorTrack()
    if not Creator.active then return end
    saveTrack()
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearBlips()
    clearProps()
end)
