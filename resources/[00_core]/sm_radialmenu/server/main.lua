local trunkBusy = {}

local function trimPlate(plate)
    return (plate:gsub('%s+$', ''))
end

local function vehicleByPlate(plate)
    plate = trimPlate(plate)

    for _, veh in ipairs(GetAllVehicles()) do
        if DoesEntityExist(veh) and trimPlate(GetVehicleNumberPlateText(veh)) == plate then
            return veh
        end
    end
end

local function nearVehicle(source, veh, range)
    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return false end

    return #(GetEntityCoords(ped) - GetEntityCoords(veh)) <= range
end

lib.callback.register('qb-trunk:server:getTrunkBusy', function(source, plate)
    if type(plate) ~= 'string' then return false end

    local holder = trunkBusy[trimPlate(plate)]

    return holder ~= nil and holder ~= source
end)

RegisterNetEvent('qb-trunk:server:setTrunkBusy', function(plate, busy)
    local source = source

    if type(plate) ~= 'string' then return end

    plate = trimPlate(plate)

    if busy then
        trunkBusy[plate] = source
    elseif trunkBusy[plate] == source then
        trunkBusy[plate] = nil
    end
end)

RegisterNetEvent('qb-radialmenu:trunk:server:Door', function(open, plate, door)
    local source = source

    if type(plate) ~= 'string' or type(door) ~= 'number' then return end
    if door < 0 or door > 5 then return end

    local veh = vehicleByPlate(plate)

    if not veh or not nearVehicle(source, veh, 12.0) then return end

    TriggerClientEvent('qb-radialmenu:trunk:client:Door', -1, trimPlate(plate), door, open and true or false)
end)

RegisterNetEvent('qb-radialmenu:server:RemoveStretcher', function(coords, obj)
    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then return end

    TriggerClientEvent('qb-radialmenu:client:RemoveStretcherFromArea', -1, coords, obj)
end)

RegisterNetEvent('qb-radialmenu:server:LayOnStretcher', function(target, kind)
    local source = source

    target = tonumber(target)

    if not target or not GetPlayerName(target) then return end
    if kind ~= 'lay' and kind ~= 'carry' then return end

    TriggerClientEvent('qb-radialmenu:Stretcher:client:BusyCheck', target, source, kind)
end)

RegisterNetEvent('qb-radialmenu:server:BusyResult', function(busy, otherId, kind)
    otherId = tonumber(otherId)

    if not otherId then return end

    TriggerClientEvent('qb-radialmenu:client:Result', otherId, busy and true or false, kind)
end)

AddEventHandler('playerDropped', function()
    local source = source

    for plate, holder in pairs(trunkBusy) do
        if holder == source then
            trunkBusy[plate] = nil
        end
    end
end)

lib.print.info('sm_radialmenu server siap')
