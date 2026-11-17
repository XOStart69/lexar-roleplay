interface.init()

local camera = false
local cameraprop = nil
local walkMode = false
local effectMenuOpen = false
local onTakePhoto = false

local effects = require 'interface.rhd_photo_system.modules.effects'

local FOV_MAX = 80.0
local FOV_MIN = 5.0
local ZOOM_SPEED = 10.0
local SPEED_LEFT_RIGHT = 8.0
local SPEED_UP_DOWN = 8.0

local ROLL_SPEED = 3.0
local ROLL_MAX = 45.0
local ROLL_MIN = -45.0
local cameraRoll = 0.0

local fov = (FOV_MAX + FOV_MIN) * 0.5

local LETTERBOX = 0.1
local pdHudOpen = false
local captureStreet = nil
local captureStamp = nil

local function drawText(text, x, y, scale, alpha, rightAlign)
    SetTextFont(4)
    SetTextScale(0.0, scale)
    SetTextColour(255, 255, 255, alpha)
    SetTextDropshadow(0, 0, 0, 0, 0)
    SetTextOutline()
    if rightAlign then
        SetTextJustification(2)
        SetTextWrap(0.0, x)
    else
        SetTextJustification(1)
    end
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawCinematic()
    DrawRect(0.5, LETTERBOX * 0.5, 1.0, LETTERBOX, 0, 0, 0, 255)
    DrawRect(0.5, 1.0 - LETTERBOX * 0.5, 1.0, LETTERBOX, 0, 0, 0, 255)

    if captureStamp then
        drawText(captureStreet, 0.03, 1.0 - LETTERBOX + 0.018, 0.5, 240, false)
        drawText(captureStamp, 0.03, 1.0 - LETTERBOX + 0.052, 0.36, 200, false)
    end
end

---@return string
local function getStreetLabel()
    local coords = GetEntityCoords(cache.ped)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local cross = crossHash ~= 0 and GetStreetNameFromHashKey(crossHash) or ''

    if street == '' then
        street = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    end

    return cross ~= '' and ('%s / %s'):format(street, cross) or street
end

local function hideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(13)
    HideHudComponentThisFrame(14)
    HideHudComponentThisFrame(11)
    HideHudComponentThisFrame(12)
    HideHudComponentThisFrame(15)
    HideHudComponentThisFrame(18)
    HideHudComponentThisFrame(19)
end

local function selectEffect(name)
    local effect = lib.array.find(effects, function(e) return e.name == name end)

    if not effect then
        return lib.notify({
            description = 'Effect not found: ' .. name,
            type = 'error'
        })
    end

    return pcall(function(...)
        effect.onUse()
    end)
end

interface.callback('selectEffect', function(data, cb)
    cb('ok')

    local success = selectEffect(data.name)

    if pdHudOpen and success then
        local effect = lib.array.find(effects, function(e) return e.name == data.name end)
        interface.send({ action = 'updatePdCameraHUD', data = { effect = effect.label } })
    end

    print(('Effect %s: %s'):format(data.name, (success and 'applied' or 'failed')))
end)

interface.callback('closeEffectMenu', function(_, cb)
    effectMenuOpen = false
    interface.focus(false, false)
    cb('ok')
end)

local function checkInputRotation(cam, zoomvalue)
    local rightAxisX = GetControlNormal(0, 220)
    local rightAxisY = GetControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)

    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * SPEED_UP_DOWN * (zoomvalue + 0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * SPEED_LEFT_RIGHT * (zoomvalue + 0.1)),
            -89.5)

        local smoothRoll = rotation.y + (cameraRoll - rotation.y) * 0.1
        SetCamRot(cam, new_x, smoothRoll, new_z, 2)

        if not IsPedSittingInAnyVehicle(cache.ped) then
            SetEntityHeading(cache.ped, new_z)
        end
    end
end

local function handleZoom(cam)
    local isShiftHeld = IsControlPressed(0, 21)

    local scrollUp, scrollDown

    if not IsPedSittingInAnyVehicle(cache.ped) then
        scrollUp = IsDisabledControlJustPressed(0, 241)
        scrollDown = IsDisabledControlJustPressed(0, 242)
    else
        scrollUp = IsDisabledControlJustPressed(0, 17)
        scrollDown = IsDisabledControlJustPressed(0, 16)
    end

    if isShiftHeld then
        if scrollUp then cameraRoll = math.max(cameraRoll - ROLL_SPEED, ROLL_MIN) end
        if scrollDown then cameraRoll = math.min(cameraRoll + ROLL_SPEED, ROLL_MAX) end
    else
        if scrollUp then fov = math.max(fov - ZOOM_SPEED, FOV_MIN) end
        if scrollDown then fov = math.min(fov + ZOOM_SPEED, FOV_MAX) end
    end

    local current_fov = GetCamFov(cam)
    if math.abs(fov - current_fov) < 0.1 then fov = current_fov end
    SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)

    if GetControlNormal(0, 220) == 0.0 and GetControlNormal(0, 221) == 0.0 then
        local current_rot = GetCamRot(cam, 2)
        local smoothRoll  = current_rot.y + (cameraRoll - current_rot.y) * 0.1
        if math.abs(smoothRoll - current_rot.y) > 0.01 then
            SetCamRot(cam, current_rot.x, smoothRoll, current_rot.z, 2)
        end
    end
end

local function createCam()
    local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    AttachCamToEntity(cam, cache.ped, 0.0, 1.0, 0.8, true)
    SetCamRot(cam, 0.0, 0.0, GetEntityHeading(cache.ped), 2)
    SetCamFov(cam, fov)
    RenderScriptCams(true, false, 0, true, false)
    return cam
end

local function destroyCam(cam)
    ClearTimecycleModifier()
    fov        = (FOV_MAX + FOV_MIN) * 0.5
    cameraRoll = 0.0
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    SetNightvision(false)
    SetSeethrough(false)
end

---@return { photoId: string, url: string }?
local function uploadPhoto()
    local presigned = lib.callback.await('rhd_photo_system:requestUpload', false)
    if not presigned then return end

    local resp = interface.capture(presigned, { encoding = 'jpg', quality = 0.85 })
    local url = resp and type(resp.data) == 'table' and resp.data.url
    if not url then return end

    return lib.callback.await('rhd_photo_system:savePhoto', false, url)
end

---@return boolean?
local function uploadPdPhoto()
    local street = getStreetLabel()
    local upload = lib.callback.await('rhd_photo_system:pdRequestUpload', false)
    if not upload then return end

    captureStreet = street
    captureStamp = upload.stamp
    interface.send({ action = 'closePdCameraHUD' })
    Wait(100)

    local resp = interface.capture(upload.url, { encoding = 'jpg', quality = 0.9 })
    local url = resp and type(resp.data) == 'table' and resp.data.url
    captureStamp = nil
    captureStreet = nil
    if camera then
        interface.send({ action = 'openPdCameraHUD', data = {} })
    end
    if not url then return end

    return lib.callback.await('rhd_photo_system:pdSavePhoto', false, url, street)
end

local instrucional = [[
Ambil foto  - Mouse [left]
Batalkan    - Mouse [right]
Ganti mode  - G
Effect      - E
Zoom        - Scroll
Rotasi      - Shift + Scroll
]]

---@param opts? { pd?: boolean }
return function(opts)
    if camera then return end

    local pdMode = opts and opts.pd or false
    local infoId = pdMode and 'rhd_photo:pdcamera' or 'pimpound:camera'

    camera = true
    lib.playAnim(cache.ped, "amb@world_human_paparazzi@male@base", 'base', 6.0, 3.0, -1, 49, 1.0, false, false, false)

    local cameraModel = lib.requestModel(`prop_pap_camera_01`)
    if cameraModel then
        local coords = GetEntityCoords(cache.ped)
        cameraprop = CreateObject(cameraModel, coords.x, coords.y, coords.z + 0.2, true, true, true)
        AttachEntityToEntity(cameraprop, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true,
            true, false, true, 1, true)
    end

    local p = promise.new()
    CreateThread(function()
        Wait(500)

        SetTimecycleModifier("default")
        SetTimecycleModifierStrength(0.3)

        local result
        local cam = createCam()
        local lastZoom, lastStreet, nextStreetCheck = 0, '', 0

        if pdMode then
            pdHudOpen = true
            playerState:set('pdCameraOpen', true, false)
            if SM_HUD and SM_HUD.visible then
                SM_HUD.setVisible(false)
                pcall(function() exports['sm_bodycam']:hideBodycamHud(true) end)
            end
            lastStreet = getStreetLabel()
            lastZoom = math.floor(FOV_MAX / fov * 10 + 0.5) / 10
            interface.send({
                action = 'openPdCameraHUD',
                data = { zoom = lastZoom, mode = 'Tripod', effect = 'Default', street = lastStreet }
            })
        else
            interface.send({ action = 'openCameraHUD' })
        end

        infoUI.show({
            id = infoId,
            title = 'Information',
            icon = 'fas fa-camera',
            description = instrucional
        })

        while (camera or onTakePhoto) and not IsEntityDead(cache.ped) do
            DisablePlayerFiring(cache.ped, true)

            DisableControlAction(0, 177, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 113, true)
            DisableControlAction(0, 38, true)

            DisableControlAction(0, 241, true)
            DisableControlAction(0, 242, true)
            DisableControlAction(0, 17, true)
            DisableControlAction(0, 16, true)

            if not onTakePhoto then
                if not effectMenuOpen and IsDisabledControlJustPressed(0, 38) then
                    effectMenuOpen = true
                    interface.focus(true, true)
                    interface.send({ action = 'openEffectMenu' })
                end

                if IsDisabledControlJustPressed(0, 177) then
                    camera = false
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                elseif pdMode and IsDisabledControlJustPressed(1, 176) then
                    onTakePhoto = true
                    PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", false)
                    CreateThread(function()
                        local sent = uploadPdPhoto()
                        lib.notify({
                            description = sent and 'Foto terkirim ke arsip kepolisian' or 'Gagal mengambil foto, coba lagi!',
                            type = sent and 'success' or 'error'
                        })
                        onTakePhoto = false
                    end)
                elseif IsDisabledControlJustPressed(1, 176) then
                    onTakePhoto = true
                    interface.send({ action = 'closeCameraHUD' })
                    Wait(150)
                    PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", false)
                    CreateThread(function()
                        local photo = uploadPhoto()
                        if photo then
                            camera = false
                            result = photo
                        else
                            interface.send({ action = 'openCameraHUD' })
                        end
                        onTakePhoto = false
                    end)
                elseif IsDisabledControlJustPressed(0, 113) then
                    if walkMode then
                        walkMode = false
                        if not cam then
                            cam = createCam()
                        end
                    else
                        walkMode = true
                        cameraRoll = 0.0
                        if cam then
                            destroyCam(cam)
                            ---@diagnostic disable-next-line: cast-local-type
                            cam = nil
                        end
                    end

                    if pdMode then
                        interface.send({ action = 'updatePdCameraHUD', data = { mode = walkMode and 'Walk' or 'Tripod' } })
                    end
                end
            end

            if not IsEntityPlayingAnim(cache.ped, "amb@world_human_paparazzi@male@base", 'base', 3) then
                lib.playAnim(cache.ped, "amb@world_human_paparazzi@male@base", 'base', 6.0, 3.0, -1, 49, 1.0, false,
                    false, false)
            end

            if cam then
                local zoomvalue = (1.0 / (FOV_MAX - FOV_MIN)) * (fov - FOV_MIN)
                checkInputRotation(cam, zoomvalue)
                handleZoom(cam)
            end

            hideHUDThisFrame()
            if pdMode then
                drawCinematic()

                local zoom = math.floor(FOV_MAX / fov * 10 + 0.5) / 10
                if zoom ~= lastZoom then
                    lastZoom = zoom
                    interface.send({ action = 'updatePdCameraHUD', data = { zoom = zoom } })
                end

                local now = GetGameTimer()
                if now > nextStreetCheck then
                    nextStreetCheck = now + 1000
                    local street = getStreetLabel()
                    if street ~= lastStreet then
                        lastStreet = street
                        interface.send({ action = 'updatePdCameraHUD', data = { street = street } })
                    end
                end
            end
            Wait(0)
        end

        camera = false
        interface.send({ action = 'closeCameraHUD' })
        infoUI.remove(infoId)

        effectMenuOpen = false
        interface.focus(false, false)

        ClearPedTasks(cache.ped)
        DisablePlayerFiring(cache.ped, false)
        destroyCam(cam)

        if cameraprop then
            DeleteEntity(cameraprop)
        end

        if pdMode then
            pdHudOpen = false
            playerState:set('pdCameraOpen', false, false)
            interface.send({ action = 'closePdCameraHUD' })
            captureStamp = nil
            captureStreet = nil
            lib.callback.await('rhd_photo_system:pdCloseCamera', false)
        elseif not result then
            lib.callback.await('rhd_photo_system:closeCamera', false)
        end

        p:resolve(result)
    end)

    return Citizen.Await(p)
end
