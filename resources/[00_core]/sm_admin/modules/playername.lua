local utils = require 'modules.lib.utils'

local showNames = false

local function updatePlayerTags(nearbyPlayers)
    for i=1, #nearbyPlayers do
        local player = nearbyPlayers[i]
        local serverId = GetPlayerServerId(player.id)
        local playerId = GetPlayerFromServerId(serverId)
        local ped = GetPlayerPed(playerId)
        
        local state = Player(serverId).state
        local name = 'ID: ' .. serverId .. ' | ' .. ('%s (%s)'):format(state.myname, state.steamname)

        local tag = CreateFakeMpGamerTag(ped, name, false, false, "", 0)
        SetMpGamerTagAlpha(tag, 0, 255)
        SetMpGamerTagAlpha(tag, 2, 255)
        SetMpGamerTagAlpha(tag, 4, 255)
        SetMpGamerTagAlpha(tag, 6, 255)
        SetMpGamerTagHealthBarColour(tag, 25)

        local isPlayerTalking = NetworkIsPlayerTalking(playerId)
        local isPlayerInvincible = GetPlayerInvincible(playerId)

        if showNames then
            SetMpGamerTagVisibility(tag, 0, true)
            SetMpGamerTagVisibility(tag, 2, true)
            SetMpGamerTagVisibility(tag, 4, isPlayerTalking)
            SetMpGamerTagVisibility(tag, 6, isPlayerInvincible)
        else
            SetMpGamerTagVisibility(tag, 0, false)
            SetMpGamerTagVisibility(tag, 2, false)
            SetMpGamerTagVisibility(tag, 4, false)
            SetMpGamerTagVisibility(tag, 6, false)
            RemoveMpGamerTag(tag)
        end
    end
end

return {
    toggle = function (actionData)
        if not utils.validate(actionData) then
            return
        end

        showNames = not showNames

        local msg = showNames and 'active' or 'non active'
        lib.notify({ description = 'Player name ' .. msg })

        if showNames then

            while showNames do
                Wait(1000)
                local coords = GetEntityCoords(cache.ped)
                local nearbyPlayers = lib.getNearbyPlayers(coords, 15, true)
                updatePlayerTags(nearbyPlayers)
            end
        end
    end
}