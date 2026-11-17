CasinoPlayers = {}

---@param playerId number
---@param reason string
local function releasePlayer(playerId, reason)
    CasinoPlayers[playerId] = nil
    TriggerEvent('rhd_casino:releasePlayer', playerId, reason)
    TriggerEvent('rhd_casino:interiorChanged', playerId, false)
end

RegisterNetEvent('rhd_casino:interior', function (state)
    local source = source
    local playerPed = GetPlayerPed(source)
    if playerPed == 0 then return end

    local playerCoords = GetEntityCoords(playerPed)
    local isInsideCasino = shared.casinoBigZone:contains(playerCoords)
    local requestedState = state == true
    local finalState = requestedState and isInsideCasino

    if finalState then
        CasinoPlayers[source] = true
        TriggerEvent('rhd_casino:interiorChanged', source, true)
    else
        releasePlayer(source, 'left_interior')
    end
end)

RegisterNetEvent('rhd_casino:server:releasePlayer', function(reason)
    releasePlayer(source, type(reason) == 'string' and reason or 'client_cleanup')
end)

AddEventHandler('playerDropped', function()
    local source = source
    releasePlayer(source, 'disconnect')
end)

---Triggers a latent client event to a single player with dynamic bandwidth scaling.
---@param event string
---@param player number
---@param ... any
function TriggerCasinoEvent(event, player, ...)
    local payload = msgpack.pack_args(...)
    local payloadLen = #payload
    local bps = payloadLen + 1000
    TriggerLatentClientEventInternal(event, player --[[@as string]], payload, payloadLen, bps)
end

---Broadcasts a latent client event to all players currently inside the casino interior.
---@param event string
---@param ... any
function BroadcastCasinoPlayers(event, ...)
    if table.type(CasinoPlayers) == 'empty' then return end

    for src in pairs(CasinoPlayers) do
        TriggerCasinoEvent(event, src, ...)
    end
end
