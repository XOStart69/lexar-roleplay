local UNREAD_KEY = 'smMediaUnread'

local latestUnreadId = 0

local function clearUnread()
    TriggerServerEvent('sm_media_notify:markRead', latestUnreadId)
    latestUnreadId = 0

    LocalPlayer.state:set(UNREAD_KEY, 0, false)
end

RegisterNetEvent('sm_media_notify:show', function(payload)
    if type(payload) ~= 'table' then return end

    TriggerEvent('sm_hud:client:mediaBroadcast', payload)
end)

RegisterNetEvent('sm_media_notify:unread', function(payload)
    if type(payload) ~= 'table' then return end

    latestUnreadId = tonumber(payload.latestId) or 0

    LocalPlayer.state:set(UNREAD_KEY, tonumber(payload.total) or 0, false)
end)

AddEventHandler('sm_media_notify:opened', clearUnread)
