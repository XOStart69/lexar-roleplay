RegisterNetEvent('Housing:server:RegisterGarage', function(homeId, garage)
    local home = Housing:GetHome(homeId)
    if not home or type(garage) ~= 'table' then return end

    local label = ('%s - %s'):format(home.name, garage.name or 'Garasi')
    local coords = garage.coords

    if IsDuplicityVersion and GetResourceState('qb-garages') == 'started' then
        TriggerEvent('qb-garages:server:addHouseGarage', homeId, {
            label = label,
            type = 'house',
            takeVehicle = coords,
        })
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= 'qb-garages' then return end

    CreateThread(function()
        Wait(2000)
        for homeId, home in pairs(Housing.homes) do
            for _, garage in ipairs(home.garages) do
                TriggerEvent('qb-garages:server:addHouseGarage', homeId, {
                    label = ('%s - %s'):format(home.name, garage.name or 'Garasi'),
                    type = 'house',
                    takeVehicle = garage.coords,
                })
            end
        end
    end)
end)