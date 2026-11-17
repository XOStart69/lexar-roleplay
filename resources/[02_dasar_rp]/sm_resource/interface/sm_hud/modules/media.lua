local KEY = 'smMediaUnread'

---@param total any
local function sendUnread(total)
    interface.send({
        action = 'updateMediaUnread',
        data = { total = tonumber(total) or 0 },
    })
end

AddStateBagChangeHandler(KEY, ('player:%s'):format(cache.serverId), function(_, _, value)
    sendUnread(value)
end)

CreateThread(function()
    sendUnread(LocalPlayer.state[KEY])
end)

AddEventHandler('sm_hud:client:mediaBroadcast', function(payload)
    if type(payload) ~= 'table' then return end

    interface.send({ action = 'mediaBroadcast', data = payload })
end)
