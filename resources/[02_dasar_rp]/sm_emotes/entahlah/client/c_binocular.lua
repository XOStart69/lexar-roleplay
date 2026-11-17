local fov = 40.0
local index = 0
local cam
local prop_binoc
local instructions = true
local scaleform_bin
local scaleform_instructions

local function CleanupBinoculars()
    ClearPedTasks(PlayerPedId())
    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, true, false)
    SetScaleformMovieAsNoLongerNeeded(scaleform_bin)
    SetScaleformMovieAsNoLongerNeeded(scaleform_instructions)
    DestroyCam(cam, false)
    if prop_binoc then
        DeleteEntity(prop_binoc)
    end
    SetNightvision(false)
    SetSeethrough(false)
end
local function SetupButtons(button)
    local scaleform = RequestScaleformMovie("instructional_buttons")
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(10)
    end
    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    for i, btn in pairs(button) do
        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(i - 1)
        ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(0, btn.key, true))
        BeginTextCommandScaleformString("STRING")
        AddTextComponentScaleform(locale(btn.text))
        EndTextCommandScaleformString()
        PopScaleformMovieFunctionVoid()
    end

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    return scaleform
end

local function HideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(19) -- weapon wheel
    HideHudComponentThisFrame(1)  -- Wanted Stars
    HideHudComponentThisFrame(2)  -- Weapon icon
    HideHudComponentThisFrame(3)  -- Cash
    HideHudComponentThisFrame(4)  -- MP CASH
    HideHudComponentThisFrame(13) -- Cash Change
    HideHudComponentThisFrame(11) -- Floating Help Text
    HideHudComponentThisFrame(12) -- more floating help text
    HideHudComponentThisFrame(15) -- Subtitle Text
    HideHudComponentThisFrame(18) -- Game Stream
end

local function HandleZoomAndCheckRotation(cam, fov)
    local zoomspeed = 10.0 -- camera zoom speed
    local lPed = PlayerPedId()

    local fov_max = 70.0
    local fov_min = 10.0 -- max zoom level (smaller fov is more zoom)
    local speed_lr = 8.0 -- speed by which the camera pans left-right
    local speed_ud = 8.0 -- speed by which the camera pans up-down

    local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)

    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * (speed_ud) * (zoomvalue + 0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * (speed_lr) * (zoomvalue + 0.1)), -29.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
    end

    if not IsPedSittingInAnyVehicle(lPed) then
        if IsControlJustPressed(0, 241) then -- Scrollup
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0, 242) then
            fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov - current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
    else
        if IsControlJustPressed(0, 17) then -- Scrollup
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0, 16) then
            fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov - current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov) * 0.05) -- Smoothing of camera zoom
    end

    return fov
end

local function IsInActionWithErrorMessage(ignores)
    if ignores == nil then ignores = {} end

    if not ignores.isUsingBinoculars and PState.isUsingBinoculars then
        return true
    end
    if not ignores.isUsingNewscam and PState.isUsingNewscam then
        return true
    end
    if not ignores.isUsingNewsmic and PState.isUsingNewsmic then
        return true
    end
    if not ignores.isUsingNewsbmic and PState.isUsingNewsbmic then
        return true
    end

    return false
end

function UseBinocular()
    if IsPedSittingInAnyVehicle(PlayerPedId()) then
        return
    end
    if IsInActionWithErrorMessage({ isUsingBinoculars = true }) then
        return
    end

    local isUsing = PState.isUsingBinoculars or false
    PState:set('isUsingBinoculars', not isUsing, false)


    if not isUsing then
        if PState.isInAnimation then
            Emote.cancel()
            lib.print.info('Emote cancelled')
        end
        
        CreateThread(function()
    
            ClearPedTasks(PlayerPedId())
            RequestAnimDict("amb@world_human_binoculars@male@idle_a")
            while not HasAnimDictLoaded("amb@world_human_binoculars@male@idle_a") do
                Wait(5)
            end

            local boneIndex = GetPedBoneIndex(PlayerPedId(), 28422)
            local x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), true))

            lib.requestModel('prop_binoc_01', 1500)
            prop_binoc = CreateObject(`prop_binoc_01`, x, y, z + 0.2, true, true, true)
            AttachEntityToEntity(
                prop_binoc,
                PlayerPedId(),
                boneIndex,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                true, true, false, true, 1, true
            )

            TaskPlayAnim(PlayerPedId(), "amb@world_human_binoculars@male@idle_a", "idle_c", 5.0, 5.0, -1, 51, 0, false, false, false)
            PlayAmbientSpeech1(PlayerPedId(), "GENERIC_CURSE_MED", "SPEECH_PARAMS_FORCE")
            SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)

            RemoveAnimDict("amb@world_human_binoculars@male@idle_a")
            SetModelAsNoLongerNeeded("prop_binoc_01")
        end)

        Wait(200)

        SetTimecycleModifier("default")
        SetTimecycleModifierStrength(0.3)
        scaleform_bin = RequestScaleformMovie("BINOCULARS")
        while not HasScaleformMovieLoaded(scaleform_bin) do
            Wait(10)
        end

        cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)

        AttachCamToEntity(cam, PlayerPedId(), 0.0, 0.0, 1.2, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(PlayerPedId()))
        SetCamFov(cam, fov)
        RenderScriptCams(true, false, 0, true, false)
        PushScaleformMovieFunction(scaleform_bin, "SET_CAM_LOGO")
        PushScaleformMovieFunctionParameterInt(0) -- 0 for nothing, 1 for LSPD logo
        PopScaleformMovieFunctionVoid()

        -- local keyList = {
        --                 { key = 177, text = 'exit_binoculars' },
        --         { key = 19, text = 'toggle_binoculars_vision' },
        --         { key = 47, text = 'toggle_instructions' }
        --     }
        -- if Config.AllowVisionsToggling then
        --     keyList = {
                -- { key = 177, text = 'exit_binoculars' },
                -- { key = 19, text = 'toggle_binoculars_vision' },
                -- { key = 47, text = 'toggle_instructions' }
        --     }
        -- else
        --     keyList = {
        --         { key = 177, text = 'exit_binoculars' },
        --         { key = 47, text = 'toggle_instructions' }
        --     }
        -- end

        -- scaleform_instructions = SetupButtons(keyList)

        while PState.isUsingBinoculars and not IsEntityDead(PlayerPedId()) and not IsPedSittingInAnyVehicle(PlayerPedId()) do
            if IsControlJustPressed(0, 177) then
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                PState:set('isUsingBinoculars', false, false)
            end

            fov = HandleZoomAndCheckRotation(cam, fov)

            HideHUDThisFrame()
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 37, true) -- Select weapon
            DisableControlAction(0, 24, true) -- Attack
            DisablePlayerFiring(PlayerPedId(), true)

            -- if IsControlJustPressed(0, 19)  then
            --     if index == 0 then
            --         SetNightvision(true)
            --         PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            --         index = index + 1
            --     elseif index == 1 then
            --         SetSeethrough(true)
            --         SetNightvision(false)
            --         PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            --         index = index + 1
            --     elseif index == 2 then
            --         SetNightvision(false)
            --         SetSeethrough(false)
            --         PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            --         index = 0
            --     end
            -- end

            -- if IsControlJustPressed(0, 47) then
            --     instructions = not instructions
            --     PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            -- end

            DrawScaleformMovieFullscreen(scaleform_bin, 255, 255, 255, 255)
            if instructions then
                DrawScaleformMovieFullscreen(scaleform_instructions, 255, 255, 255, 255)
            end
            Wait(1)
        end
    end

    PState:set('isUsingBinoculars', false, false)
    index = 0
    CleanupBinoculars()
end

RegisterNetEvent("binoculars:client:use", function()
    UseBinocular()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupBinoculars()
    end
end)

exportWrapper('toggleBinoculars', function()
    UseBinocular()
end)
