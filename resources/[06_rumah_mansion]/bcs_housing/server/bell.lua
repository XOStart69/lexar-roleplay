RegisterNetEvent('Housing:server:Bell', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local name = Housing:Name(src) or 'Seseorang'
    for _, target in ipairs(home:GetInside()) do
        Housing:Notify(target, ('%s membunyikan bel %s'):format(name, home.name), 'info')
        TriggerClientEvent('Housing:client:BellPlay', target, homeId)
    end

    TriggerClientEvent('Housing:client:BellPlay', src, homeId)
end)