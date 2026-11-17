local gizmoEntity = nil
local initialCoords = nil
local isWarningActive = false
running = false
local cameraTimeout = nil
local camAngle = 0.0
local camRadius = 5.0
local camHeight = 0.0
local isCameraLocked = false

RegisterNUICallback("hideFrame", function(data, cb)
    ToggleNuiFrame(false)
    StopGizmo()
    SetNuiFocusKeepInput(false)
    TriggerEvent("Housing:client:ResetFurniturePlacement")
    TriggerEvent("Housing:client:CloseFurnitureMenu")
    cb({})
end)

function UpdateCameraToFollowEntity(delay)
    if isCameraLocked then
        return
    end

    if cameraTimeout then
        ClearTimeOut(cameraTimeout)
        cameraTimeout = nil
    end

    cameraTimeout = SetTimeOut(delay, function()
        if CamGizmo and gizmoEntity and DoesEntityExist(gizmoEntity) then
            local offset = CamGizmoOffset or vector3(0, -5, 3)
            local targetCoords = GetEntityCoords(gizmoEntity) + offset
            local camCoord = GetCamCoord(CamGizmo)
            local camRot = GetCamRot(CamGizmo, 2)
            local duration = 500
            local elapsed = 0

            while duration > elapsed do
                local progress = math.min(elapsed / duration, 1.0)
                local currentX = Lerp(camCoord.x, targetCoords.x, progress)
                local currentY = Lerp(camCoord.y, targetCoords.y, progress)
                local currentZ = Lerp(camCoord.z, targetCoords.z, progress)

                SetCamCoord(CamGizmo, currentX, currentY, currentZ)
                SendNUIMessage({
                    action = "setCameraPosition",
                    data = {
                        position = vector3(currentX, currentY, currentZ),
                        rotation = camRot,
                    },
                })
                Wait(0)
                elapsed = elapsed + 32
            end

            SetCamCoord(CamGizmo, targetCoords.x, targetCoords.y, targetCoords.z)
            SetCamRot(CamGizmo, camRot.x, camRot.y, camRot.z, 2)
            SendNUIMessage({
                action = "setCameraPosition",
                data = {
                    position = targetCoords,
                    rotation = camRot,
                },
            })
        end
        cameraTimeout = nil
    end)
end

function SetCamera()
    local entityCoords = GetEntityCoords(gizmoEntity)
    local offsetX = math.cos(camAngle) * camRadius
    local offsetY = math.sin(camAngle) * camRadius
    local offsetZ = camHeight
    local targetCoords = vector3(entityCoords.x + offsetX, entityCoords.y + offsetY, entityCoords.z + offsetZ)

    CamGizmoOffset = vector3(offsetX, offsetY, offsetZ)

    if CamGizmo then
        SetCamCoord(CamGizmo, targetCoords.x, targetCoords.y, targetCoords.z)
        PointCamAtEntity(CamGizmo, gizmoEntity, 0.0, 0.0, 0.0, true)
        Wait(0)
        local camRot = GetCamRot(CamGizmo, 2)
        local camCoord = GetCamCoord(CamGizmo)
        DestroyCam(CamGizmo, false)
        CamGizmo = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(CamGizmo, camCoord.x, camCoord.y, camCoord.z)
        SetCamRot(CamGizmo, camRot.x, camRot.y, camRot.z, 2)
        SetCamActive(CamGizmo, true)
        RenderScriptCams(true, false, 0, true, false)
    end
end

function UpdateGizmoEntity(entity)
    local entityCoords = GetEntityCoords(entity)
    local entityRotation = GetEntityRotation(entity)

    SendReactMessage("setGizmoEntity", {
        handle = entity,
        position = {
            x = round(entityCoords.x, 3),
            y = round(entityCoords.y, 3),
            z = round(entityCoords.z, 3),
        },
        rotation = {
            x = round(entityRotation.x, 3),
            y = round(entityRotation.y, 3),
            z = round(entityRotation.z, 3),
        },
    })
    UpdateCameraToFollowEntity(500)
end

RegisterNUICallback("moveFurniture", function(data, cb)
    if gizmoEntity and DoesEntityExist(gizmoEntity) then
        data.position = ToVector3(data.position)
        data.rotation = ToVector3(data.rotation)

        if CurrentHome and next(CurrentHome) then
            local homeCoords = CurrentHome.properties.entry or initialCoords
            if CurrentHome.properties.complex == "Flat" and CurrentHome.properties.data.flat.coords then
                homeCoords = CurrentHome.properties.data.flat.coords
            end

            if LocalPlayer.state.isInsideHome then
                homeCoords = CurrentHome.entryInside
            end

            local dist = #(ToVector3(homeCoords) - ToVector3(data.position))
            if dist <= Config.MaxDistance.Furniture then
                SetEntityCoords(gizmoEntity, data.position.x, data.position.y, data.position.z)
                UpdateCameraToFollowEntity(1000)
            else
                CreateThread(function()
                    if not isWarningActive then
                        Notify(locale("housing"), locale("going_too_far"), "error", 3000)
                        isWarningActive = true
                    end
                    Wait(3000)
                    isWarningActive = false
                end)
            end
        else
            while not (DoesEntityExist(gizmoEntity) and DoesEntityExist(lastSelected.entity)) do
                Wait(1)
            end

            if lastSelected and lastSelected.entity == gizmoEntity then
                if IsControlPressed(0, 21) then
                    if not PasteGizmo then
                        PasteGizmo = true
                        if ConfirmPlacement(lastSelected.entity, lastSelected.data) then
                            SpawnCopyGizmo()
                        end
                        CreateThread(function()
                            while PasteGizmo do
                                if not IsControlPressed(0, 21) then
                                    PasteGizmo = false
                                end
                                Wait(1)
                            end
                        end)
                        cb({})
                        return
                    end
                end
            end

            SetEntityCoords(gizmoEntity, data.position.x, data.position.y, data.position.z)
            UpdateCameraToFollowEntity(1000)
        end

        SetEntityRotation(gizmoEntity, data.rotation.x, data.rotation.y, data.rotation.z)
        SendReactMessage("updatePosition", {
            position = {
                x = round(data.position.x, 3),
                y = round(data.position.y, 3),
                z = round(data.position.z, 3),
            },
            rotation = {
                x = round(data.rotation.x, 3),
                y = round(data.rotation.y, 3),
                z = round(data.rotation.z, 3),
            },
        })
    end
    cb({})
end)

RegisterNUICallback("submitPosition", function(data, cb)
    if CurrentHome and gizmoEntity then
        local entryCoords = CurrentHome.entryInside
        if CurrentHome.properties.type == "mlo" and Homes[CurrentHome.identifier] then
            local mloEntry = Homes[CurrentHome.identifier]:GetEntryCoords()
            if mloEntry then
                entryCoords = mloEntry
            end
        end

        local rot = ToVector3(data.rotation)
        local coords = ToVector3(data.coords)
        local dist = #(entryCoords - coords)

        if dist <= Config.MaxDistance.Furniture then
            SetEntityRotation(gizmoEntity, rot)
            SetEntityCoords(gizmoEntity, coords)
            UpdateGizmoEntity(gizmoEntity)
        else
            Notify(locale("housing"), locale("going_too_far"), "error", 3000)
        end
    end
    cb({})
end)

function StartEntityGizmo(entity, action)
    debugPrint("[Gizmo] Starting entity gizmo", entity, action)
    gizmoEntity = entity
    initialCoords = GetEntityCoords(entity)

    if running then
        return
    end

    SetNuiFocusKeepInput(true)
    UpdateGizmoEntity(entity)
    SendReactMessage("toggleGizmo", action)
    running = true

    if not CamGizmo then
        CamGizmo = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local camCoord = GetFinalRenderedCamCoord()
        local camRot = GetFinalRenderedCamRot(0)

        SetCamCoord(CamGizmo, camCoord.x, camCoord.y, camCoord.z)
        SetCamRot(CamGizmo, camRot.x, camRot.y, camRot.z, 2)
        SetCamActive(CamGizmo, true)
        RenderScriptCams(true, true, 500, true, false)

        CamGizmoOffset = camCoord - GetEntityCoords(entity)

        local entityCoords = GetEntityCoords(entity)
        local currentCamCoord = GetCamCoord(CamGizmo)
        local dx = currentCamCoord.x - entityCoords.x
        local dy = currentCamCoord.y - entityCoords.y

        camAngle = math.atan(dy, dx)
        camRadius = math.sqrt((dx * dx) + (dy * dy))
        camHeight = currentCamCoord.z - entityCoords.z

        if camRadius < 1.0 then
            camRadius = 5.0
        end
        if camRadius > 15.0 then
            camRadius = 5.0
        end

        SetCamera()
    end

    CreateThread(function()
        while running do
            SendNUIMessage({
                action = "setCameraPosition",
                data = {
                    position = GetCamCoord(CamGizmo),
                    rotation = GetCamRot(CamGizmo, 2),
                },
            })
            Wait(0)
        end
    end)
end

function StopGizmo()
    debugPrint("[Gizmo] Stopping Gizmo")
    SendReactMessage("setGizmoEntity", {})
    SendReactMessage("toggleGizmo", "")
    SetNuiFocusKeepInput(false)
    StopCameraEntity()

    if running then
        gizmoEntity = nil
        initialCoords = nil
        CamGizmoOffset = nil
        running = false
        camAngle = 0.0
        camRadius = 5.0
        camHeight = 0.0
    end

    if CamGizmo then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(CamGizmo, true)
        CamGizmo = nil
    end
end

RegisterNUICallback("move", function(data, cb)
    if isInFurnitureShop() and gizmoEntity then
        SetCamPosition(GetEntityCoords(gizmoEntity), data.x, data.y)
    end
    cb(1)
end)

RegisterNUICallback("zoom", function(zoomDelta, cb)
    if isInFurnitureShop() and gizmoEntity then
        if (camDistance + zoomDelta) < 1.0 or (camDistance + zoomDelta) > 7.0 then
            cb(0)
            return
        end
        camDistance = camDistance + zoomDelta
        SetCamPosition(GetEntityCoords(gizmoEntity))
    end
    cb(1)
end)

local function ToggleLockCamera(data, cb)
    isCameraLocked = not isCameraLocked

    local messageKey = "camera_follow_enabled"
    if isCameraLocked then
        messageKey = "camera_follow_disabled"
    end

    Notify(locale("housing"), locale(messageKey), "info", 2000)

    if not isCameraLocked then
        UpdateCameraToFollowEntity(500)
    end

    if cb then
        cb({})
    end
end

RegisterNUICallback("toggleLockCamera", ToggleLockCamera)

function CamGizmoControl()
    if Config.EnableFurnitureShop and not CamGizmo and CurrentMode ~= "gizmo" and CurrentMode ~= nil then
        return
    end

    if not gizmoEntity or not DoesEntityExist(gizmoEntity) then
        return
    end

    EnableControlAction(0, 21, true)
    if not DisableScroll then
        EnableControlAction(0, 14, true)
        EnableControlAction(0, 15, true)
    end

    local sensitivity = 0.03
    local zoomStep = 0.5

    if IsControlJustPressed(0, 15) then
        camRadius = math.max(camRadius - zoomStep, 1.0)
        SetCamera()
    elseif IsControlJustPressed(0, 14) then
        camRadius = math.min(camRadius + zoomStep, 15.0)
        SetCamera()
    end

    if IsDisabledControlJustPressed(0, 52) then
        ToggleLockCamera()
    end

    if IsDisabledControlPressed(0, 25) then
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        local lookX = GetControlNormal(0, 1)
        local lookY = GetControlNormal(0, 2)

        if math.abs(lookX) > 0.003 then
            camAngle = camAngle + (lookX * sensitivity) * 20
        end
        if math.abs(lookY) > 0.003 then
            camHeight = camHeight - (lookY * sensitivity) * 40
        end

        SetCamera()
    end
end