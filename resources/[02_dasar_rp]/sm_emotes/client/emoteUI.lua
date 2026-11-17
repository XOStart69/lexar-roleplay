---@class UiState
local state = {
    isInUi = false
}

local emoteData = require 'data.emotes'.ui

local function setEmoteData()
    SendNUIMessage({
        action = 'setEmote',
        data = emoteData
    })
end

local function openEmoteMenu()
    if state.isInUi or PState.naikSapi then
        return
    end

    SendNUIMessage({
        action = 'setVisible',
        data = {
            visible = true
        }
    })

    state.isInUi = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    CreateThread(function()
        while state.isInUi do

            if PState.naikSapi then
                closeEmoteMenu()
                return
            end

            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 1, true)   -- Look LR
            DisableControlAction(0, 2, true)   -- Look UD
            DisableControlAction(0, 200, true) -- Pause menu
            Wait(1)
        end
    end)
end

local function closeEmoteMenu()
    state.isInUi = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

RegisterNUICallback('toggleKeepInput', function (data, cb)
    SetNuiFocusKeepInput(data.state)
    cb(true)
end)

RegisterNUICallback('init', function(_, cb)
    setEmoteData()
    cb('ok')
end)

RegisterNUICallback('exitMenu', function(_, cb)
    closeEmoteMenu()
    preview.finish()
    cb('ok')
end)

RegisterNUICallback('playEmote', function(data, cb)
    local category, command, texture in data

    if command == 'default' and category ~= nil then
        ---@cast category cache_category
        if category:lower() == 'walks' then
            walkstyle.set(command, true)
        elseif category:lower() == 'expressions' then
            expression.set(command, true)
        end
        goto continue
    end

    if command then
        Emote.playFromMenu(command, texture)
    end

    ::continue::

    cb(true)
end)

RegisterNUICallback('setPlacement', function (data, cb)
    local command in data
    placement.start(command)
    cb('ok')
end)

RegisterNUICallback('uiReady', function(_, cb)
    setEmoteData()
    cb('ok')
end)

RegisterNUICallback('getNearbyPlayers', function (data, cb)
     local players = {}

     local coords = GetEntityCoords(cache.ped)
     local nearby = lib.getNearbyPlayers(coords, 5)

    if nearby and #nearby > 0 then
        for i=1, #nearby do
            local player = nearby[i]
            local serverId = GetPlayerServerId(player.id)
            local name = ('Player (%s)'):format(serverId)

            players[#players+1] = { serverId = serverId, name = name }
        end
    end

    cb(players)
end)


RegisterNUICallback('getPlayerGroup', function(_, cb)
    local groupData = lib.callback.await('sm_emote:getPlayerGroup', false)
    cb(groupData)
end)

RegisterNUICallback('addPlayerToGroup', function (data, cb)
    local success = lib.callback.await('sm_emote:invitePlayer', false, data)
    cb(success)
end)

RegisterNUICallback('removePlayerFromGroup', function (data, cb)
    local success = lib.callback.await('sm_emote:removePlayer', false, data)
    cb(success)
end)

RegisterNUICallback('leaveGroup', function (_, cb)
    local success = lib.callback.await('sm_emote:leaveGroup', false)
    cb(success)
end)

RegisterNUICallback('playEmoteGroup', function (data, cb)
    local command = data.command
    local texture = data.texture

    if not command then
        return cb(false)
    end

    TriggerServerEvent('sm_emote:playGroupEmote', command, texture)

    cb(true)
end)

RegisterNUICallback('preview', function (data, cb)
    local command = data.command
    local texture = data.texture

    if not command then
        return cb(false)
    end

    preview.show(command, texture)
    cb(true)
end)

RegisterNUICallback('previewStop', function (_, cb)
    preview.finish()
    cb(true)
end)

exports('OpenEmoteMenu', openEmoteMenu)
exports('CloseEmoteMenu', closeEmoteMenu)