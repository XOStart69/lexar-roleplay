local config = localmodule 'config.shared'
local Util = localmodule 'modules.util'
local Anim = localmodule 'modules.anim'

local Lean = {
    blend = 0.0,
    limit = 1.0
}

local mathAbs, mathMax, mathMin, mathRad, mathSin, mathCos, mathSqrt = math.abs, math.max, math.min, math.rad, math.sin, math.cos, math.sqrt

local isLeanLeftPressed = false
local isLeanRightPressed = false
local currentAnimName = nil
local lastAnimTime = -1.0
local leanCam = nil

local bodyProbe = { handle = nil, distance = nil, side = 0.0, fx = 0.0, fy = 0.0, fz = 0.0 }
local camProbe = { handle = nil, distance = nil, side = 0.0, fx = 0.0, fy = 0.0, fz = 0.0 }

---@param probe table
local function resetProbe(probe)
    probe.handle = nil
    probe.distance = nil
end

---@param probe table
---@param side number
local function setProbeSide(probe, side)
    if probe.side == side then
        return
    end

    resetProbe(probe)
    probe.side = side
end

---@param probe table
---@param fx number
---@param fy number
---@param fz number
---@param tx number
---@param ty number
---@param tz number
---@param ignore number
---@param flags number
local function pollProbe(probe, fx, fy, fz, tx, ty, tz, ignore, flags)
    local handle = probe.handle

    if handle then
        local status, hit, hitCoords = GetShapeTestResult(handle)

        if status == 1 then
            return
        end

        probe.handle = nil

        if status == 2 then
            if hit == 1 or hit == true then
                local dx, dy, dz = hitCoords.x - probe.fx, hitCoords.y - probe.fy, hitCoords.z - probe.fz
                probe.distance = mathSqrt(dx * dx + dy * dy + dz * dz)
            else
                probe.distance = false
            end
        end
    end

    probe.fx, probe.fy, probe.fz = fx, fy, fz
    probe.handle = StartShapeTestLosProbe(fx, fy, fz, tx, ty, tz, flags, ignore, 4)
end

RegisterCommand('+dmLeanLeft', function()
    isLeanLeftPressed = true
end, false)

RegisterCommand('-dmLeanLeft', function()
    isLeanLeftPressed = false
end, false)

RegisterCommand('+dmLeanRight', function()
    isLeanRightPressed = true
end, false)

RegisterCommand('-dmLeanRight', function()
    isLeanRightPressed = false
end, false)

---@param key string
---@return string
local function getKeyType(key)
    if key:upper():match('^MOUSE_') then
        return 'MOUSE_BUTTON'
    end

    return 'keyboard'
end

RegisterKeyMapping('+dmLeanLeft', 'Lean left', getKeyType(config.lean.keyLeft), config.lean.keyLeft)
RegisterKeyMapping('+dmLeanRight', 'Lean right', getKeyType(config.lean.keyRight), config.lean.keyRight)

---@param ped number
local function stopLeanAnim(ped)
    if not currentAnimName then
        return
    end

    StopAnimTask(ped, config.lean.anim.dict, currentAnimName, 4.0)
    currentAnimName = nil
    lastAnimTime = -1.0
end

local function destroyLeanCam()
    if not leanCam then
        return
    end

    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(leanCam, false)
    leanCam = nil
end

function Lean.Active()
    return mathAbs(Lean.blend) > 0.01
end

function Lean.CameraActive()
    return leanCam ~= nil
end

function Lean.Pressed()
    if isLeanLeftPressed or isLeanRightPressed then
        return true
    end

    local gamepad = config.lean.gamepad

    if gamepad.enabled and (IsControlPressed(0, gamepad.left) or IsControlPressed(0, gamepad.right)) then
        return true
    end

    return false
end

function Lean.Amount()
    return Lean.blend
end

---@param ped number
---@param direction number
---@return number
local function getObstructionLimit(ped, direction)
    local lean = config.lean

    if not lean.blockWhenObstructed then
        return 1.0
    end

    setProbeSide(bodyProbe, direction)

    local spine = GetPedBoneCoords(ped, 24818, 0.0, 0.0, 0.0)
    local rad = mathRad(GetGameplayCamRot(2).z)
    local reach = direction * (lean.distance + lean.obstructionPadding)
    local sx, sy, sz = spine.x, spine.y, spine.z

    pollProbe(bodyProbe, sx, sy, sz, sx + mathCos(rad) * reach, sy + mathSin(rad) * reach, sz, ped, config.traversal.clearanceFlags)

    local distance = bodyProbe.distance

    if not distance then
        return 1.0
    end

    return Util.Clamp((distance - lean.obstructionPadding) / lean.distance, 0.0, 1.0)
end

---@param ped number
local function updateLeanAnim(ped)
    local anim = config.lean.anim

    if not anim.dict or anim.dict == '' then
        return
    end

    local clampedBlend = Util.Clamp(Lean.blend * Lean.limit, -1.0, 1.0)

    if mathAbs(clampedBlend) < 0.01 then
        stopLeanAnim(ped)
        return
    end

    local animName = clampedBlend < 0.0 and anim.left or anim.right

    if not animName or animName == '' then
        return
    end

    if currentAnimName and currentAnimName ~= animName then
        stopLeanAnim(ped)
    end

    if not currentAnimName or not IsEntityPlayingAnim(ped, anim.dict, animName, 3) then
        if not Anim.Play(ped, { dict = anim.dict, name = animName }, anim.flags) then
            return
        end

        currentAnimName = animName
        lastAnimTime = -1.0
    end

    local animTime = mathAbs(clampedBlend)

    if mathAbs(animTime - lastAnimTime) < 0.001 then
        return
    end

    lastAnimTime = animTime
    SetEntityAnimSpeed(ped, anim.dict, animName, 0.0)
    SetEntityAnimCurrentTime(ped, anim.dict, animName, animTime)
end

---@param ped number
local function updateLeanCamera(ped)
    local camera = config.lean.camera

    if not camera.enabled or IsPauseMenuActive() or GetFollowPedCamViewMode() >= 3 or mathAbs(Lean.blend) < 0.01 then
        destroyLeanCam()
        return
    end

    if not leanCam then
        leanCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(leanCam, true)
        SetCamAffectsAiming(leanCam, true)
        RenderScriptCams(true, false, 0, true, false)
    end

    local camRot = GetGameplayCamRot(2)
    local camCoords = GetGameplayCamCoord()
    local blend = Lean.blend
    local direction = blend < 0.0 and -1.0 or 1.0
    local sideOffset = blend < 0.0 and camera.left or camera.right
    local absBlend = mathAbs(blend)
    local rad = mathRad(camRot.z)
    local cosZ, sinZ = mathCos(rad), mathSin(rad)
    local side = direction * sideOffset * absBlend
    local forward = camera.forward * absBlend
    local ox = cosZ * side - sinZ * forward
    local oy = sinZ * side + cosZ * forward
    local oz = camera.height * absBlend
    local offsetLength = mathSqrt(ox * ox + oy * oy + oz * oz)
    local cx, cy, cz = camCoords.x, camCoords.y, camCoords.z
    local tx, ty, tz = cx, cy, cz

    setProbeSide(camProbe, direction)

    if offsetLength > 0.005 then
        local inv = 1.0 / offsetLength
        local dx, dy, dz = ox * inv, oy * inv, oz * inv
        local reach = offsetLength + camera.padding

        pollProbe(camProbe, cx, cy, cz, cx + dx * reach, cy + dy * reach, cz + dz * reach, ped, config.traversal.clearanceFlags)

        local distance = camProbe.distance

        if distance then
            offsetLength = mathMin(offsetLength, mathMax(0.0, distance - camera.padding))
        end

        tx, ty, tz = cx + dx * offsetLength, cy + dy * offsetLength, cz + dz * offsetLength
    end

    SetCamCoord(leanCam, tx, ty, tz)
    SetCamRot(leanCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamFov(leanCam, mathMax(10.0, GetGameplayCamFov() - (camera.narrow * absBlend)))
    ShowHudComponentThisFrame(14)

    if not camera.crosshair then
        return
    end

    DrawRect(0.5, 0.5, 0.0022, 0.0039, 235, 235, 235, 190)
end

---@param ped number
---@param deltaTime number
---@param canLean boolean
function Lean.Update(ped, deltaTime, canLean)
    local lean = config.lean
    local target = 0.0

    if canLean then
        local gamepad = lean.gamepad
        local left = isLeanLeftPressed
        local right = isLeanRightPressed

        if gamepad.enabled then
            if not left then
                left = IsControlPressed(0, gamepad.left)
            end

            if not right then
                right = IsControlPressed(0, gamepad.right)
            end
        end

        if left ~= right then
            target = left and -1.0 or 1.0
        end
    end

    Lean.blend = Lean.blend + (target - Lean.blend) * Util.Clamp(lean.blendSpeed * deltaTime, 0.0, 1.0)

    if target == 0.0 and mathAbs(Lean.blend) < 0.01 then
        Lean.blend = 0.0
    end

    if Lean.blend == 0.0 then
        Lean.limit = 1.0
        resetProbe(bodyProbe)
        resetProbe(camProbe)
    else
        Lean.limit = getObstructionLimit(ped, Lean.blend < 0.0 and -1.0 or 1.0)
    end

    updateLeanAnim(ped)
    updateLeanCamera(ped)
end

---@param ped number
function Lean.Reset(ped)
    destroyLeanCam()

    if DoesEntityExist(ped) then
        stopLeanAnim(ped)
    end

    Lean.blend = 0.0
    Lean.limit = 1.0
    currentAnimName = nil
    lastAnimTime = -1.0
    resetProbe(bodyProbe)
    resetProbe(camProbe)
end

return Lean
