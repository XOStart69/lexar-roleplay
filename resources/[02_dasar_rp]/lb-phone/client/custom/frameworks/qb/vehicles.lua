if Config.Framework ~= "qb" then
    return
end

while not QB do
    Wait(500)
    debugprint("Vehicles: Waiting for QB to load")
end

---Apply vehicle mods
---@param vehicle number
---@param vehicleData table
function ApplyVehicleMods(vehicle, vehicleData)
    if type(vehicleData.mods) == "string" then
        vehicleData.mods = json.decode(vehicleData.mods)
    end

    SetVehicleNumberPlateText(vehicle, vehicleData.plate)

    if GetResourceState("ox_lib") == "started" then
        exports.ox_lib:setVehicleProperties(vehicle, vehicleData.mods)
    else
        QB.Functions.SetVehicleProperties(vehicle, vehicleData.mods)
    end
    TriggerEvent("sm_vehiclekeys:client:setVehicleOwner", QB.Functions.GetPlate(vehicle))

    if GetResourceState("LegacyFuel") == "started" and vehicleData.fuel then
        exports.LegacyFuel:SetFuel(vehicle, vehicleData.fuel)
    end

    if Config.Valet.FixTakeOut then
        SetVehicleFixed(vehicle)
    end
end

---Create a vehicle and apply vehicle mods
---@param vehicleData table
---@param coords vector3
---@return number? vehicle
function CreateFrameworkVehicle(vehicleData, coords, heading)
    local hash = tonumber(vehicleData.hash)

    if not hash then
        return
    end

    local combinedCoords = vec4(coords.x, coords.y, coords.z, heading or 0.0)
    local vehicle = exports.sm_core:SpawnVehicle(hash, nil, combinedCoords, true, false)

    if vehicle and DoesEntityExist(vehicle) then
        ApplyVehicleMods(vehicle, vehicleData)
    end

    return vehicle
end
