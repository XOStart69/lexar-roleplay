local currentCam = nil
local shellCoords = {}
local moveSteps = { 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100 }
local rotSteps = { 0.25, 0.5, 1, 2.5, 5, 15, 30, 45, 60, 90, 180 }
local stepSettings = { moveSteps, rotSteps }

local function rotateCoords(origin, target, angle)
    if angle == 0.0 then
        return target
    end
    local diff = target - origin
    local rad = math.rad(angle)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    local newX = math.floor((((diff.x * cos) - diff.y * sin) + origin.x) * 100 + 0.0) / 100
    local newY = math.floor((((diff.x * sin) + diff.y * cos) + origin.y) * 100 + 0.0) / 100
    return newX, newY
end

function PlaceStoragesWardrobes(homeData)
    local baseCoords = nil
    local shellEntity = nil

    local hasStorages = homeData.storages and (type(homeData.storages) ~= "table" or #homeData.storages > 0)
    local hasWardrobes = homeData.wardrobes and (type(homeData.wardrobes) ~= "table" or #homeData.wardrobes > 0)

    if not hasStorages and not hasWardrobes then
        return
    end

    if homeData.type == "shell" then
        baseCoords = homeData.data.placement
        pcall(lib.requestModel, homeData.data.interior)
        shellEntity = CreateShell(homeData.data.interior, homeData.data.placement)
        SetModelAsNoLongerNeeded(homeData.data.interior)
        entry = GetOffsetFromEntityInWorldCoords(shellEntity, Shells[homeData.data.interior])
        SetEntityCoordsNoOffset(cache.ped, entry)
        SetEntityHeading(cache.ped, Shells[homeData.data.interior].w)
        FreezeEntityPosition(cache.ped, true)
        Wait(2500)
    elseif homeData.type == "ipl" then
        for i = 1, #CustomizeIPL do
            local ipl = CustomizeIPL[i]
            if ipl.name == homeData.data.interior then
                baseCoords = ipl.entry
                SetEntityCoordsNoOffset(cache.ped, ipl.entry)
                SetEntityHeading(cache.ped, ipl.entry.w)
                break
            end
        end
    elseif homeData.type == "mlo_teleport" then
        for i = 1, #MLOTeleport do
            local teleport = MLOTeleport[i]
            if teleport.name == homeData.data.interior then
                baseCoords = teleport.entry
                SetEntityCoordsNoOffset(cache.ped, teleport.entry)
                SetEntityHeading(cache.ped, teleport.entry.w)
                break
            end
        end
    elseif homeData.type == "mlo" then
        baseCoords = homeData.entry
    end

    FreezeEntityPosition(cache.ped, false)

    if homeData.storages then
        if type(homeData.storages) ~= "table" or #homeData.storages > 0 then
            HelpText(true, locale("prompt_add_storage"))
            for i = 1, #homeData.storages do
                while true do
                    local hit, _, coords = lib.raycast.cam()
                    if hit then
                        DrawMarker(1, coords.x, coords.y, coords.z,
                            0.0, 0.0, 0.0, 0, 0.0, 0.0,
                            1.5, 1.5, 1.5,
                            255, 100, 100, 255,
                            false, true, 2, false, false, false, false)
                    end
                    if IsControlJustReleased(0, 38) then
                        homeData.storages[i].coords = {
                            x = round(coords.x - baseCoords.x, 4),
                            y = round(coords.y - baseCoords.y, 4),
                            z = round(coords.z - baseCoords.z, 4)
                        }
                        homeData.storages[i].area = homeData.type == "mlo"
                        HelpText(false)
                        Wait(1000)
                        break
                    end
                end
            end
            Wait(1000)
        end
    end

    HelpText(true, locale("prompt_add_wardrobe"))
    for i = 1, #homeData.wardrobes do
        while true do
            local hit, _, coords = lib.raycast.cam()
            if hit then
                DrawMarker(1, coords.x, coords.y, coords.z,
                    0.0, 0.0, 0.0, 0, 0.0, 0.0,
                    1.5, 1.5, 1.5,
                    100, 100, 255, 255,
                    false, true, 2, false, false, false, false)
            end
            if IsControlJustReleased(0, 38) then
                homeData.wardrobes[i].coords = {
                    x = round(coords.x, 4),
                    y = round(coords.y, 4),
                    z = round(coords.z, 4)
                }
                HelpText(false)
                Wait(1000)
                break
            end
        end
    end
    Wait(1000)

    if shellEntity then
        DeleteEntity(shellEntity)
    end

    local returnCoords = homeData.entry
    if homeData.complex == "Flat" and homeData.data.flat and homeData.data.flat.coords then
        returnCoords = homeData.data.flat.coords
    end

    SetEntityCoords(cache.ped, returnCoords.x, returnCoords.y, returnCoords.z)
    HelpText(false)
end

AddEventHandler("Housing:client:CreateShell", function(homeData)
    local interior = homeData.data.interior
    local defaultCoords = homeData.entry or (homeData.data.flat and homeData.data.flat.coords)
    local shellPlacement = PlaceShell(interior, defaultCoords)

    if shellPlacement then
        homeData.data.placement = shellPlacement.shell
        homeData.data.placement.w = shellPlacement.heading
        homeData.data.interior = shellPlacement.interior
        PlaceStoragesWardrobes(homeData)
        TriggerServerEvent("Housing:server:CreateHome", homeData)
    end
end)

AddEventHandler("Housing:client:CreateIPL", function(homeData)
    local interior = homeData.data.interior
    local selectedIPL = SelectIPL(interior)

    if selectedIPL then
        homeData.data.interior = selectedIPL
        PlaceStoragesWardrobes(homeData)
        TriggerServerEvent("Housing:server:CreateHome", homeData)
    end
end)

function PlaceShell(interior, defaultCoords, initialPlacement)
    local shellList = {}
    local stepIndex = 5
    local moveStep = stepSettings[1][stepIndex]
    local rotStep = stepSettings[2][stepIndex]

    local function showKeybinds()
        if IsResourceStarted("bcs_hud") then
            exports.bcs_hud:keybind({
                title = string.format("Shell: %s, Step: %s | %s", interior, moveStep, rotStep),
                items = {
                    { description = locale("keybind_confirm_house"), buttons = { "ENTER" } },
                    { description = locale("keybind_cancel"), buttons = { "BACKSPACE" } },
                    { description = locale("keybind_rotate"), buttons = { "Q", "E" } },
                    { description = locale("keybind_adjust_height"), buttons = { "R", "F" } },
                    { description = locale("keybind_move_shell"), buttons = { "W", "A", "S", "D" } },
                    { description = locale("keybind_change_shell"), buttons = { "HOLD CTRL", "SCROLL UP/DOWN" } },
                    { description = locale("keybind_zoom"), buttons = { "HOLD SHIFT", "SCROLL UP/DOWN" } }
                }
            })
        else
            displayHelp(locale("prompt_create_shell", interior, moveStep, rotStep), "bottom-right")
        end
    end

    for shellName in pairs(Shells) do
        table.insert(shellList, shellName)
    end

    local shellIndex = 1
    for i = 1, #shellList do
        if shellList[i] == interior then
            shellIndex = i
            break
        end
    end

    if not DoesModelExists(interior) then
        print("[HOUSING] ^1Shell does not exists! Make sure it is loaded", interior)
        return {}
    end

    pcall(lib.requestModel, interior)

    shellCoords = {
        x = defaultCoords.x,
        y = defaultCoords.y,
        z = defaultCoords.z + 120.0
    }

    if initialPlacement then
        shellCoords = {
            x = initialPlacement.x,
            y = initialPlacement.y,
            z = initialPlacement.z
        }
    end

    local shellEntity = CreateObject(interior, shellCoords.x, shellCoords.y, shellCoords.z, false, false, false)
    SetModelAsNoLongerNeeded(interior)

    local camDistance = 15
    local currentHeading = GetEntityHeading(shellEntity)

    if initialPlacement then
        SetEntityHeading(shellEntity, initialPlacement.w)
    end

    currentCam = CreateCam("DEFAULT_SCRIPTED_CAMERA")

    local function updateCamPosition()
        SetEntityCoords(shellEntity, shellCoords.x, shellCoords.y, shellCoords.z)
        local rightVector, forwardVector, upVector, position = GetEntityMatrix(shellEntity)
        SetCamCoord(currentCam, ((position + rightVector * camDistance) + forwardVector * camDistance) + upVector * camDistance / 2)
    end

    updateCamPosition()
    SetEntityCollision(shellEntity, false)
    PointCamAtEntity(currentCam, shellEntity)
    SetCamActive(currentCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    showKeybinds()
    SetPlayerControl(PlayerId(), false)

    local function cleanup()
        DeleteEntity(shellEntity)
        RenderScriptCams(false)
        DestroyCam(currentCam, true)
        SetPlayerControl(PlayerId(), true)
        currentCam = nil
        shellEntity = nil
        closeHelp()
    end

    while true do
        if IsDisabledControlJustReleased(0, 32) then
            local camRotZ = GetCamRot(currentCam, 0).z
            local newX, newY = rotateCoords(vec2(shellCoords.x, shellCoords.y), vec2(shellCoords.x, shellCoords.y + moveStep), camRotZ)
            shellCoords.x = newX
            shellCoords.y = newY
            updateCamPosition()
        elseif IsDisabledControlJustReleased(0, 33) then
            local camRotZ = GetCamRot(currentCam, 0).z
            local newX, newY = rotateCoords(vec2(shellCoords.x, shellCoords.y), vec2(shellCoords.x, shellCoords.y - moveStep), camRotZ)
            shellCoords.x = newX
            shellCoords.y = newY
            updateCamPosition()
        elseif IsDisabledControlJustReleased(0, 35) then
            local camRotZ = GetCamRot(currentCam, 0).z
            local newX, newY = rotateCoords(vec2(shellCoords.x, shellCoords.y), vec2(shellCoords.x + moveStep, shellCoords.y), camRotZ)
            shellCoords.x = newX
            shellCoords.y = newY
            updateCamPosition()
        elseif IsDisabledControlJustReleased(0, 34) then
            local camRotZ = GetCamRot(currentCam, 0).z
            local newX, newY = rotateCoords(vec2(shellCoords.x, shellCoords.y), vec2(shellCoords.x - moveStep, shellCoords.y), camRotZ)
            shellCoords.x = newX
            shellCoords.y = newY
            updateCamPosition()
        elseif IsDisabledControlJustReleased(0, 44) then
            currentHeading = currentHeading + rotStep
            SetEntityHeading(shellEntity, currentHeading)
            shellCoords.w = currentHeading
        elseif IsDisabledControlJustReleased(0, 46) then
            currentHeading = currentHeading - rotStep
            SetEntityHeading(shellEntity, currentHeading)
            shellCoords.w = currentHeading
        elseif IsDisabledControlPressed(0, 45) then
            shellCoords.z = shellCoords.z + moveStep
            updateCamPosition()
        elseif IsDisabledControlPressed(0, 23) then
            shellCoords.z = shellCoords.z - moveStep
            updateCamPosition()
        elseif IsDisabledControlJustReleased(0, 17) then
            if IsDisabledControlPressed(0, 21) then
                if camDistance - 0.5 > 0.5 then
                    camDistance = camDistance - 0.5
                elseif camDistance - 0.5 > 0 then
                    camDistance = 0.5
                end
                updateCamPosition()
            elseif IsDisabledControlPressed(0, 36) then
                if shellIndex < #shellList then
                    shellIndex = shellIndex + 1
                    DeleteEntity(shellEntity)
                    interior = shellList[shellIndex]
                    showKeybinds()
                    RequestModel(shellList[shellIndex])
                    while not HasModelLoaded(shellList[shellIndex]) do
                        Wait(1000)
                    end
                    shellEntity = CreateObjectNoOffset(interior, shellCoords.x, shellCoords.y, shellCoords.z, false, false, false)
                    PointCamAtEntity(currentCam, shellEntity)
                end
            elseif not IsDisabledControlPressed(0, 19) and stepIndex < 11 then
                stepIndex = stepIndex + 1
                moveStep = stepSettings[1][stepIndex]
                rotStep = stepSettings[2][stepIndex]
                showKeybinds()
            end
        elseif IsDisabledControlJustReleased(0, 16) then
            if IsDisabledControlPressed(0, 21) then
                camDistance = camDistance + 0.5
                updateCamPosition()
            elseif IsDisabledControlPressed(0, 36) then
                if shellIndex > 1 then
                    shellIndex = shellIndex - 1
                    DeleteEntity(shellEntity)
                    interior = shellList[shellIndex]
                    showKeybinds()
                    if not DoesModelExists(shellList[shellIndex]) then
                        print("[HOUSING] ^1Shell does not exists! Make sure it is loaded", shellList[shellIndex])
                    else
                        RequestModel(shellList[shellIndex])
                        while not HasModelLoaded(shellList[shellIndex]) do
                            Wait(1000)
                        end
                        shellEntity = CreateObjectNoOffset(interior, shellCoords.x, shellCoords.y, shellCoords.z, false, false, false)
                        PointCamAtEntity(currentCam, shellEntity)
                    end
                end
            elseif not IsDisabledControlPressed(0, 19) and stepIndex > 1 then
                stepIndex = stepIndex - 1
                moveStep = stepSettings[1][stepIndex]
                rotStep = stepSettings[2][stepIndex]
                showKeybinds()
            end
        end

        if IsDisabledControlJustReleased(0, 176) then
            cleanup()
            return {
                shell = shellCoords,
                heading = currentHeading,
                interior = interior
            }
        end

        if IsDisabledControlJustReleased(0, 177) then
            cleanup()
            TriggerEvent("Housing:notify", "Housing", locale("canceled_house"), "warning", 3000)
            break
        end

        Wait(0)
    end
end

function SelectIPL(interiorName)
    local initialCoords = GetEntityCoords(cache.ped)

    local function showKeybinds()
        if IsResourceStarted("bcs_hud") then
            exports.bcs_hud:keybind({
                title = string.format("IPL: %s", interiorName),
                items = {
                    { description = locale("keybind_confirm_house"), buttons = { "ENTER" } },
                    { description = locale("keybind_cancel"), buttons = { "BACKSPACE" } },
                    { description = locale("keybind_rotate"), buttons = { "Q", "E" } },
                    { description = locale("keybind_change_ipl"), buttons = { "HOLD CTRL", "SCROLL UP/DOWN" } }
                }
            })
        else
            displayHelp(locale("prompt_create_ipl", interiorName), "bottom-right")
        end
    end

    local function setupIPLView()
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do
            Wait(10)
        end
        for i = 1, #CustomizeIPL do
            local ipl = CustomizeIPL[i]
            if ipl.name == interiorName then
                currentCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                RenderScriptCams(true, false, 0, true, false, 0)
                SetCamActive(currentCam, true)
                SetCamCoord(currentCam, ipl.entry.x, ipl.entry.y, ipl.entry.z)
                SetCamRot(currentCam, 0.0, 0.0, ipl.entry.w, 2)
                SetEntityCoords(cache.ped, ipl.entry.x, ipl.entry.y, ipl.entry.z)
                SetEntityAlpha(cache.ped, 0, false)
                break
            end
        end
        Wait(500)
        DoScreenFadeIn(500)
        showKeybinds()
    end

    local function cleanupIPLView()
        if currentCam then
            SetCamActive(currentCam, false)
            DestroyCam(currentCam, false)
            RenderScriptCams(false, false, 0, true, false)
            SetEntityAlpha(cache.ped, 255, false)
            SetEntityCoords(cache.ped, initialCoords.x, initialCoords.y, initialCoords.z)
        end
    end

    local function switchIPL(isNext)
        local currentIndex = nil
        for i = 1, #CustomizeIPL do
            if CustomizeIPL[i].name == interiorName then
                currentIndex = i
                break
            end
        end
        if not currentIndex then
            return
        end
        local nextIndex = isNext and (currentIndex + 1) or (currentIndex - 1)
        if CustomizeIPL[nextIndex] then
            interiorName = CustomizeIPL[nextIndex].name
            setupIPLView()
        end
    end

    setupIPLView()

    while true do
        if IsDisabledControlJustReleased(0, 17) then
            if IsDisabledControlPressed(0, 36) then
                switchIPL(true)
            end
        elseif IsDisabledControlJustReleased(0, 16) then
            if IsDisabledControlPressed(0, 36) then
                switchIPL(false)
            end
        end

        if IsDisabledControlPressed(0, 44) then
            local rot = GetCamRot(currentCam, 2)
            SetCamRot(currentCam, rot.x, rot.y, rot.z + 1.0, 2)
        elseif IsDisabledControlPressed(0, 46) then
            local rot = GetCamRot(currentCam, 2)
            SetCamRot(currentCam, rot.x, rot.y, rot.z - 1.0, 2)
        end

        if IsDisabledControlJustReleased(0, 176) then
            break
        end

        if IsDisabledControlJustReleased(0, 177) then
            TriggerEvent("Housing:notify", "Housing", locale("canceled_house"), "warning", 3000)
            interiorName = nil
            break
        end

        Wait(0)
    end

    cleanupIPLView()
    closeHelp()
    return interiorName
end

function CreateThumbnail()
    local screenshot = nil
    local animDict = "amb@world_human_paparazzi@male@base"
    local animName = "base"
    local propModel = "prop_pap_camera_01"

    lib.requestAnimDict(animDict)
    pcall(lib.requestModel, propModel)

    local cameraEntity = CreateObjectNoOffset(propModel, 0, 0, 0, false, false, false)
    AttachEntityToEntity(cameraEntity, cache.ped, GetPedBoneIndex(cache.ped, 28422),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        false, false, false, false, 2, true)
    TaskPlayAnim(cache.ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(propModel)

    Wait(2000)
    SetEntityVisible(cache.ped, false, false)
    displayHelp(locale("prompt_create_thumbnail"), "bottom-right")

    while true do
        SetFollowPedCamViewMode(4)
        if IsControlJustPressed(0, 18) then
            if PlaySoundFrontend then
                PlaySoundFrontend(-1, "Camera_Shoot", "Phone_SoundSet_Michael", true)
            end
            closeHelp()
            screenshot = GetScreenshot()
            Wait(500)
            break
        end
        Wait(0)
    end

    closeHelp()
    SetEntityVisible(cache.ped, true, false)
    StopAnimTask(cache.ped, animDict, animName, 1.0)
    DeleteObject(cameraEntity)
    SetFollowPedCamViewMode(1)
    return screenshot
end