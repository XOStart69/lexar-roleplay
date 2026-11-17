local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local Nui = require 'pelumber.modules.client.nui'
local utils = require 'modules.utils'

local Minigame = {}

local PLUNGER_MODEL = 'tw_plunger'
local REQUIRED_PUMPS = 50

---@class TaskHandler
---@field setup fun(mission: ClientMission)
---@field teardown fun()
---@field onObjectDone? fun(objId: string)
---@field onValveState? fun(objId: string, state: string)
---@field onPipeRemoved? fun(objId: string)
---@field onProcessing? fun(objId: string, src: number|false)

---@type table<string, TaskHandler>
local handlers = {}

---@type TaskHandler?
local activeHandler = nil

---@type string?
local activeKind = nil

---@param kind string
---@param handler TaskHandler
function Minigame.registerTask(kind, handler)
    handlers[kind] = handler
end

function Minigame.setupCurrentTask()
    if not State.mission then return end
    local kind = State.currentTask()
    if not kind then return end

    local handler = handlers[kind]
    if not handler then
        lib.print.warn(('Tidak ada handler untuk task "%s"'):format(kind))
        return
    end

    activeHandler = handler
    activeKind = kind
    handler.setup(State.mission)
end

function Minigame.teardownCurrentTask()
    if activeHandler and activeHandler.teardown then
        activeHandler.teardown()
    end
    activeHandler = nil
    activeKind = nil
end

---@param objId string
function Minigame.onObjectDone(objId)
    if activeHandler and activeHandler.onObjectDone then
        activeHandler.onObjectDone(objId)
    end
end

---@param objId string
---@param state string
function Minigame.onValveState(objId, state)
    if activeHandler and activeHandler.onValveState then
        activeHandler.onValveState(objId, state)
    end
end

---@param objId string
function Minigame.onPipeRemoved(objId)
    if activeHandler and activeHandler.onPipeRemoved then
        activeHandler.onPipeRemoved(objId)
    end
end

---@param objId string
---@param src number|false
function Minigame.onProcessing(objId, src)
    if activeHandler and activeHandler.onProcessing then
        activeHandler.onProcessing(objId, src)
    end
end

---@return string?
function Minigame.currentKind()
    return activeKind
end

---@param objId string
---@return boolean success
function Minigame.valveGame(objId)
    return Nui.runNuiMinigame('OPEN_VALVE_GAME', objId)
end

---@param objId string
---@return boolean success
function Minigame.switchGame(objId)
    return Nui.runNuiMinigame('OPEN_SWITCH_GAME', { id = objId })
end

local pipeActive = false

function Minigame.stopPipe()
    pipeActive = false
end

---@param mode 'open'|'close'
---@param entity number
---@param objId string
---@param totalNeeded? number
---@return boolean success
function Minigame.pipeGame(mode, entity, objId, totalNeeded)
    if pipeActive then return false end
    if not entity or not DoesEntityExist(entity) then return false end

    pipeActive = true

    local coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, -1.0, 0.0)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    if not DoesCamExist(cam) then
        pipeActive = false
        return false
    end

    PointCamAtEntity(cam, entity, 0.0, 0.0, 0.0, true)
    SetCamCoord(cam, coords.x, coords.y, coords.z)
    RenderScriptCams(true, true, 500, false, false)

    Nui.send('OPEN_PIPE_GAME', { mode = mode, id = objId })
    Nui.send('SET_PIPE_PRESSURE', { pressure = 0 })

    local screenX, screenY = GetActiveScreenResolution()
    local objRot = GetEntityRotation(entity)
    local startRotation = objRot.y
    local rotation = startRotation
    local rotationMult = 7.0 * 75
    local isClosing = mode == 'close'
    totalNeeded = totalNeeded or (isClosing and 720.0 or 360.0)
    local isStuck = false
    local stuckDuration = 0
    local nextStuckCheck = 0
    local success = false

    while pipeActive do
        if not DoesEntityExist(entity) then break end
        if not State.mission then break end

        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        SetMouseCursorActiveThisFrame()
        SetEntityLocallyInvisible(cache.ped)

        if IsDisabledControlJustPressed(0, 200) then
            break
        end

        if IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24) then
            SetMouseCursorSprite(4)
            local right = GetControlNormal(0, 1)
            local down = GetControlNormal(0, 2)
            local x, y = GetNuiCursorPosition()

            nextStuckCheck = nextStuckCheck - 1
            if nextStuckCheck <= 0 then
                nextStuckCheck = math.random(30, 60)
                if math.random() < 0.2 and not isStuck then
                    isStuck = true
                    stuckDuration = math.random(40, 90)
                end
            end
            if isStuck then
                stuckDuration = stuckDuration - 1
                if stuckDuration <= 0 then isStuck = false end
            end

            local mult = isStuck and rotationMult * 0.05 or rotationMult
            local old = rotation

            if x > screenX / 2 then
                if y > screenY / 2 then
                    rotation = rotation - (right - down) * mult * GetFrameTime()
                else
                    rotation = rotation - (-right - down) * mult * GetFrameTime()
                end
            else
                if y > screenY / 2 then
                    rotation = rotation - (right + down) * mult * GetFrameTime()
                else
                    rotation = rotation - (-right + down) * mult * GetFrameTime()
                end
            end

            local delta = math.abs(rotation - old)
            if isStuck then
                delta = delta * 0.1
                if math.random() < 0.05 and delta > 0.005 then isStuck = false end
            end

            SetEntityRotation(entity, objRot.x, rotation, objRot.z, 0, false)

            local signed = rotation - startRotation
            if isClosing then signed = -signed end
            local progress = math.max(0.0, math.min(1.0, signed / totalNeeded))
            local pressure = progress * 100.0

            Nui.send('SET_PIPE_PRESSURE', { pressure = pressure })

            if math.abs(startRotation - rotation) > 45 and math.floor(rotation) % 25 == 0 then
                Util.loadParticleLib('core')
                StartParticleFxNonLoopedOnEntity('bul_decal_water_heli', entity, 0.0, -0.2, 0.0, 0.0, math.random(-90, 90) + 0.0, 0.0, 0.3, false, false, false)
            end

            if pressure >= 75.0 then
                Nui.send('SET_PIPE_PRESSURE', { pressure = 78.0 })
                success = true
                break
            end
        else
            SetMouseCursorSprite(3)
        end

        Wait(0)
    end

    Nui.send('CLOSE_PIPE_GAME')
    RenderScriptCams(false, true, 500, true, false)
    DestroyCam(cam, false)
    pipeActive = false
    return success
end

local toiletActive = false

function Minigame.stopToilet()
    toiletActive = false
end

---@param coords vector3
---@param heading number
---@param offset { x: number, y: number, z: number }
---@return vector3
local function rotatedOffset(coords, heading, offset)
    local rad = math.rad(heading)
    local rx = offset.x * math.cos(rad) - offset.y * math.sin(rad)
    local ry = offset.x * math.sin(rad) + offset.y * math.cos(rad)
    return vector3(coords.x + rx, coords.y + ry, coords.z + offset.z)
end

---@param toiletData { coords: vector3, heading: number, shitProps: table[], waterProp: table, plungerOffset: vector3 }
---@return boolean success
function Minigame.toilet(toiletData)
    if toiletActive then return false end

    local toiletOffsets = State.offsets.toilet
    local coords = toiletData.coords
    local heading = toiletData.heading or 0.0

    local restoreCoords = GetEntityCoords(cache.ped)
    local restoreHeading = GetEntityHeading(cache.ped)

    local plungerModel = utils.waitForModel(PLUNGER_MODEL)
    if not plungerModel then
        lib.print.warn('PELUMBER: Failed to load plunger model, contact server developer to fix this issue.')
        return Util.progress('Membersihkan toilet...', 8000, {
            dict = 'anim@amb@business@coc@coc_unpack_cut@',
            clip = 'fullcut_cycle_v6_cokecutter',
            flag = 49,
        })
    end

    toiletActive = true

    local playerPos = rotatedOffset(coords, heading, toiletOffsets.playerOffset)
    SetEntityCoords(cache.ped, playerPos.x, playerPos.y, playerPos.z, true, false, false, true)
    SetEntityHeading(cache.ped, heading)

    local props = {}
    local shitProps = {}

    local plungerPos = rotatedOffset(coords, heading, toiletData.plungerOffset or toiletOffsets.playerOffset)
    local plunger = utils.createProp(PLUNGER_MODEL, plungerPos, false)
    if not plunger then
        toiletActive = false
        return false
    end
    FreezeEntityPosition(plunger, true)
    SetEntityHeading(plunger, heading)
    props[#props + 1] = plunger

    for i = 1, #toiletData.shitProps do
        local info = toiletData.shitProps[i]
        local off = toiletOffsets.shitOffsets[i] or toiletOffsets.shitOffsets[1]
        local pos = rotatedOffset(coords, heading, off)
        local shit = utils.createProp(info.prop, pos, false)
        if shit then
            FreezeEntityPosition(shit, true)
            SetEntityRotation(shit, off.rotX, off.rotY, off.rotZ + heading, 0, true)
            props[#props + 1] = shit
            shitProps[#shitProps + 1] = shit
        end
    end

    local waterPos = rotatedOffset(coords, heading, toiletOffsets.waterOffset)
    local water = utils.createProp(toiletData.waterProp.prop, waterPos, false)
    if water then
        FreezeEntityPosition(water, true)
        local wo = toiletOffsets.waterOffset
        SetEntityRotation(water, wo.rotX, wo.rotY, wo.rotZ + heading, 0, true)
        props[#props + 1] = water
    end

    EnterCursorMode()

    local pedCoords = GetEntityCoords(cache.ped)
    local forward = GetEntityForwardVector(cache.ped)
    local rightVec = vector3(-forward.y, forward.x, 0.0)

    local camPos = vector3(
        pedCoords.x - forward.x * toiletOffsets.cameraOffset.distance + rightVec.x * 0.05,
        pedCoords.y - forward.y * toiletOffsets.cameraOffset.distance + rightVec.y * 0.05,
        pedCoords.z + toiletOffsets.cameraOffset.z
    )

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, -45.0, 0.0, heading, 60.0, true, 0)
    SetCamRot(cam, -45.0, 0.0, heading, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)

    local baseZ = GetEntityCoords(plunger).z
    local minZ = baseZ + toiletOffsets.zLimits.min
    local maxZ = baseZ + toiletOffsets.zLimits.max

    local pumps = 0
    local pumpDirection = 0
    local lastY = GetControlNormal(0, 240)
    local lastZ = baseZ
    local success = false
    local animDict = 'anim@amb@business@coc@coc_unpack_cut@'
    local animClip = 'fullcut_cycle_v6_cokecutter'
    utils.waitForAnim(animDict)

    while toiletActive do
        Wait(0)
        if not State.mission then break end

        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 257, true)

        SetEntityLocallyInvisible(cache.ped)

        if DoesEntityExist(plunger) then
            SetEntityDrawOutline(plunger, true)
            SetEntityDrawOutlineColor(0, 255, 0, 255)
            SetEntityDrawOutlineShader(0)
        end

        if not IsEntityPlayingAnim(cache.ped, animDict, animClip, 49) then
            TaskPlayAnim(cache.ped, animDict, animClip, 8.0, -8.0, -1, 49, 0, false, false, false)
        end

        if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 202) then
            break
        end

        local mouseY = GetControlNormal(0, 240)
        local diffY = mouseY - lastY

        if math.abs(diffY) >= 0.0005 and IsDisabledControlPressed(0, 237) then
            local plungerCoords = GetEntityCoords(plunger)
            local camCoords = GetFinalRenderedCamCoord()
            local heightDiff = math.max(1.0, camCoords.z - plungerCoords.z)
            local moveZ = -diffY * (heightDiff * 1.83)
            local newZ = math.max(minZ, math.min(maxZ, plungerCoords.z + moveZ))
            SetEntityCoords(plunger, plungerCoords.x, plungerCoords.y, newZ, true, false, false, true)

            local currentDir = diffY > 0 and 1 or -1
            if pumpDirection == 0 then
                pumpDirection = currentDir
            elseif currentDir ~= pumpDirection and math.abs(diffY) > 0.003 then
                pumps = pumps + 1
                pumpDirection = currentDir
            end

            local zDiff = math.abs(newZ - lastZ)
            if zDiff > 0.01 and pumps > 0 then
                local allRemoved = true
                local minShitZ = 99999.0
                for i = 1, #shitProps do
                    local shit = shitProps[i]
                    if shit and DoesEntityExist(shit) then
                        allRemoved = false
                        local sc = GetEntityCoords(shit)
                        local nz = sc.z - (zDiff * 0.02)
                        SetEntityCoords(shit, sc.x, sc.y, nz, true, false, false, true)
                        if nz < minShitZ then minShitZ = nz end
                        if nz < baseZ - 0.3 then
                            DeleteEntity(shit)
                            shitProps[i] = false
                        end
                    end
                end

                if allRemoved or (pumps >= REQUIRED_PUMPS and minShitZ < baseZ - 0.1) then
                    success = true
                    break
                end
            end
            lastZ = newZ
        end
        lastY = mouseY
    end

    LeaveCursorMode()
    SetCamActive(cam, false)
    DestroyCam(cam, false)
    RenderScriptCams(false, false, 0, true, true)
    ClearPedTasksImmediately(cache.ped)
    ClearPedTasks(cache.ped)
    ClearFocus()
    FreezeEntityPosition(cache.ped, false)

    for i = 1, #props do
        if props[i] and DoesEntityExist(props[i]) then DeleteEntity(props[i]) end
    end

    SetEntityCoords(cache.ped, restoreCoords.x, restoreCoords.y, restoreCoords.z, true, false, false, true)
    SetEntityHeading(cache.ped, restoreHeading)
    toiletActive = false
    return success
end

return Minigame
