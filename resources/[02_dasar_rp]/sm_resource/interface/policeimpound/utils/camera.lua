local camera = false
local cameraprop = nil

local FOV_MAX = 80.0
local FOV_MIN = 5.0 -- max zoom level (smaller fov is more zoom)
local ZOOM_SPEED = 10.0 -- camera zoom speed
local SPEED_LEFT_RIGHT = 8.0 -- speed by which the camera pans left-right
local SPEED_UP_DOWN = 8.0 -- speed by which the camera pans up-down

local fov = (FOV_MAX+FOV_MIN) * 0.5
local onTakePhoto = false

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
    HideHudComponentThisFrame(11)
    HideHudComponentThisFrame(12)
    HideHudComponentThisFrame(15)
    HideHudComponentThisFrame(18)
    HideHudComponentThisFrame(19)
end

local function checkInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * (SPEED_UP_DOWN) * (zoomvalue + 0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * (SPEED_LEFT_RIGHT) * (zoomvalue + 0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
        -- Moves the entities body if they are not in a vehicle (else the whole vehicle will rotate as they look around)
        if not IsPedSittingInAnyVehicle(cache.ped) then
            SetEntityHeading(cache.ped, new_z)
        end
    end
end

local function handleZoom(cam)
    if not IsPedSittingInAnyVehicle(cache.ped) then
        if IsControlJustPressed(0,241) then
            fov = math.max(fov - ZOOM_SPEED, FOV_MIN)
        end
        if IsControlJustPressed(0,242) then
            fov = math.min(fov + ZOOM_SPEED, FOV_MAX)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    else
        if IsControlJustPressed(0,17) then
            fov = math.max(fov - ZOOM_SPEED, FOV_MIN)
        end
        if IsControlJustPressed(0,16) then
            fov = math.min(fov + ZOOM_SPEED, FOV_MAX)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov - current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
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
    fov = (FOV_MAX + FOV_MIN) * 0.5
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    SetNightvision(false)
    SetSeethrough(false)
end

local instrucional = [[
Ambil foto - Mouse [left]
Batalkan - Mouse [right]
Ganti mode - G
]]

---@return string?
local function uploadPhoto()
    local presigned = lib.callback.await('pimpound:requestUpload', false)
    if not presigned then return end

    local resp = interface.capture(presigned, { encoding = 'jpg', quality = 0.85 })
    local url = resp and type(resp.data) == 'table' and resp.data.url
    if not url then return end

    return lib.callback.await('pimpound:savePhoto', false, url)
end

return function ()
    if camera then return end

    camera = true
    lib.playAnim(cache.ped, "amb@world_human_paparazzi@male@base", 'base', 6.0, 3.0, -1, 49, 1.0, false, false, false)

    local cameraModel = safecall.fun(function ()
        return lib.requestModel(`prop_pap_camera_01`)
    end)

    if cameraModel then
        local coords = GetEntityCoords(cache.ped)
        cameraprop = CreateObject(cameraModel, coords.x, coords.y, coords.z + 0.2, true, true, true)
        AttachEntityToEntity(cameraprop, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    end

    local p = promise.new()
    CreateThread(function()
        Wait(500)

        SetTimecycleModifier("default")
        SetTimecycleModifierStrength(0.3)

        local url
        local cam = createCam()

        infoUI.show({
            id = 'pimpound:camera',
            title = 'Information',
            icon = 'fas fa-camera',
            description = instrucional
        })

        while camera and not IsEntityDead(cache.ped) do
            DisablePlayerFiring(cache.ped, true)

            DisableControlAction(0, 177, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 113, true)

            if IsDisabledControlJustPressed(0, 177) then
                camera = false
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                ClearPedTasks(cache.ped)
                DisablePlayerFiring(cache.ped, false)

                if cameraprop then
                    DeleteEntity(cameraprop)
                end
            elseif IsDisabledControlJustPressed(1, 176) then
                PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", false)
                if not onTakePhoto then
                    onTakePhoto = true
                    CreateThread(function()
                        local result = uploadPhoto()
                        if result then
                            camera = false

                            if cameraprop then
                                DeleteEntity(cameraprop)
                            end

                            url = result
                            ClearPedTasks(cache.ped)
                            DisablePlayerFiring(cache.ped, false)
                        end
                        onTakePhoto = false
                    end)
                end
            elseif IsDisabledControlJustPressed(0, 113) then
                if cam then
                    destroyCam(cam)
                    cam = nil
                else
                    cam = createCam()
                end
            end

            if not IsEntityPlayingAnim(cache.ped, "amb@world_human_paparazzi@male@base", 'base', 3) then
                lib.playAnim(cache.ped, "amb@world_human_paparazzi@male@base", 'base', 6.0, 3.0, -1, 49, 1.0, false, false, false)
            end

            if cam then
                local zoomvalue = (1.0 / (FOV_MAX - FOV_MIN)) * (fov - FOV_MIN)
                checkInputRotation(cam, zoomvalue)
                handleZoom(cam)
            end

            hideHUDThisFrame()
            Wait(0)
        end

        infoUI.remove('pimpound:camera')

        p:resolve(url)
        DisablePlayerFiring(cache.ped, false)
        camera = false
        destroyCam()
    end)

    return Citizen.Await(p)
end