local BCSHousing = exports[GetCurrentResourceName()]
local isScreenshotFinished = false

local function takeInteriorScreenshot(houseType, interiorName)
    local screenshotName = nil
    if houseType and interiorName then
        local shellEntity = nil
        DisplayRadar(false)
        SetEntityVisible(cache.ped, false)
        if houseType == "ipl" then
            for i = 1, #CustomizeIPL do
                if CustomizeIPL[i].name == interiorName then
                    entry = CustomizeIPL[i].entry
                    SetEntityCoordsNoOffset(PlayerPedId(), entry)
                    SetEntityHeading(PlayerPedId(), entry)
                    inside = true
                    break
                end
            end
            if not inside then
                Notify(locale("housing"), locale("interior_not_found"), "error", 3000)
                return
            end
        elseif houseType == "shell" then
            for modelName in pairs(Shells) do
                if modelName == interiorName then
                    DoScreenFadeOut(500)
                    while not IsScreenFadedOut() do
                        Wait(10)
                    end
                    if not DoesModelExists(modelName) then
                        print("[HOUSING] ^1Shell does not exists! Make sure it is loaded", modelName)
                        DoScreenFadeIn(500)
                        break
                    end
                    RequestModel(modelName)
                    while not HasModelLoaded(modelName) do
                        Wait(1000)
                    end
                    local shellOffsets = Shells[modelName]
                    shellEntity = CreateShell(modelName)
                    SetEntityCoordsNoOffset(PlayerPedId(), GetOffsetFromEntityInWorldCoords(shellEntity, shellOffsets.x, shellOffsets.y, shellOffsets.z))
                    Wait(500)
                    DoScreenFadeIn(500)
                    inside = true
                    ToggleSyncTime()
                    break
                end
            end
            if not inside then
                Notify(locale("housing"), locale("interior_not_found"), "error", 3000)
                return
            end
        end
        Wait(1000)
        if inside then
            BCSHousing:SetActive(true)
            HelpText(true, locale("prompt_screenshot_interior"))
            while true do
                Wait(0)
                DisableControlAction(0, 74, true)
                if IsDisabledControlJustReleased(0, 74) then
                    if Config.Screenshot == "offline" then
                        screenshotName = interiorName
                        isScreenshotFinished = false
                        TriggerServerEvent("takeScreenshot", interiorName:gsub("%s+", ""), "interior")
                        while not isScreenshotFinished do
                            Wait(250)
                        end
                    else
                        print(GetScreenshot())
                    end
                    Wait(250)
                    SetEntityVisible(cache.ped, true)
                    DisplayRadar(true)
                    BCSHousing:SetActive(false)
                    inside = false
                    DoScreenFadeOut(500)
                    while not IsScreenFadedOut() do
                        Wait(10)
                    end
                    SetEntityCoords(cache.ped, GetEntityCoords(cache.ped))
                    if shellEntity then
                        DeleteEntity(shellEntity)
                    end
                    Wait(500)
                    DoScreenFadeIn(500)
                    HelpText(false)
                    break
                end
            end
        end
        return screenshotName
    end
end

RegisterNUICallback("recreateThumbnail", function(data, cb)
    ToggleNuiFrame(false)
    TriggerServerEvent("Housing:server:SetThumbnail", data.interior, takeInteriorScreenshot(data.houseType, data.interior))
    cb({})
end)

if Config.debug then
    local whiteRoom = nil

    RegisterCommand(commands.screenshotfurniture.name, function(source, args)
        local model = args[1]
        if not model then
            return
        end
        if not DoesModelExists(model) then
            print("[Furniture] Model is invalid")
            return
        end
        pcall(lib.requestModel, model)
        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        RenderScriptCams(true, false, 0, true, false, 0)
        SetPlayerControl(PlayerId(), false)
        pcall(lib.requestModel, "whiteroom")
        local pedCoords = GetEntityCoords(cache.ped)
        whiteRoom = CreateObject(542699803, pedCoords.x, pedCoords.y, pedCoords.z - 10, false, false)
        SetModelAsNoLongerNeeded("whiteroom")
        local roomCoords = GetEntityCoords(whiteRoom)
        DisplayRadar(false)
        local furnitureObj = CreateObject(GetHashKey(model), roomCoords.x, roomCoords.y, roomCoords.z, false, false)
        SetModelAsNoLongerNeeded(model)
        local forwardVector = GetEntityForwardVector(furnitureObj)
        local minDim, maxDim = GetModelDimensions(GetHashKey(model))
        local size = maxDim - minDim
        local centerCoords = GetEntityCoords(furnitureObj, false) + (minDim + maxDim) / 2
        local maxDimension = math.max(size.x, size.z)
        local camCoords = vec3(
            centerCoords.x + forwardVector.x * 1.2 + maxDimension / 2,
            centerCoords.y + forwardVector.y * 1.2 + maxDimension / 2,
            centerCoords.z + forwardVector.z
        )
        SetCamCoord(cam, camCoords)
        SetCamFov(cam, math.min((maxDimension / 0.15) * 10, 60) + 0.0)
        PointCamAtCoord(cam, centerCoords.x, centerCoords.y, centerCoords.z)
        FreezeEntityPosition(furnitureObj, true)
        displayHelp(locale("prompt_screenshot_furniture"), "bottom-right")
        while true do
            DisableControlAction(0, 38, true)
            DisableControlAction(0, 190, true)
            DisableControlAction(0, 189, true)
            DisableControlAction(0, 187, true)
            DisableControlAction(0, 188, true)
            DisableControlAction(0, 74, true)
            DisableControlAction(0, 96, true)
            DisableControlAction(0, 97, true)
            if IsDisabledControlJustPressed(0, 38) then
                PlaySoundFrontend(-1, "HUD_AWARDS", "COLLECTED")
                break
            end
            if IsDisabledControlJustPressed(0, 189) then
                SetEntityHeading(furnitureObj, GetEntityHeading(furnitureObj) - 15)
            elseif IsDisabledControlJustPressed(0, 190) then
                SetEntityHeading(furnitureObj, GetEntityHeading(furnitureObj) + 15)
            elseif IsDisabledControlPressed(0, 187) then
                SetCamCoord(cam, camCoords + vec3(0.1, 0.1, 0.0))
            elseif IsDisabledControlPressed(0, 188) then
                SetCamCoord(cam, camCoords - vec3(0.1, 0.1, 0.0))
            end
            if IsDisabledControlJustPressed(0, 74) then
                SetEntityHeading(furnitureObj, GetEntityHeading(furnitureObj) + 180)
            end
            if IsDisabledControlPressed(0, 96) then
                SetCamCoord(cam, camCoords - vec3(0.0, 0.0, 0.1))
            elseif IsDisabledControlPressed(0, 97) then
                SetCamCoord(cam, camCoords + vec3(0.0, 0.0, 0.1))
            end
            Wait(0)
        end
        local screenshotData
        if Config.Screenshot == "offline" then
            screenshotData = model
            isScreenshotFinished = false
            TriggerServerEvent("takeScreenshot", model, "furnitures")
            while not isScreenshotFinished do
                Wait(250)
            end
        else
            screenshotData = GetScreenshot()
        end
        TriggerServerEvent("bcs_housing:server:SaveThumbnail", {
            img = screenshotData,
            model = model
        })
        Wait(250)
        DeleteEntity(furnitureObj)
        DisplayRadar(true)
        SetPlayerControl(PlayerId(), true)
        RenderScriptCams(false, false, 1, 1, 1)
        DestroyCam(cam)
        DeleteEntity(whiteRoom)
        closeHelp()
        whiteRoom = nil
    end, false)

    RegisterCommand("stopfurniturescreenshot", function()
        DestroyAllCams()
        SetPlayerControl(PlayerId(), true)
        RenderScriptCams(false, false, 1, 1, 1)
        DeleteEntity(whiteRoom)
        whiteRoom = nil
        DisplayRadar(true)
    end, false)

    RegisterNetEvent("continueScreenshot", function()
        isScreenshotFinished = true
    end)

    RegisterCommand(commands.startfurniturescreenshot.name, function(source, args)
        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        RenderScriptCams(true, false, 0, true, false, 0)
        SetPlayerControl(PlayerId(), false)
        pcall(lib.requestModel, "whiteroom")
        local pedCoords = GetEntityCoords(cache.ped)
        whiteRoom = CreateObject(542699803, pedCoords.x, pedCoords.y, pedCoords.z - 10, false, false)
        SetModelAsNoLongerNeeded("whiteroom")
        local roomCoords = GetEntityCoords(whiteRoom)
        DisplayRadar(false)
        for _, category in pairs(FurnitureList) do
            for _, furniture in pairs(category.list) do
                pcall(function()
                    local modelHash = GetHashKey(furniture.model)
                    local imageExists = FurnitureImages[tostring(modelHash)]
                    print(imageExists, furniture.model, modelHash)
                    if not imageExists and DoesModelExists(furniture.model) then
                        pcall(lib.requestModel, furniture.model)
                        local furnitureObj = CreateObject(GetHashKey(furniture.model), roomCoords.x, roomCoords.y, roomCoords.z, false, false)
                        SetModelAsNoLongerNeeded(furniture.model)
                        local forwardVector = GetEntityForwardVector(furnitureObj)
                        local minDim, maxDim = GetModelDimensions(GetHashKey(furniture.model))
                        local size = maxDim - minDim
                        local centerCoords = GetEntityCoords(furnitureObj, false) + (minDim + maxDim) / 2
                        local maxDimension = math.max(size.x, size.z)
                        local camCoords = vec3(
                            centerCoords.x + forwardVector.x * 1.2 + maxDimension / 2,
                            centerCoords.y + forwardVector.y * 1.2 + maxDimension / 2,
                            centerCoords.z + forwardVector.z
                        )
                        SetCamCoord(cam, camCoords)
                        SetCamFov(cam, math.min((maxDimension / 0.15) * 10, 60) + 0.0)
                        PointCamAtCoord(cam, centerCoords.x, centerCoords.y, centerCoords.z)
                        FreezeEntityPosition(furnitureObj, true)
                        if args[1] == "control" then
                            displayHelp(locale("prompt_screenshot_furniture"), "bottom-right")
                            while true do
                                if IsDisabledControlJustPressed(0, 38) then
                                    PlaySoundFrontend(-1, "HUD_AWARDS", "COLLECTED")
                                    break
                                end
                                if IsDisabledControlJustPressed(0, 189) then
                                    SetEntityHeading(furnitureObj, GetEntityHeading(furnitureObj) - 15)
                                elseif IsDisabledControlJustPressed(0, 190) then
                                    SetEntityHeading(furnitureObj, GetEntityHeading(furnitureObj) + 15)
                                elseif IsDisabledControlPressed(0, 187) then
                                    SetCamCoord(cam, camCoords + vec3(0.1, 0.1, 0.0))
                                elseif IsDisabledControlPressed(0, 188) then
                                    SetCamCoord(cam, camCoords - vec3(0.1, 0.1, 0.0))
                                end
                                if IsDisabledControlJustPressed(0, 74) then
                                    SetEntityHeading(furnitureObj, GetEntityHeading(furnitureObj) + 180)
                                end
                                if IsDisabledControlPressed(0, 96) then
                                    SetCamCoord(cam, camCoords - vec3(0.0, 0.0, 0.1))
                                elseif IsDisabledControlPressed(0, 97) then
                                    SetCamCoord(cam, camCoords + vec3(0.0, 0.0, 0.1))
                                end
                                Wait(0)
                            end
                            closeHelp()
                        end
                        local screenshotData
                        if Config.Screenshot == "offline" then
                            screenshotData = furniture.model
                            isScreenshotFinished = false
                            TriggerServerEvent("takeScreenshot", furniture.model, "furnitures")
                            while not isScreenshotFinished do
                                Wait(250)
                            end
                        else
                            screenshotData = GetScreenshot()
                        end
                        TriggerServerEvent("bcs_housing:server:SaveThumbnail", {
                            img = screenshotData,
                            model = furniture.model
                        })
                        Wait(250)
                        DeleteEntity(furnitureObj)
                    end
                end)
            end
        end
        DisplayRadar(true)
        SetPlayerControl(PlayerId(), true)
        RenderScriptCams(false, false, 1, 1, 1)
        DestroyCam(cam)
        DeleteEntity(whiteRoom)
        whiteRoom = nil
    end, false)

    RegisterCommand(commands.screenshotinterior.name, function(source, args, rawCommand)
        local houseType = args[1]
        takeInteriorScreenshot(houseType, rawCommand:gsub(commands.screenshotinterior.name .. " " .. houseType .. " ", ""))
    end, false)
end
RegisterNetEvent('Housing:client:TakeScreenshot', function(name, screenshotType)
    local ok, err = pcall(function()
        if screenshotType == 'interior' then
            local image = takeInteriorScreenshot and takeInteriorScreenshot(nil, name) or nil
            if image then TriggerServerEvent('Housing:server:SetThumbnail', name, image) end
        elseif screenshotType == 'furnitures' then
            TriggerServerEvent('takeScreenshot', name, 'furnitures')
        end
    end)

    if not ok then
        print(('[bcs_housing] screenshot gagal: %s'):format(err))
    end
end)