local MaxFOV = Config.Camera and Config.Camera.MaxFOV or 70.0
local DefaultFOV = Config.Camera and Config.Camera.DefaultFOV or 60.0
local MinFOV = Config.Camera and Config.Camera.MinFOV or 10.0
local MaxLookUp = Config.Camera and Config.Camera.MaxLookUp or 80.0
local MaxLookDown = Config.Camera and Config.Camera.MaxLookDown or -80.0
local AllowRunning = (Config.Camera and Config.Camera.AllowRunning) == true
local VehicleZoom = (Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.Zoom) == true
local VehicleMaxFOV = Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.MaxFOV or 80.0
local VehicleDefaultFOV = Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.DefaultFOV or 60.0
local VehicleMinFOV = Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.MinFOV or 10.0
local VehicleMaxLookUp = Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.MaxLookUp or 50.0
local VehicleMaxLookDown = Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.MaxLookDown or -30.0
local VehicleMaxLeftRight = Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.MaxLeftRight or 120.0
local VehicleMinLeftRight = Config.Camera and Config.Camera.Vehicle and Config.Camera.Vehicle.MinLeftRight or -120.0
local SelfieMaxFOV = Config.Camera and Config.Camera.Selfie and Config.Camera.Selfie.MaxFOV or 80.0
local SelfieDefaultFOV = Config.Camera and Config.Camera.Selfie and Config.Camera.Selfie.DefaultFOV or 60.0
local SelfieMinFOV = Config.Camera and Config.Camera.Selfie and Config.Camera.Selfie.MinFOV or 50.0
local FreezeEnabled = (Config.Camera and Config.Camera.Freeze and Config.Camera.Freeze.Enabled) == true
local FreezeMaxDistance = Config.Camera and Config.Camera.Freeze and Config.Camera.Freeze.MaxDistance or 10.0
local FreezeMaxTime = (Config.Camera and Config.Camera.Freeze and Config.Camera.Freeze.MaxTime or 60) * 1000
local SelfieOffset = Config.Camera and Config.Camera.Selfie and Config.Camera.Selfie.Offset or vector3(0.1, 0.55, 0.6)
local SelfieRotation = Config.Camera and Config.Camera.Selfie and Config.Camera.Selfie.Rotation or vector3(10.0, 0.0, -180.0)
local RollEnabled = Config.Camera.Roll == true
local rearOffset = vector3(0.0, 0.5, 0.6)
local pitch = 0.0
local roll = 0.0
local fov = 60.0
local previousViewMode = 0
local vehicleHeading = 0.0
local radioControlDisabled = false
local frozen = false
local freezeTimeout = 0
local ped = PlayerPedId()
local isSelfie = false
local isMoving = false
local lookSpeed = 0.0
local lookSensitivity = GetProfileSetting(754) + 10
local lastZoom = 1.0
local cam = nil
local cameraModes = { REAR = 0, SELFIE = 1, IN_VEHICLE = 2 }
local currentMode = cameraModes.REAR

local function GetCameraFovLimits()
    local inVehicle = IsPedInAnyVehicle(ped, true)
    local maxFov = (isSelfie and SelfieMaxFOV) or (inVehicle and VehicleMaxFOV) or MaxFOV
    local minFov = (isSelfie and SelfieMinFOV) or (inVehicle and ((VehicleZoom and VehicleMinFOV) or VehicleMaxFOV)) or MinFOV
    local defaultFov = (isSelfie and SelfieDefaultFOV) or (inVehicle and VehicleDefaultFOV) or DefaultFOV
    return maxFov, minFov, defaultFov
end

function ConvertFovToZoom(fov)
    local maxFov, minFov, defaultFov = GetCameraFovLimits()
    local clamped = math.clamp(fov, minFov, maxFov)
    if clamped == defaultFov then
        return 1.0
    elseif defaultFov > clamped then
        if clamped <= 0 then
            return 1.0
        end
        return defaultFov / clamped
    else
        local t = (clamped - defaultFov) / (maxFov - defaultFov)
        return 1.0 - t * 0.5
    end
end

local function ConvertZoomToFov(zoom)
    local maxFov, minFov, defaultFov = GetCameraFovLimits()
    local minZoom = 1.0
    if defaultFov < maxFov then
        minZoom = 0.5
    end
    local maxZoom = 1.0
    if minFov < defaultFov and minFov > 0 then
        maxZoom = defaultFov / minFov
    end
    local clamped = math.clamp(zoom, minZoom, maxZoom)
    if 1.0 == clamped then
        return defaultFov
    elseif clamped > 1.0 then
        return defaultFov / clamped
    else
        local t = 2.0 * (1.0 - clamped)
        return defaultFov + t * (maxFov - defaultFov)
    end
end

local function UpdateZoomLevels()
    local maxFov, minFov = GetCameraFovLimits()
    local minZoom = ConvertFovToZoom(maxFov)
    local maxZoom = ConvertFovToZoom(minFov)
    local levels = { 1.0 }
    if minZoom < 1.0 then
        table.insert(levels, 1, minZoom)
    end
    if maxZoom > 2.0 then
        table.insert(levels, 2)
    end
    if maxZoom > 5.0 then
        table.insert(levels, 5)
    elseif maxZoom > 3.0 then
        table.insert(levels, 3)
    end
    SendNUIAction("camera:setZoomLevels", levels)
end

function SetCameraZoom(zoom)
    fov = ConvertZoomToFov(zoom)
end

local function UpdateCamera()
    local inVehicle = IsPedInAnyVehicle(ped, true)
    local mode = (isSelfie and cameraModes.SELFIE) or cameraModes.REAR
    if inVehicle then
        mode = mode + cameraModes.IN_VEHICLE
    end
    if currentMode ~= mode then
        local _, _, defaultFov = GetCameraFovLimits()
        currentMode = mode
        fov = defaultFov
        debugprint("Camera mode changed to: " .. currentMode)
        UpdateZoomLevels()
        SetCamFov(cam, fov)
    end
    isMoving = IsDisabledControlPressed(0, 33) or IsDisabledControlPressed(0, 34) or (IsDisabledControlPressed(0, 35) and not inVehicle)
    SetFollowPedCamViewMode(0)
    SetGameplayCamRelativeHeading(0.0)
    DisableControlAction(0, 1, true)
    DisableControlAction(0, 14, true)
    DisableControlAction(0, 15, true)
    DisableControlAction(0, 16, true)
    DisableControlAction(0, 17, true)
    DisableControlAction(0, 99, true)
    DisableControlAction(0, 100, true)
    DisableControlAction(0, 115, true)
    DisableControlAction(0, 116, true)
    DisableControlAction(0, 261, true)
    DisableControlAction(0, 262, true)
    SetPedResetFlag(ped, 47, true)
    if frozen and not inVehicle then
        local dist = #(GetEntityCoords(ped) - GetCamCoord(cam))
        if dist > FreezeMaxDistance or GetGameTimer() > freezeTimeout then
            frozen = false
            TogglePhoneAnimation(true, "camera")
        end
        return
    end
    if not AllowRunning then
        DisableControlAction(0, 21, true)
    end
    if isSelfie and not inVehicle then
        AttachCamToPedBone_2(cam, ped, 0, SelfieRotation.x + pitch, SelfieRotation.y, SelfieRotation.z, SelfieOffset.x, SelfieOffset.y, SelfieOffset.z, true)
    elseif not isSelfie and not inVehicle then
        local target = GetOffsetFromEntityInWorldCoords(ped, rearOffset.x, rearOffset.y, rearOffset.z)
        local boneCoords = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
        local z
        if math.abs(boneCoords.z - target.z) > 0.2 then
            z = boneCoords.z
        else
            z = target.z
        end
        DetachCam(cam)
        SetCamCoord(cam, target.x, target.y, z)
        SetCamRot(cam, pitch, roll, GetEntityHeading(ped), 2)
    elseif isSelfie and inVehicle then
        AttachCamToPedBone_2(cam, ped, 0, 80.0 + pitch, 0.0, -180.0, 0.0, 0.2, 0.5, true)
    elseif not isSelfie and inVehicle then
        local phoneObj = GetPhoneObject()
        if phoneObj then
            SetEntityLocallyInvisible(phoneObj)
        end
        SetEntityLocallyInvisible(ped)
        AttachCamToPedBone_2(cam, ped, GetPedBoneIndex(ped, 11816), pitch, 0.0, vehicleHeading, 0.0, 0.0, 0.55, true)
    end
    if inVehicle then
        if not radioControlDisabled then
            radioControlDisabled = true
            SetUserRadioControlEnabled(false)
        end
    else
        if radioControlDisabled then
            radioControlDisabled = false
            SetUserRadioControlEnabled(true)
        end
        vehicleHeading = 0.0
    end
    if isMoving then
        SetPedResetFlag(ped, 69, true)
    elseif not isSelfie and not inVehicle then
        DisableControlAction(0, 30, true)
    end
    local currentFov = GetCamFov(cam)
    local maxFovLimit = (isSelfie and SelfieMaxFOV) or (inVehicle and VehicleMaxFOV) or MaxFOV
    local minFovLimit = (isSelfie and SelfieMinFOV) or (inVehicle and ((VehicleZoom and VehicleMinFOV) or VehicleMaxFOV)) or MinFOV
    fov = math.clamp(fov, minFovLimit, maxFovLimit)
    local zoomLevel = math.round(ConvertFovToZoom(currentFov), 1)
    if zoomLevel ~= lastZoom then
        debugprint("Zoom changed to: " .. zoomLevel, ConvertFovToZoom(currentFov), currentFov)
        lastZoom = zoomLevel
        SendNUIAction("camera:setZoom", zoomLevel)
    end
    if math.abs(currentFov - fov) > 0.05 then
        SetCamFov(cam, currentFov + (fov - currentFov) / 25)
    end
    if IsNuiFocused() then
        return
    end
    lookSpeed = lookSensitivity * (math.max(fov, 1.0) / MaxFOV) / 5
    local leftRight = GetDisabledControlNormal(0, 1)
    if inVehicle then
        vehicleHeading = math.clamp(vehicleHeading - leftRight * lookSpeed, VehicleMinLeftRight, VehicleMaxLeftRight)
    elseif 0.0 ~= leftRight then
        SetEntityHeading(ped, GetEntityHeading(ped) - leftRight * lookSpeed)
    end
    if IsDisabledControlPressed(0, 180) then
        fov = fov + 5
    elseif IsDisabledControlPressed(0, 181) then
        fov = fov - 5
    end
    local upDown = GetDisabledControlNormal(0, 2)
    if 0.0 ~= upDown then
        local delta = upDown * lookSpeed
        if inVehicle then
            pitch = math.clamp(pitch - delta, VehicleMaxLookDown, VehicleMaxLookUp)
        else
            pitch = math.clamp(pitch - delta, MaxLookDown, MaxLookUp)
        end
    end
end

local function UpdatePedHeading()
    local leftRight = GetDisabledControlNormal(0, 1)
    if 0.0 ~= leftRight then
        SetEntityHeading(ped, GetEntityHeading(ped) - leftRight * lookSpeed)
    end
end

function EnableWalkableCam(enabled)
    if cam then
        return
    end
    isSelfie = true == enabled
    isMoving = false
    fov = (isSelfie and SelfieDefaultFOV) or DefaultFOV
    ped = PlayerPedId()
    previousViewMode = GetFollowPedCamViewMode()
    pitch = 0.0
    vehicleHeading = 0.0
    roll = 0.0
    frozen = false
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    lookSensitivity = GetProfileSetting(754) + 10
    lastZoom = 1.0
    SetPhoneAction("camera")
    CreateThread(function()
        while cam do
            Wait(0)
            if isMoving or frozen then
                if not IsNuiFocused() then
                    UpdatePedHeading()
                end
            end
        end
    end)
    CreateThread(function()
        while cam do
            Wait(0)
            UpdateCamera()
        end
        if radioControlDisabled then
            radioControlDisabled = false
            SetUserRadioControlEnabled(true)
        end
    end)
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, true, true)
    SetCamActive(cam, true)
    SendNUIAction("camera:setZoom", 1.0)
    UpdateZoomLevels()
    RefreshAnimationsInterval()
end

function DisableWalkableCam()
    if not cam then
        return
    end
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(cam, false)
    SetFollowPedCamViewMode(previousViewMode)
    SetPhoneAction(IsInCall() and "call" or "default")
    cam = nil
    if frozen then
        TogglePhoneAnimation(true, "camera")
    end
    RefreshAnimationsInterval()
end

function ToggleSelfieCam(enabled)
    local wasSelfie = isSelfie
    isSelfie = true == enabled
    if wasSelfie ~= isSelfie then
        roll = 0.0
        pitch = 0.0
    end
end

function ToggleCameraFrozen()
    if not (FreezeEnabled and cam and not isSelfie) then
        return
    end
    local newFrozen = not frozen
    if newFrozen then
        TogglePhoneAnimation(false, "camera")
        freezeTimeout = GetGameTimer() + FreezeMaxTime
    end
    frozen = newFrozen
end

function IsWalkingCamEnabled()
    return nil ~= cam
end

function IsSelfieCam()
    return isSelfie
end

AddEventHandler("lb-phone:keyPressed", function(key)
    if not cam then
        return
    end
    if "FreezeCamera" == key then
        if not (FreezeEnabled and not isSelfie) then
            return
        end
        ToggleCameraFrozen()
    elseif "RollLeft" == key or "RollRight" == key then
        if not RollEnabled then
            return
        end
        local dir = ("RollLeft" == key) and -0.5 or 0.5
        local bind = Config.KeyBinds[key].bindData
        while bind.pressed do
            Wait(0)
            roll = roll + dir
        end
    end
end)

exports("EnableWalkableCam", EnableWalkableCam)
exports("DisableWalkableCam", DisableWalkableCam)
exports("ToggleSelfieCam", ToggleSelfieCam)
exports("ToggleCameraFrozen", ToggleCameraFrozen)
exports("IsWalkingCamEnabled", IsWalkingCamEnabled)
exports("IsSelfieCam", IsSelfieCam)
