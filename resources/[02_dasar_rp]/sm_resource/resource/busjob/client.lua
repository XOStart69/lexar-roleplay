
local bus = localmodule 'modules.bus'
local shared_config = localmodule 'config.shared'
local blipModule = require 'modules.blipHandle.client'

local currentWork

CreateThread(function ()
    shared_config.office_target.options = {
        {
            label = 'Kerja bus',
            icon = 'fa-solid fa-bus',
            distance = 1.5,
            onSelect = function ()
                if cache.vehicle then
                    return
                end

                TriggerTokenEvent('sm_busjob:requestWork')
            end,
        },
        {
            label = 'Berhenti Kerja',
            icon = 'fa-solid fa-stop',
            distance = 1.5,
            onSelect = function ()
                if cache.vehicle then
                    return
                end

                TriggerTokenEvent('sm_busjob:endJob')
            end,
        }
    }
    ox_target:addBoxZone(shared_config.office_target)

    blipModule:new({
        coords = shared_config.office_target.coords,
        sprite = 67,
        color = 3,
        scale = 0.8,
        label = 'Kantor Bus',
    })
end)

RegisterNetEvent('sm_busjob:startWork', function (netId, routeIndex)
    if source == '' then return end

    if currentWork then
        currentWork:reset()
    end

    local busEntity = NetworkGetEntityFromNetworkId(netId)

    pcall(function ()
        sm_fuel.set(busEntity, 100)
    end)

    currentWork = bus:new(busEntity, routeIndex)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', GetVehicleNumberPlateText(busEntity))
end)

RegisterNetEvent('sm_busjob:resetWork', function ()
    if source == '' then return end
    if not currentWork then return end

    currentWork:reset()
    currentWork = nil
end)