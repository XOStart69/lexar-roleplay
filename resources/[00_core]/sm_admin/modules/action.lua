local action = {}

local utils = require 'modules.lib.utils'

function action.maxmods(actionData, options, args)
    local act = utils.validate(actionData)

    if not act then
        return
    end

    if not cache.vehicle then
        return lib.notify({ description = 'Kamu harus berada didalam kendaraan!', type = 'error' })
    end

    local max
    local Mod = { 11, 12, 13, 15, 16 }

    if DoesEntityExist(cache.vehicle) and IsEntityAVehicle(cache.vehicle) then
        SetVehicleModKit(cache.vehicle, 0)

        for _, modType in ipairs(Mod) do
            max = GetNumVehicleMods(cache.vehicle, tonumber(modType) --[[@as number]]) - 1
            SetVehicleMod(cache.vehicle, modType, max, false)
        end

        ToggleVehicleMod(cache.vehicle, 18, true) -- Turbo
	    SetVehicleFixed(cache.vehicle)
        SetVehicleEngineOn(cache.vehicle, true, true, false)
        lib.notify({ description = 'Kendaraan telah di ratakanan.', type = 'success' })
    end
end

local performanceMods = {
    11, -- Engine
    12, -- Brakes
    13, -- Transmission
    15, -- Suspension
    16  -- Armor
}

---@param vehicle number
local function applyMaxPerformance(vehicle)
    SetVehicleModKit(vehicle, 0)

    for _, modType in ipairs(performanceMods) do
        local numMods = GetNumVehicleMods(vehicle, modType)

        if numMods > 0 then
            SetVehicleMod(vehicle, modType, numMods - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true) -- Turbo

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)
end

function action.maxperformance(actionData, options, args)
    local act = utils.validate(actionData)

    if not act then
        return
    end

    if not cache.vehicle then
        return lib.notify({ description = 'Kamu harus berada didalam kendaraan!', type = 'error' })
    end

    local vehicle = cache.vehicle

    if not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle) then
        return
    end

    applyMaxPerformance(vehicle)

    TriggerServerEvent('sm_admin:installHarness', Token(), actionData, {
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        plate = GetVehicleNumberPlateText(vehicle)
    })

    lib.notify({ description = 'Kendaraan telah di max performance + harness.', type = 'success' })
end

function action.setFuel(actionData, options, args)
    local act = utils.validate(actionData)

    if not act then
        return
    end

    if not cache.vehicle then
        return lib.notify({ description = 'Kamu harus berada didalam kendaraan!', type = 'error' })
    end

    exports.LegacyFuel:SetFuel(cache.vehicle, options.new_fuel)
end

function action.setAmmo(actionData, options, args)
    local act = utils.validate(actionData)

    if not act then
        return
    end

    if not cache.weapon then
        return lib.notify({ description = 'Kamu sedang tidak memegang senjata.', type = 'error' })
    end

    AddAmmoToPed(cache.ped, cache.weapon, options.ammo)
end

function action.playSound(actionData, options, args)
    local act = utils.validate(actionData)

    if not act then
        return
    end

    TriggerServerEvent("InteractSound_SV:PlayOnOne", options.playerid, options.sound, 0.30)
end

action.toggleNoclip = require 'modules.noclip'.toggle
action.toggleName = require 'modules.playername'.toggle
action.toggleBlips = require 'modules.playerBlip'.toggle
action.toggleLaser = require 'modules.laser'.toggle
action.toggleInvisible = require 'modules.invisible'.toggle

return action