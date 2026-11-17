local decorName = '_FUEL_LEVEL'

local fuelUsage = {
    [1.0] = 1.3,
	[0.9] = 1.1,
	[0.8] = 0.9,
	[0.7] = 0.8,
	[0.6] = 0.7,
	[0.5] = 0.5,
	[0.4] = 0.3,
	[0.3] = 0.2,
	[0.2] = 0.1,
	[0.1] = 0.1,
	[0.0] = 0.0,
}

local config = localmodule 'config.consum'
local electric_charging = localmodule 'config.station'.electric_charging

local fuelSynced = false

function sm_fuel.get(vehicle)
	return DecorGetFloat(vehicle, decorName)
end

function sm_fuel.set(vehicle, fuel)
	if type(fuel) == 'number' and fuel >= 0 and fuel <= 100 then
		SetVehicleFuelLevel(vehicle, fuel + 0.0)
		DecorSetFloat(vehicle, decorName, GetVehicleFuelLevel(vehicle))
	end
end

function sm_fuel.isBlacklist(vehicle)
    local nfu = config.noFuelUsage
    local elveh = config.electric_vehicle

    local vehmodel = GetEntityModel(vehicle)

    return not electric_charging and array.findIndex(elveh, function (model)
        return joaat(model) == vehmodel
    end) or array.findIndex(nfu, function (model)
        return joaat(model) == vehmodel
    end)
end

local function manageFuelUsage(vehicle)
	if not DecorExistOn(cache.vehicle, decorName) then
		sm_fuel.set(cache.vehicle, math.random(200, 800) / 10)
	elseif not fuelSynced then
        local vehFuel = sm_fuel.get(cache.vehicle)

        if vehFuel > 1.0 and not IsEntityDead(cache.vehicle) then
            SetVehicleUndriveable(cache.vehicle, false)
        end

		sm_fuel.set(cache.vehicle, vehFuel)
		fuelSynced = true
	end

	if IsVehicleEngineOn(cache.vehicle) then
        local currentFuel = GetVehicleFuelLevel(cache.vehicle)
        local vehicleRPM = math.round(GetVehicleCurrentRpm(cache.vehicle), 1)
        local newFuel = currentFuel - (fuelUsage[vehicleRPM] * 0.5) / 10

        if newFuel < 1 then
            if GetIsVehicleEngineRunning(cache.vehicle) then

                SetVehicleEngineOn(cache.vehicle, false, true, false)
                SetVehicleUndriveable(cache.vehicle, true)

                local soundId = GetSoundId()
                RequestAmbientAudioBank("DLC_PILOT_ENGINE_FAILURE_SOUNDS", 0)
                PlaySoundFromEntity(soundId, "Landing_Tone", cache.vehicle, "DLC_PILOT_ENGINE_FAILURE_SOUNDS", 0, 0)
                Wait(1500)
                StopSound(soundId)
            end
        else
            sm_fuel.set(cache.vehicle, newFuel)
        end
	end
end

local function fuelCheck()
    CreateThread(function ()
        while cache.vehicle do
            Wait(1000)
            if not sm_fuel.isBlacklist(cache.vehicle) and cache.seat == -1 then
                manageFuelUsage(cache.vehicle)
            end
        end
        fuelSynced = false
    end)
end

lib.onCache('vehicle', function (vehicle)
    if not vehicle then
        return
    end

    fuelCheck()
end)

local exportWrapper = require 'export_wrapper'
exportWrapper('LegacyFuel', 'SetFuel', sm_fuel.set)
exportWrapper('LegacyFuel', 'GetFuel', sm_fuel.get)

CreateThread(function ()
	DecorRegister(decorName, 1)
end)

-- RegisterCommand('setfuel', function (_, args)

--     if not cache.vehicle then return end
--     local level = tonumber(args[1] or 50)

--     sm_fuel.set(cache.vehicle, level)
-- end, false)