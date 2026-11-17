cameraOpen = false
local selfieMode = false
local videoMode = false
local hudHidden = false
local recordingPeerId = nil
local albumTypeMap = {
    selfies = "selfie",
    screenshots = "screenshot",
    imports = "import"
}

local function startGtaCam()
    TogglePhoneAnimation(false, "camera")
    CreateMobilePhone(0)
    CellCamActivate(true, true)
    CellCamActivateSelfieMode(selfieMode)
    SetTimeout(500, function()
        local objects = GetGamePool("CObject")
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #objects do
            local object = objects[i]
            if #(coords - GetEntityCoords(object)) < 4.0 then
                if GetEntityModel(object) == 413312110 then
                    SetEntityAsMissionEntity(object, true, true)
                    DeleteObject(object)
                end
            end
        end
    end)
    while true do
        if not phoneOpen then
            break
        end
        if not cameraOpen then
            break
        end
        if IsWalkingCamEnabled() then
            break
        end
        Wait(250)
        InvalidateIdleCam()
        InvalidateVehicleIdleCam()
    end
    if cameraOpen then
        TogglePhoneAnimation(true, "camera")
    elseif phoneOpen then
        TogglePhoneAnimation(true)
    end
    DestroyMobilePhone()
    if cameraOpen then
        if not IsWalkingCamEnabled() then
            while true do
                if phoneOpen then
                    break
                end
                Wait(500)
            end
            startGtaCam()
        end
    end
end

local function parseFilter(filter)
    if filter.album == "recents" then
        filter.album = nil
    elseif filter.album == "favourites" then
        filter.album = nil
        filter.favourites = true
    end
    if filter.type == "videos" then
        filter = {
            showPhotos = false,
            showVideos = true
        }
    end
    if filter.type then
        filter.album = nil
        if albumTypeMap[filter.type] then
            filter.type = albumTypeMap[filter.type]
        else
            filter.type = nil
            filter.duplicates = true
        end
    end
    if not filter.showPhotos and not filter.showVideos then
        filter.showPhotos = true
        filter.showVideos = true
    end
    return filter
end

local function getUploadApi(uploadType)
    local method = nil
    if CustomGetUploadMethod then
        method = CustomGetUploadMethod(uploadType)
    else
        if not UploadMethods then
            infoprint("error", "Upload methods not found")
            return "No upload methods found. The server devs have broken the upload.lua file. Tell the server devs to reinstall lb-phone."
        end
        local methods = UploadMethods[Config.UploadMethod[uploadType]]
        if not methods then
            infoprint("error", "Upload methods not found for ", uploadType)
            return "No upload methods found for '" .. tostring(Config.UploadMethod[uploadType]) .. "'. Tell the server devs to reinstall lb-phone."
        end
        method = methods[uploadType] or methods.Default
        if not method then
            infoprint("error", "Upload method not found for ", uploadType)
            return "No upload method found for '" .. uploadType .. "' using '" .. tostring(Config.UploadMethod[uploadType]) .. "'. Tell the server devs to reinstall lb-phone."
        end
    end
    if not method.method then
        method.method = Config.UploadMethod[uploadType]
    end
    if method.sendPlayer then
        if not method.player then
            method.player = {
                identifier = GetIdentifier(),
                name = GetPlayerName(PlayerId())
            }
        end
    end
    local needsApiKey = false
    if method.url:find("API_KEY") then
        needsApiKey = true
    elseif method.headers then
        for _, header in pairs(method.headers) do
            if header:find("API_KEY") then
                needsApiKey = true
                break
            end
        end
    end
    if needsApiKey then
        local apiKey = AwaitCallback("camera:getUploadApiKey", uploadType)
        method.url = method.url:gsub("API_KEY", apiKey)
        if method.headers then
            for key, header in pairs(method.headers) do
                method.headers[key] = header:gsub("API_KEY", apiKey)
            end
        end
    end
    if method.url:find("PRESIGNED_URL") then
        local presignedUrl = AwaitCallback("camera:getPresignedUrl", uploadType)
        if not presignedUrl then
            infoprint("error", "Failed to get presigned url for " .. uploadType)
            return "Failed to get presigned url for '" .. uploadType .. "'. The devs have most likely not set a valid token in lb-phone/server/apiKeys.lua. Tell the server devs to check the console for errors."
        end
        method.presignedUrl = presignedUrl
    end
    return method
end

local function getCameraButtons()
    local buttons = {}
    local keybinds = Config.KeyBinds
    if keybinds.TakePhoto and keybinds.TakePhoto.Command and keybinds.TakePhoto.bindData then
        buttons[#buttons + 1] = L("BACKEND.CAMERA.TAKE_PHOTO", { key = keybinds.TakePhoto.bindData.instructional })
    end
    if keybinds.FlipCamera and keybinds.FlipCamera.Command and keybinds.FlipCamera.bindData then
        buttons[#buttons + 1] = L("BACKEND.CAMERA.FLIP_CAMERA", { key = keybinds.FlipCamera.bindData.instructional })
    end
    if keybinds.ToggleFlash and keybinds.ToggleFlash.Command and keybinds.ToggleFlash.bindData then
        buttons[#buttons + 1] = L("BACKEND.CAMERA.TOGGLE_FLASH", { key = keybinds.ToggleFlash.bindData.instructional })
    end
    if keybinds.LeftMode and keybinds.LeftMode.Command and keybinds.LeftMode.bindData and keybinds.RightMode and keybinds.RightMode.Command and keybinds.RightMode.bindData then
        buttons[#buttons + 1] = L("BACKEND.CAMERA.CHANGE_MODE", {
            key = keybinds.LeftMode.bindData.instructional,
            key2 = keybinds.RightMode.bindData.instructional
        })
    end
    if keybinds.RollLeft and keybinds.RollLeft.Command and keybinds.RollLeft.bindData and keybinds.RollRight and keybinds.RollRight.Command and keybinds.RollRight.bindData then
        buttons[#buttons + 1] = L("BACKEND.CAMERA.ROLL", {
            key = keybinds.RollLeft.bindData.instructional,
            key2 = keybinds.RollRight.bindData.instructional
        })
    end
    if Config.Camera and Config.Camera.Freeze and Config.Camera.Freeze.Enabled and keybinds.FreezeCamera and keybinds.FreezeCamera.Command and keybinds.FreezeCamera.bindData then
        buttons[#buttons + 1] = L("BACKEND.CAMERA.FREEZE", { key = keybinds.FreezeCamera.bindData.instructional })
    end
    if keybinds.Focus and keybinds.Focus.Command and keybinds.Focus.bindData then
        buttons[#buttons + 1] = L("BACKEND.CAMERA.TOGGLE_CURSOR", { key = keybinds.Focus.bindData.instructional })
    end
    return buttons
end

RegisterNUICallback("Camera", function(data, cb)
    if not currentPhone then
        return
    end
    if not data then
        return debugprint("Camera data is nil")
    end
    local action = data.action
    debugprint("Camera:" .. (action or ""))
    if action == "open" then
        cb("ok")
        cameraOpen = true
        DisplayCameraButtons(getCameraButtons())
        if Config.Camera and Config.Camera.Walkable then
            debugprint("Using walkable cam")
            EnableWalkableCam()
        else
            debugprint("Using native GTA cam")
            startGtaCam()
        end
    elseif action == "saveToGallery" then
        TriggerCallback("camera:saveToGallery", cb, data.link, data.size, data.isVideo and true or false, data.type, data.shouldLog)
    elseif action == "updateImage" then
        TriggerCallback("camera:updateImage", cb, data.id, data.src, data.size)
    elseif action == "deleteFromGallery" then
        if type(data.ids) ~= "table" then
            data.ids = { data.ids }
        end
        TriggerCallback("camera:deleteFromGallery", cb, data.ids)
    elseif action == "getLastImage" then
        TriggerCallback("camera:getLastImage", cb)
    elseif action == "getImages" then
        local filter = parseFilter(data.filter or {})
        local images = AwaitCallback("camera:getImages", filter, data.page or 0)
        local result = {}
        for i = 1, #images do
            local image = images[i]
            result[i] = {
                id = image.id,
                src = image.link,
                isVideo = image.is_video,
                type = image.metadata,
                favourite = image.is_favourite,
                timestamp = image.timestamp,
                size = image.size or 0
            }
        end
        cb(result)
    elseif action == "getAlbums" then
        TriggerCallback("camera:getHomePageData", cb)
    elseif action == "createAlbum" then
        TriggerCallback("camera:createAlbum", cb, data.title)
    elseif action == "renameAlbum" then
        TriggerCallback("camera:renameAlbum", cb, data.id, data.title)
    elseif action == "addToAlbum" then
        TriggerCallback("camera:addToAlbum", cb, data.album, data.ids)
    elseif action == "removeFromAlbum" then
        TriggerCallback("camera:removeFromAlbum", cb, data.album, data.ids)
    elseif action == "deleteAlbum" then
        TriggerCallback("camera:deleteAlbum", cb, data.id)
    elseif action == "removeMemberFromAlbum" then
        TriggerCallback("camera:removeMemberFromAlbum", cb, data.number, data.album)
    elseif action == "leaveSharedAlbum" then
        TriggerCallback("camera:leaveSharedAlbum", cb, data.id)
    elseif action == "getAlbumMembers" then
        TriggerCallback("camera:getAlbumMembers", cb, data.id)
    elseif action == "toggleFavourites" then
        TriggerCallback("camera:toggleFavourites", cb, data.favourite, data.ids)
    elseif action == "toggleVideo" then
        if videoMode == data.toggled then
            return cb("ok")
        end
        videoMode = data.toggled
        cameraOpen = true
        cb("ok")
        SendNUIAction("camera:toggleMicrophone", IsTalking())
        if videoMode or (Config.Camera and Config.Camera.Walkable) then
            EnableWalkableCam(selfieMode)
        else
            DisableWalkableCam()
            startGtaCam()
        end
    elseif action == "toggleHud" then
        hudHidden = not data.toggled
        TriggerEvent("lb-phone:toggleHud", hudHidden)
        ToggleHudComponents(not data.toggled)
        Wait(100)
        cb(true)
    elseif action == "getUploadApi" then
        cb(getUploadApi(data.uploadType) or false)
    elseif action == "toggleLandscape" then
        LocalPlayer.state:set("phoneLandscape", data.toggled == true or nil, true)
        if data.toggled then
            AttachPhone({ landscape = true })
        else
            AttachPhone()
        end
        cb("ok")
    elseif action == "flipCamera" then
        data.value = data.value == true
        if selfieMode == data.value then
            return cb("ok")
        end
        selfieMode = data.value
        if IsWalkingCamEnabled() then
            ToggleSelfieCam(selfieMode)
        else
            CellCamActivateSelfieMode(selfieMode)
        end
        cb("ok")
    elseif action == "setQuickZoom" then
        if IsWalkingCamEnabled() then
            SetCameraZoom(data.value)
        end
        cb(true)
    elseif action == "setRecordingPeerId" then
        TriggerServerEvent("phone:camera:setPeer", data.peerId)
        recordingPeerId = data.peerId
        cb("ok")
    else
        if action == "endedRecording" then
            if recordingPeerId then
                TriggerServerEvent("phone:camera:endedRecording", recordingPeerId)
                recordingPeerId = nil
                cb("ok")
            end
        elseif action == "close" then
            cameraOpen = false
            videoMode = false
            selfieMode = false
            StopDisplayingCameraButtons()
            DisableWalkableCam()
            if LocalPlayer.state.phoneLandscape then
                LocalPlayer.state:set("phoneLandscape", nil, true)
            end
            cb("ok")
        end
    end
end)

RegisterNUICallback("isExternalImageAllowed", function(data, cb)
    return cb(IsMediaLinkAllowed(data.url))
end)

exports("SaveToGallery", function(link)
    assert(type(link) == "string", "Expected string for link, got " .. type(link))
    SendNUIAction("saveMedia", link)
end)

RegisterNetEvent("phone:photos:addMemberToAlbum", function(albumId, phoneNumber)
    SendNUIAction("photos:addMemberToAlbum", { albumId = albumId, phoneNumber = phoneNumber })
end)

RegisterNetEvent("phone:photos:removeMemberFromAlbum", function(albumId, phoneNumber)
    SendNUIAction("photos:removeMemberFromAlbum", { albumId = albumId, phoneNumber = phoneNumber })
end)

RegisterNetEvent("phone:photos:addSharedAlbum", function(data)
    SendNUIAction("photos:addSharedAlbum", data)
end)

RegisterNetEvent("phone:photos:updateAlbum", function(data)
    debugprint("phone:photos:updateAlbum", data)
    SendNUIAction("photos:updateAlbum", data)
end)

exports("IsCameraOpen", function()
    return cameraOpen
end)
