local vehUtils = {}
local serverSide = lib.context == 'server'

local utils = require 'modules.utils'

---@class GiveKeyData
---@field source? number
---@field plate string

---@class VehicleSpawnResult
---@field netId number
---@field entity number
---@field plate string

---@class CreateVehicleData
---@field model string|number
---@field coords vector4
---@field platePrefix? string

---@type fun(entity: number)?
local releasePlate

---@param netId number
---@return boolean
function vehUtils.remove(netId)
    if not netId then return false end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) then return false end
    if not serverSide then
        SetEntityAsMissionEntity(entity, true, true)
    elseif releasePlate then
        releasePlate(entity)
    end
    DeleteEntity(entity)
    return true
end

function vehUtils.getVehPlate(vehicle)
    assert(vehicle and DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2, 'Invalid vehicle entity')
    return utils.stringTrim(GetVehicleNumberPlateText(vehicle))
end

if serverSide then
    local PLATE_LENGTH = 8

    ---@type table<string, number>
    local activePlates = {}

    releasePlate = function(entity)
        for plate, holder in pairs(activePlates) do
            if holder == entity then
                activePlates[plate] = nil
                return
            end
        end
    end

    ---@param plate string
    ---@return boolean
    local function plateTaken(plate)
        local holder = activePlates[plate]

        if holder then
            if DoesEntityExist(holder) then return true end
            activePlates[plate] = nil
        end

        return false
    end

    ---@param prefix string
    ---@return string?
    local function generatePlate(prefix)
        prefix = utils.stringTrim(prefix):upper():sub(1, PLATE_LENGTH - 1)
        local randomLength = PLATE_LENGTH - #prefix

        for _ = 1, 30 do
            local plate = prefix .. lib.string.random(('.'):rep(randomLength))

            if not plateTaken(plate) then
                return plate
            end
        end

        lib.print.warn(('Gagal membuat plat unik untuk prefix "%s"'):format(prefix))
    end

    ---@param data CreateVehicleData
    ---@return VehicleSpawnResult?
    function vehUtils.create(data)
        if not data or not data.model or not data.coords then return end

        local x, y, z, w = table.unpack(data.coords)
        local vehmodel = type(data.model) == 'string' and joaat(data.model) or data.model

        local vehicle = CreateVehicle(vehmodel, x, y, z, w or 0.0, true, false)

        lib.waitFor(function ()
            if DoesEntityExist(vehicle) then
                return true
            end
        end, 'Failed to spawn vehicle: ' .. tostring(data.model), 50000)

        SetVehicleDirtLevel(vehicle, 0.0)
        SetEntityOrphanMode(vehicle, 2)

        if data.platePrefix then
            local plate = generatePlate(data.platePrefix)

            if plate then
                SetVehicleNumberPlateText(vehicle, plate)
                activePlates[plate] = vehicle

                local applied = pcall(lib.waitFor, function()
                    if utils.stringTrim(GetVehicleNumberPlateText(vehicle)) == plate then
                        return true
                    end
                end, 'Plate did not apply', 5000)

                if not applied then
                    activePlates[plate] = nil
                    lib.print.warn(('Plat "%s" gagal terpasang, memakai plat bawaan'):format(plate))
                end
            end
        end

        local netId = NetworkGetNetworkIdFromEntity(vehicle)

        return { entity = vehicle, netId = netId, plate = utils.stringTrim(GetVehicleNumberPlateText(vehicle)) }
    end

    ---@param data GiveKeyData
    function vehUtils.giveKey(data)
        exports['sm_vehiclekeys']:GiveKeys(data.source, utils.stringTrim(data.plate))
    end

    ---@param data GiveKeyData
    function vehUtils.removeKey(data)
        exports['sm_vehiclekeys']:RemoveKeys(data.source, utils.stringTrim(data.plate))
    end
end

return vehUtils