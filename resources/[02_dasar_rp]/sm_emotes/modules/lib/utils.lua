local utils = {}
local busyState = {}

local ped_types = lib.load('data.ped_types')
local scenario_models = lib.load('data.scenario_models')
local emotes = require 'data.emotes'.shared

---@param name string
---@return CacheEmote?
function utils.getEmote(name)
    return emotes[name]
end

if lib.context == 'client' then
    function utils.isAiming()
        return cache.weapon and (
            IsPlayerFreeAiming(cache.ped) or IsAimCamActive() or IsAimCamThirdPersonActive()
        )
    end

    function utils.isInActionWithErrorMessage(ignores)
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
        if not ignores.isProne and PState.isProne then
            return true
        end

        return false
    end

    function utils.setupButtons(button)
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

    function utils.hideHUDThisFrame()
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

    function utils.handleZoomAndCheckRotation(cam, fov)
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

    function utils.cancelScenario()
        local emote = PState.currentEmote
        if not emote then return end

        local emote_data = emotes[emote]
        if not emote_data then return end

        local category in emote_data

        ---@cast category cache_category
        if category == 'scenario' then
            ClearPedTasksImmediately(cache.ped)
        end
    end

    function utils.isValidAnimals(emote)
        if emote:match('bdog') then
            return lib.array.find(ped_types.big_dogs, function (val)
                if IsPedModel(cache.ped, val) then
                    return true
                end
            end)
        elseif emote:match('sdog') then
            return lib.array.find(ped_types.small_dogs, function (val)
                if IsPedModel(cache.ped, val) then
                    return true
                end
            end)
        end
        return false
    end

    function utils.isCuffed()
        local ok, cuffed = pcall(function() return exports.sm_policejob:IsHandcuffed() end)
        if ok and cuffed then
            lib.notify({ description = 'Tidak bisa melakukan emote saat sedang diborgol', type = 'error' })
            return true
        end
        return false
    end

    function utils.isInInvalidActionState()
        local ped = cache.ped

        if not DoesEntityExist(ped) then
            return true
        end

        if utils.isCuffed() then
            return true
        end

        if IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedGettingUp(ped) or IsPedInMeleeCombat(ped) then
            lib.notify({ description = 'Tidak bisa melakukan emote saat ini', type = 'error' })
            return true
        end

        if (IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped)) then
            lib.notify({ description = 'Tidak bisa melakukan emote ketika sedang berenang', type = 'error' })
            return true
        end

        return false
    end

    function utils.isMale()
        return GetEntityModel(cache.ped) == joaat("mp_m_freemode_01")
    end

    function utils.isDead()
        local playerData = QBPlayerData or QBX?.PlayerData
        
        if not playerData then
            pcall(function()
                local QBCore = exports['qb-core']:GetCoreObject()
                playerData = QBCore.Functions.GetPlayerData()
            end)
        end

        if playerData and (playerData.metadata?.isdead or playerData.metadata?.inlaststand) then
            lib.notify({ description = 'Tidak bisa melakukan emote saat ini', type = 'error'})
            return true
        end
        
        return false
    end

    function utils.clearScenarioObject()
        
        if busyState.clearScenObject then return end

        busyState.clearScenObject = true
        local coords = GetEntityCoords(cache.ped)
        local deletedCount = 0

        for i = 1, #scenario_models do
            local models = scenario_models[i]
            local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.0, models, false, true, true)

            if DoesEntityExist(object) then
                print('[CLEAR_SCENARIO_OBJ] Deleting object:', object, 'model:', models)
                SetEntityAsMissionEntity(object, false, false)
                DeleteObject(object)
                deletedCount = deletedCount + 1
            end
        end

        SetTimeout(1500, function ()
            busyState.clearScenObject = false
        end)
    end
end

_ENV.utils = utils