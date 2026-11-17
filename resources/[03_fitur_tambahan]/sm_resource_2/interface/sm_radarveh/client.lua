local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'

interface.init(false)

local GetEntityCoords = GetEntityCoords
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetEntityHeading = GetEntityHeading
local GetEntitySpeed = GetEntitySpeed
local GetEntityVelocity = GetEntityVelocity
local GetEntityModel = GetEntityModel
local GetEntityPitch = GetEntityPitch
local GetModelDimensions = GetModelDimensions
local DoesEntityExist = DoesEntityExist
local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local IsThisModelABoat = IsThisModelABoat
local IsThisModelAHeli = IsThisModelAHeli
local IsThisModelAPlane = IsThisModelAPlane
local StartShapeTestCapsule = StartShapeTestCapsule
local GetShapeTestResult = GetShapeTestResult
local IsEntityAVehicle = IsEntityAVehicle
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetVehicleNumberPlateTextIndex = GetVehicleNumberPlateTextIndex
local DisableControlAction = DisableControlAction
local GetGamePool = GetGamePool
local Wait = Wait
local supper = string.upper
local ceil, max, abs = math.ceil, math.max, math.abs
local tremove = table.remove

local updateInterval = config.UpdateInterval or 200
local speedMultiplier = config.SpeedUnit == 'KMH' and 3.6 or 2.236936
local maxRange = config.MaxDetectionRange or 200.0
local maxRangeSqr = maxRange * maxRange
local plateRange = config.PlateDetectionRange or 50.0
local reopenAfterLeave = config.ReopenRadarAfterLeave
local notificationType = config.NotificationType
local showNotification = config.ShowNotification
local keybinds = config.Keybinds

local restrictModels = config.AllowedVehicleModels and config.AllowedVehicleModels.Enable
local allowedModels = {}
if restrictModels then
    local models = config.AllowedVehicleModels.Models
    for i = 1, #models do
        allowedModels[joaat(models[i])] = true
    end
end

local restrictJobs = config.AllowedJobs and config.AllowedJobs.Enable
local allowedJobs = {}
if restrictJobs then
    local jobs = config.AllowedJobs.Jobs
    for i = 1, #jobs do
        allowedJobs[jobs[i]] = true
    end
end

local state = {
    radarEnabled = false,
    radarWasEnabled = config.AutoEnable == true,
    interacting = false,
    inputActive = false,
    speedLockThreshold = 80,
    speedLockEnabled = false,
    lastFrontSpeed = 0,
    lastRearSpeed = 0,
    lastPatrolSpeed = 0,
    frontApproaching = false,
    rearApproaching = false,
}

local boloPlates = {}
local boloLookup = {}

local interactControls = { 1, 2, 24, 25, 68, 69, 70, 91, 92 }
local typingControls = {
    1, 2, 24, 25, 68, 69, 70, 91, 92, 30, 31, 32, 33, 34, 35,
    71, 72, 73, 74, 75, 76, 59, 60, 61, 62, 63, 64, 65,
    8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
    44, 45, 46, 47, 48, 49, 50, 51, 140, 141, 142, 143, 144,
    177, 178, 179, 180, 181, 199, 200, 201, 202, 203, 204, 322,
}
local scrollControls = { 14, 15, 81, 82, 99, 100, 115, 116, 261, 262 }

local rayOffsets = { 0.0, -5.0, 5.0, -10.0, -17.0 }
local rayCount = #rayOffsets

local modelValidity = {}
local modelSphere = {}
local vehiclePool = {}
local savedPositions

local radarThread, controlThread, poolThread, plateThread = false, false, false, false

local plateReader = {
    front = { plate = '', index = 0 },
    rear = { plate = '', index = 0 },
}

---@return boolean
local function hasAllowedJob()
    if not restrictJobs then return true end
    local job = QBPlayerData.job
    return job ~= nil and allowedJobs[job.name] == true
end

---@param vehicle number?
---@return boolean
local function isValidRadarVehicle(vehicle)
    if not vehicle or vehicle == 0 or not hasAllowedJob() then return false end
    return not restrictModels or allowedModels[GetEntityModel(vehicle)] == true
end

---@param vehicle number
---@return boolean
local function isModelValid(vehicle)
    local model = GetEntityModel(vehicle)
    local cached = modelValidity[model]
    if cached == nil then
        cached = not (IsThisModelABoat(model) or IsThisModelAHeli(model) or IsThisModelAPlane(model))
        modelValidity[model] = cached
    end
    return cached
end

---@param vehicle number
---@return number radius
---@return number size
local function sphereData(vehicle)
    local model = GetEntityModel(vehicle)
    local cached = modelSphere[model]
    if not cached then
        local minDim, maxDim = GetModelDimensions(model)
        local size = maxDim - minDim
        local total = size.x + size.y + size.z
        local radius = (total * total) / 12
        cached = { radius = radius < 5.0 and 5.0 or radius > 11.0 and 11.0 or radius, size = total }
        modelSphere[model] = cached
    end
    return cached.radius, cached.size
end

---@return boolean hit
---@return number relPos
local function rayHitsSphere(cx, cy, radius, sx, sy, ex, ey)
    local dx, dy = ex - sx, ey - sy
    local length = (dx * dx + dy * dy) ^ 0.5
    if length < 0.001 then return false, 0 end

    local nx, ny = dx / length, dy / length
    local tx, ty = cx - sx, cy - sy
    local projection = tx * nx + ty * ny
    local perpSqr = (tx * tx + ty * ty) - projection * projection
    local distToCenter = (tx * tx + ty * ty) ^ 0.5 - radius * 2

    if perpSqr < radius * radius and distToCenter <= length then
        if projection > 8.0 then return true, 1 end
        if projection < -8.0 then return true, -1 end
    end
    return false, 0
end

---@return boolean
local function isInTraffic(target, own, relPos)
    local diff = abs((GetEntityHeading(own) - GetEntityHeading(target) + 180) % 360 - 180)
    if relPos == 1 and diff > 45 and diff < 135 then return false end
    if relPos == -1 and diff > 45 and (diff < 135 or diff > 215) then return false end
    return true
end

---@return boolean
local function isApproaching(own, target)
    local ownPos, tarPos = GetEntityCoords(own), GetEntityCoords(target)
    local ownVel, tarVel = GetEntityVelocity(own), GetEntityVelocity(target)
    return (tarPos.x - ownPos.x) * (tarVel.x - ownVel.x) + (tarPos.y - ownPos.y) * (tarVel.y - ownVel.y) < 0
end

local function refreshVehiclePool()
    local all = GetGamePool('CVehicle')
    local pool, n = {}, 0
    for i = 1, #all do
        local vehicle = all[i]
        if isModelValid(vehicle) then
            n = n + 1
            pool[n] = vehicle
        end
    end
    vehiclePool = pool
end

local rayStarts, rayEnds = {}, {}

---@return table? front
---@return table? rear
local function detectSpeedTargets(own)
    local pitch = GetEntityPitch(own)
    if pitch <= -35 or pitch >= 35 then return nil, nil end

    local ownPos = GetEntityCoords(own)
    for i = 1, rayCount do
        rayStarts[i] = GetOffsetFromEntityInWorldCoords(own, rayOffsets[i], 0.0, 0.0)
        rayEnds[i] = GetOffsetFromEntityInWorldCoords(own, rayOffsets[i], maxRange, 0.0)
    end

    local front, rear
    local pool = vehiclePool
    for p = 1, #pool do
        local vehicle = pool[p]
        if vehicle ~= own and DoesEntityExist(vehicle) then
            local pos = GetEntityCoords(vehicle)
            local dx, dy, dz = pos.x - ownPos.x, pos.y - ownPos.y, pos.z - ownPos.z
            if dx * dx + dy * dy + dz * dz <= maxRangeSqr then
                local speed = GetEntitySpeed(vehicle)
                if speed > 0.1 and HasEntityClearLosToEntity(own, vehicle, 15) then
                    local radius, size = sphereData(vehicle)
                    for i = 1, rayCount do
                        local s, e = rayStarts[i], rayEnds[i]
                        local hit, relPos = rayHitsSphere(pos.x, pos.y, radius, s.x, s.y, e.x, e.y)
                        if hit and isInTraffic(vehicle, own, relPos) then
                            local best = relPos == 1 and front or rear
                            if not best or size > best.size then
                                local entry = { veh = vehicle, speed = ceil(speed * speedMultiplier), size = size }
                                if relPos == 1 then front = entry else rear = entry end
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    return front, rear
end

---@return number
local function vehicleInDirection(own, from, to)
    local handle = StartShapeTestCapsule(from.x, from.y, from.z, to.x, to.y, to.z, 2.0, 2, own, 7)
    local status, hit, _, _, vehicle = GetShapeTestResult(handle)
    local frames = 0

    while status == 1 and frames < 10 do
        Wait(0)
        frames = frames + 1
        status, hit, _, _, vehicle = GetShapeTestResult(handle)
    end

    if status ~= 2 or not hit or hit == 0 then return 0 end

    return vehicle
end

local function updatePlateReader(own)
    local ownHeading = GetEntityHeading(own)
    local minDim, maxDim = GetModelDimensions(GetEntityModel(own))

    for i = 1, -1, -2 do
        local camName = i == 1 and 'front' or 'rear'
        local reader = plateReader[camName]
        local edge = i == 1 and maxDim.y + 0.5 or minDim.y - 0.5
        local from = GetOffsetFromEntityInWorldCoords(own, 0.0, edge, 0.0)
        local to = GetOffsetFromEntityInWorldCoords(own, 0.0, plateRange * i, 0.0)
        local vehicle = vehicleInDirection(own, from, to)

        if vehicle ~= 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
            local diff = abs((ownHeading - GetEntityHeading(vehicle) + 180) % 360 - 180)
            if diff < 45 or diff > 135 then
                local plate = GetVehicleNumberPlateText(vehicle) or ''
                if reader.plate ~= plate then
                    local index = GetVehicleNumberPlateTextIndex(vehicle) or 0
                    reader.plate, reader.index = plate, index
                    interface.send({ type = 'plateUpdate', cam = camName, plate = plate, plateIndex = index })

                    if plate ~= '' then
                        TriggerEvent('sm_radarveh:onPlateScanned', { plate = plate, plateIndex = index, direction = camName, vehicle = vehicle })
                    end
                end
            end
        end
    end
end

---@param msg table
local function sendIfEnabled(msg)
    if state.radarEnabled then
        interface.send(msg)
    end
end

local function loadSavedPositions()
    if savedPositions == nil then
        local raw = GetResourceKvpString('radar_positions')
        savedPositions = raw and json.decode(raw) or false
    end
    return savedPositions or nil
end

local function sendBolo()
    interface.send({ type = 'updateBoloPlates', plates = boloPlates })
end

local mounted = false

local function openUi()
    if not mounted then
        mounted = true
        interface.show()
    end
    interface.send({ type = 'open' })
    interface.send({ type = 'setKeybinds', keybinds = keybinds })
    interface.send({ type = 'setNotificationType', notificationType = notificationType })
    interface.send({ type = 'setSpeedUnit', speedUnit = config.SpeedUnit })
    interface.send({ type = 'setLedGlow', ledGlow = config.LedGlow ~= false })

    local saved = loadSavedPositions()
    if saved then
        interface.send({ type = 'loadPositions', positions = saved })
    end
    if #boloPlates > 0 then
        sendBolo()
    end
end

local function closeUi()
    state.interacting = false
    state.inputActive = false
    interface.focus(false, false, false)
    interface.send({ type = 'close' })
end

local function disableControls(list)
    for i = 1, #list do
        DisableControlAction(0, list[i], true)
    end
    for group = 0, 2 do
        for i = 1, #scrollControls do
            DisableControlAction(group, scrollControls[i], true)
        end
    end
end

local function startControlThread()
    if controlThread then return end
    controlThread = true
    CreateThread(function()
        while state.inputActive or state.interacting do
            disableControls(state.inputActive and typingControls or interactControls)
            Wait(0)
        end
        controlThread = false
    end)
end

local function doRadarUpdate(vehicle)
    local front, rear = detectSpeedTargets(vehicle)
    local fSpeed = front and front.speed or 0
    local rSpeed = rear and rear.speed or 0
    local fApproaching = front and isApproaching(vehicle, front.veh) or false
    local rApproaching = rear and isApproaching(vehicle, rear.veh) or false
    local patrolSpeed = ceil(GetEntitySpeed(vehicle) * speedMultiplier)

    if fSpeed ~= state.lastFrontSpeed or rSpeed ~= state.lastRearSpeed or patrolSpeed ~= state.lastPatrolSpeed
        or fApproaching ~= state.frontApproaching or rApproaching ~= state.rearApproaching then
        interface.send({
            type = 'update',
            frontSpeed = fSpeed,
            rearSpeed = rSpeed,
            patrolSpeed = patrolSpeed,
            frontApproaching = fApproaching,
            rearApproaching = rApproaching,
        })
        state.lastFrontSpeed, state.lastRearSpeed, state.lastPatrolSpeed = fSpeed, rSpeed, patrolSpeed
        state.frontApproaching, state.rearApproaching = fApproaching, rApproaching
    end

    local threshold = state.speedLockThreshold
    if state.speedLockEnabled and (fSpeed >= threshold or rSpeed >= threshold) then
        local frontTriggered = fSpeed >= threshold
        interface.send({
            type = 'speedLockTriggered',
            speed = max(fSpeed, rSpeed),
            plate = frontTriggered and plateReader.front.plate or plateReader.rear.plate,
            direction = frontTriggered and 'Front' or 'Rear',
        })
        state.speedLockEnabled = false
    end
end

local function startThreads()
    if not poolThread then
        poolThread = true
        CreateThread(function()
            while state.radarEnabled do
                refreshVehiclePool()
                Wait(3000)
            end
            poolThread = false
        end)
    end

    if not plateThread then
        plateThread = true
        CreateThread(function()
            while state.radarEnabled do
                local vehicle = cache.vehicle
                if vehicle then
                    updatePlateReader(vehicle)
                end
                Wait(500)
            end
            plateThread = false
        end)
    end

    if not radarThread then
        radarThread = true
        CreateThread(function()
            while state.radarEnabled do
                local vehicle = cache.vehicle
                if vehicle then
                    doRadarUpdate(vehicle)
                    Wait(GetEntitySpeed(vehicle) < 0.1 and 200 or updateInterval)
                else
                    Wait(200)
                end
            end
            radarThread = false
        end)
    end
end

local function enableRadar()
    state.radarEnabled = true
    state.radarWasEnabled = false
    openUi()
    startThreads()
end

---@param remember boolean
local function disableRadar(remember)
    if remember and reopenAfterLeave then
        state.radarWasEnabled = true
    end
    state.radarEnabled = false
    closeUi()
end

local function toggleRadar()
    if not isValidRadarVehicle(cache.vehicle) then return end
    if state.radarEnabled then
        disableRadar(false)
    else
        enableRadar()
    end
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    if state.radarEnabled and not hasAllowedJob() then
        disableRadar(true)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if state.radarEnabled then
        disableRadar(true)
    end
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle then
        if state.radarWasEnabled and not state.radarEnabled and isValidRadarVehicle(vehicle) then
            enableRadar()
        end
    elseif state.radarEnabled then
        disableRadar(true)
    end
end)

---@param name string
---@param key string?
---@param label string
local function bindKey(name, key, label)
    if key and key:match('%S') then
        RegisterKeyMapping(name, label, 'keyboard', key)
        local hash = joaat('+' .. name)
        interactControls[#interactControls + 1] = hash
        typingControls[#typingControls + 1] = hash
    end
end

RegisterCommand('radar', toggleRadar, false)
if keybinds.ToggleRadar and keybinds.ToggleRadar:match('%S') then
    RegisterKeyMapping('radar', 'Toggle Radar', 'keyboard', keybinds.ToggleRadar)
end

RegisterCommand('radarInteract', function()
    if not state.radarEnabled then return end
    state.interacting = not state.interacting
    interface.focus(state.interacting, state.interacting, state.interacting)
    if state.interacting then
        startControlThread()
    end
end, false)
if keybinds.Interact and keybinds.Interact:match('%S') then
    RegisterKeyMapping('radarInteract', 'Interact with Radar UI', 'keyboard', keybinds.Interact)
end

local simpleCommands = {
    radarSave = { keybinds.SaveReading, 'Save Radar Reading', 'saveReading' },
    radarLock = { keybinds.LockRadar, 'Toggle Radar Lock', 'toggleLock' },
    radarLockSpeed = { keybinds.LockSpeed, 'Lock/Unlock Speed', 'toggleSpeedLock' },
    radarLockPlate = { keybinds.LockPlate, 'Lock/Unlock Plates', 'togglePlateLock' },
    radarToggleLog = { keybinds.ToggleLog, 'Toggle Radar Log', 'toggleLog' },
    radarToggleBolo = { keybinds.ToggleBolo, 'Toggle BOLO List', 'toggleBolo' },
    radarToggleKeybinds = { keybinds.ToggleKeybinds, 'Toggle Radar Keybinds', 'toggleKeybinds' },
    radarSpeedLockThreshold = { keybinds.SpeedLockThreshold, 'Open Speed Lock Threshold Menu', 'openSpeedLockModal' },
}

for name, info in pairs(simpleCommands) do
    local msg = { type = info[3] }
    RegisterCommand(name, function() sendIfEnabled(msg) end, false)
    bindKey(name, info[1], info[2])
end

local moveCommands = {
    radarMoveRadar = { keybinds.MoveRadar, 'Move Radar Panel', 'togglePositionRadar' },
    radarMoveLog = { keybinds.MoveLog, 'Move Log Panel', 'togglePositionLog' },
    radarMoveBolo = { keybinds.MoveBolo, 'Move BOLO Panel', 'togglePositionBolo' },
}

for name, info in pairs(moveCommands) do
    local msg = { type = info[3] }
    RegisterCommand(name, function()
        if not state.radarEnabled then return end
        if not state.interacting then
            state.interacting = true
            interface.focus(true, true, true)
            startControlThread()
        end
        interface.send(msg)
    end, false)
    bindKey(name, info[1], info[2])
end

---@param plate string
---@return boolean
local function addBoloPlate(plate)
    if type(plate) ~= 'string' or plate == '' then return false end
    local upper = supper(plate)
    if boloLookup[upper] then return false end
    boloPlates[#boloPlates + 1] = upper
    boloLookup[upper] = true
    if state.radarEnabled then sendBolo() end
    return true
end

---@param plate string
---@return boolean
local function removeBoloPlate(plate)
    if type(plate) ~= 'string' or plate == '' then return false end
    local upper = supper(plate)
    if not boloLookup[upper] then return false end
    for i = 1, #boloPlates do
        if boloPlates[i] == upper then
            tremove(boloPlates, i)
            break
        end
    end
    boloLookup[upper] = nil
    if state.radarEnabled then sendBolo() end
    return true
end

interface.callback('setSpeedLockThreshold', function(data, cb)
    state.speedLockThreshold = tonumber(data.threshold) or state.speedLockThreshold
    state.speedLockEnabled = data.enabled == true
    if notificationType == 'custom' and data.threshold then
        showNotification(('Speed lock threshold set to %s'):format(data.threshold))
    end
    cb({})
end)

interface.callback('addBoloPlate', function(data, cb)
    addBoloPlate(data.plate)
    cb({})
end)

interface.callback('removeBoloPlate', function(data, cb)
    removeBoloPlate(data.plate)
    cb({})
end)

interface.callback('boloAlert', function(_, cb)
    PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', true)
    cb({})
end)

interface.callback('showNotification', function(data, cb)
    if notificationType == 'custom' and data.message then
        showNotification(data.message)
    end
    cb({})
end)

interface.callback('savePositions', function(data, cb)
    if type(data) == 'table' then
        local current = loadSavedPositions() or {}
        for k, v in pairs(data) do
            current[k] = v
        end
        savedPositions = current
        SetResourceKvp('radar_positions', json.encode(current))
    end
    cb({})
end)

interface.callback('inputActive', function(_, cb)
    state.inputActive = true
    interface.focus(true, true, false)
    startControlThread()
    cb({})
end)

interface.callback('inputInactive', function(_, cb)
    state.inputActive = false
    if state.radarEnabled then
        interface.focus(state.interacting, state.interacting, state.interacting)
    else
        interface.focus(false, false, false)
    end
    cb({})
end)

CreateThread(function()
    Wait(500)
    if state.radarWasEnabled and isValidRadarVehicle(cache.vehicle) then
        enableRadar()
    end
end)

local function getBoloPlates() return boloPlates end
local function isRadarEnabled() return state.radarEnabled end

exports('addBoloPlate', addBoloPlate)
exports('removeBoloPlate', removeBoloPlate)
exports('getBoloPlates', getBoloPlates)
exports('isRadarEnabled', isRadarEnabled)
exports('toggleRadar', toggleRadar)

exportWrapper('sm_radarveh', 'addBoloPlate', addBoloPlate)
exportWrapper('sm_radarveh', 'removeBoloPlate', removeBoloPlate)
exportWrapper('sm_radarveh', 'getBoloPlates', getBoloPlates)
exportWrapper('sm_radarveh', 'isRadarEnabled', isRadarEnabled)
exportWrapper('sm_radarveh', 'toggleRadar', toggleRadar)
