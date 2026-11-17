local noclip = false
local cam = 0
local speed = 1
local maxSpeed = 16
local noclipEntity

local function disabledControls()
    HudWeaponWheelIgnoreSelection()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    EnableControlAction(0, 220, true)
    EnableControlAction(0, 221, true)
    EnableControlAction(0, 245, true)
end

local function setupCam()
    local rotation = GetEntityRotation(noclipEntity)
    local coords = GetEntityCoords(noclipEntity)

    cam = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z, 0.0, 0.0, rotation.z, 75.0, false, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, false, false)
    AttachCamToEntity(cam, noclipEntity, 0.0, 0.0, 1.0, true)
end

local function destoryCam()
    Wait(100)
    SetGameplayCamRelativeHeading(0)
    RenderScriptCams(false, true, 1000, true, true)
    DetachEntity(noclipEntity, true, true)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
end

local isControlAlwaysPressed = function(inputGroup, control)
    return IsControlPressed(inputGroup, control) or IsDisabledControlPressed(inputGroup, control)
end

local function updateCameraRotation()
    local rightAxisX = GetControlNormal(0, 220)
    local rightAxisY = GetControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    local yValue = rightAxisY * -5
    local newX
    local newZ = rotation.z + (rightAxisX * -10)

    if (rotation.x + yValue > -89.0) and (rotation.x + yValue < 89.0) then
        newX = rotation.x + yValue
    end

    if newX ~= nil and newZ ~= nil then
        SetCamRot(cam, newX, rotation.y, newZ, 2)
    end

    SetEntityHeading(noclipEntity, math.max(0, (rotation.z % 360)))
end

local function teleportToGround()
    local coords = GetEntityCoords(noclipEntity)
    local rayCast = StartShapeTestRay(coords.x, coords.y, coords.z, coords.x, coords.y, -10000.0, 1, 0, 0)
    local _, hit, hitCoords = GetShapeTestResult(rayCast)

    if hit == 1 then
        SetEntityCoords(noclipEntity, hitCoords.x, hitCoords.y, hitCoords.z, false, false, false, false)
    else
        SetEntityCoords(noclipEntity, coords.x, coords.y, coords.z, false, false, false, false)
    end
end

local function toggleBehavior(bool)
    local coords = GetEntityCoords(noclipEntity)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    FreezeEntityPosition(noclipEntity, bool)
    SetEntityCollision(noclipEntity, not bool, not bool)
    SetEntityVisible(noclipEntity, not bool, not bool)
    SetEntityInvincible(noclipEntity, bool)
    SetEntityAlpha(noclipEntity, 255, false)
    SetLocalPlayerVisibleLocally(true)
    SetEveryoneIgnorePlayer(noclipEntity, bool)
    SetPoliceIgnorePlayer(noclipEntity, bool)
end

local function updateSpeed()
    if isControlAlwaysPressed(2, 14) then
        speed = speed - 0.5
        if speed < 0.5 then
            speed = 0.5
        end
    elseif isControlAlwaysPressed(2, 15) then
        speed = speed + 0.5
        if speed > maxSpeed then
            speed = maxSpeed
        end
    elseif IsDisabledControlJustReleased(0, 348) then
        speed = 1
    end
end

local function updateMovement()
    local multi = 1.0
    if isControlAlwaysPressed(0, 21) then
        multi = 2
    elseif isControlAlwaysPressed(0, 19) then
        multi = 4
    elseif isControlAlwaysPressed(0, 36) then
        multi = 0.25
    end

    local moveSpeed = 0.5 * speed * multi
    local verticalMultiplier = (speed * multi) / 178

    if isControlAlwaysPressed(0, 32) then
        local pitch = GetCamRot(cam, 2)
        local verticalOffset = pitch.x * verticalMultiplier
        local newCoords = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, moveSpeed, verticalOffset)
        SetEntityCoordsNoOffset(noclipEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    elseif isControlAlwaysPressed(0, 33) then
        local pitch = GetCamRot(cam, 2)
        local verticalOffset = pitch.x * verticalMultiplier
        local newCoords = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, -moveSpeed, -verticalOffset)
        SetEntityCoordsNoOffset(noclipEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    end

    if isControlAlwaysPressed(0, 34) then
        local newCoords = GetOffsetFromEntityInWorldCoords(noclipEntity, -moveSpeed, 0.0, 0.0)
        SetEntityCoordsNoOffset(noclipEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    elseif isControlAlwaysPressed(0, 35) then
        local newCoords = GetOffsetFromEntityInWorldCoords(noclipEntity, moveSpeed, 0.0, 0.0)
        SetEntityCoordsNoOffset(noclipEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    end

    if isControlAlwaysPressed(0, 44) then
        local newCoords = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, 0.0, moveSpeed)
        SetEntityCoordsNoOffset(noclipEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    elseif isControlAlwaysPressed(0, 46) then
        local newCoords = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, 0.0, -moveSpeed)
        SetEntityCoordsNoOffset(noclipEntity, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    end
end

local utils = require 'modules.lib.utils'

return {
    toggle = function (actionData)
        if not utils.validate(actionData) then
            return
        end

        noclip = not noclip

        local msg = noclip and 'active' or 'non active'
        lib.notify({ description = 'Noclip mode ' .. msg })

        if cache.vehicle then
            noclipEntity = cache.vehicle
        else
            noclipEntity = cache.ped
        end

        if noclip then
            setupCam()
            toggleBehavior(true)
            while noclip do
                Wait(0)
                updateCameraRotation()
                disabledControls()
                updateSpeed()
                updateMovement()
            end
        else
            destoryCam()
            teleportToGround()
            toggleBehavior(false)
        end
    end
}