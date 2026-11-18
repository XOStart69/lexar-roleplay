local resName = GetCurrentResourceName()

local function push(event, target)
    TriggerClientEvent(event, -1, target)
end

AddEventHandler('playerJoining', function()
    push('onPlayerJoining', source)
end)

AddEventHandler('playerDropped', function()
    push('onPlayerDropped', source)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= resName then return end
    for _, id in ipairs(GetPlayers()) do
        TriggerClientEvent('onPlayerJoining', -1, tonumber(id))
    end
end)
