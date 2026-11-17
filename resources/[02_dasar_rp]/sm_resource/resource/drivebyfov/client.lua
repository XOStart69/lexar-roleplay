local currentMode = 0

local function resetCam()
    if currentMode then
        local context = GetCamActiveViewModeContext()
        SetCamViewModeForContext(context, currentMode)
        ---@diagnostic disable-next-line: cast-local-type
        currentMode = nil
    end
end

local function forceFirstPerson()
    local mode = GetFollowVehicleCamViewMode()

    if mode ~= 4 then
        currentMode = mode
        local context = GetCamActiveViewModeContext()
        SetCamViewModeForContext(context, 4)
    end
end

local function vehicleIsHeli(vehicle)
    return GetVehicleClass(vehicle) == 15
end

local function driveByCamThread()
    CreateThread(function ()
        while cache.vehicle do
            if vehicleIsHeli(cache.vehicle) then
                resetCam()
                Wait(250)
                goto continue
            end

            if IsPlayerFreeAiming(cache.playerId) or IsPedDoingDriveby(cache.ped) then
                forceFirstPerson()

                if GetFollowVehicleCamViewMode() ~= 4 then
                    DisableControlAction(0, 25, true)  -- INPUT_AIM (RMB / L2)
                    DisableControlAction(0, 68, true)  -- INPUT_VEH_AIM
                end
            else
                resetCam()
            end
            Wait(0)
            ::continue::
        end

        resetCam()
    end)
end

lib.onCache('vehicle', function (vehicle)
    if not vehicle then return end

    Wait(100)
    driveByCamThread()
end)