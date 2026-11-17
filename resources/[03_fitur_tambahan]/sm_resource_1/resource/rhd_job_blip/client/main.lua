local renderer = localmodule 'modules.renderer'
local config = localmodule 'config.shared'

local event = localmodule 'enum.event'
local settings = config.Settings or {}

RegisterNetEvent(event.SYNC, function(payload)
    renderer:applyPayload(payload)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        renderer:clearAll()
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    renderer:clearAll()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    renderer:clearAll()
end)

CreateThread(function()
    while not QBPlayerData.job do
        Wait(500)
    end

    TriggerServerEvent(event.REQUEST_SYNC)
end)

CreateThread(function()
    local siren = settings.siren or {}
    if not siren.enabled then return end

    local lastState = false

    while true do
        local vehicle = cache.vehicle
        local state = vehicle and IsVehicleSirenOn(vehicle) == true or false

        if state ~= lastState then
            lastState = state
            TriggerServerEvent(event.SIREN, state)
        end

        Wait(siren.checkInterval or 500)
    end
end)
