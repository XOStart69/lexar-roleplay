--[[
    sm_givecash :: server
    Kirim uang tunai antar pemain. Jarak, jumlah, dan cooldown divalidasi di server.
]]

local config = localmodule 'config'

local MAX_GIVE = config.maxGive or 1000000
local DISTANCE = config.distance or 3.0
local COOLDOWN = config.cooldown or 2000

local last = {}

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

lib.callback.register('sm_givecash:server:cash', function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return 0 end

    return player.PlayerData.money and player.PlayerData.money.cash or 0
end)

RegisterTokenEvent('sm_givecash:server:give', function(targetId, amount)
    local src = source
    targetId = tonumber(targetId)
    amount = math.floor(tonumber(amount) or 0)

    if not targetId or targetId == src then return end
    if amount < 1 or amount > MAX_GIVE then return end

    local now = GetGameTimer()
    if last[src] and now - last[src] < COOLDOWN then return notify(src, 'Tunggu sebentar.') end
    last[src] = now

    local player = qb_ecore:GetPlayer(src)
    local target = qb_ecore:GetPlayer(targetId)
    if not player or not target then return notify(src, 'Orang tidak ditemukan.') end

    local a, b = GetPlayerPed(src), GetPlayerPed(targetId)
    if a == 0 or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > DISTANCE + 2.0 then
        return notify(src, 'Orangnya terlalu jauh.')
    end

    if (player.PlayerData.money.cash or 0) < amount then
        return notify(src, 'Uang tunai tidak cukup.')
    end

    if not player.Functions.RemoveMoney('cash', amount, 'givecash') then
        return notify(src, 'Gagal mengirim uang.')
    end

    target.Functions.AddMoney('cash', amount, 'givecash')

    TriggerClientEvent('sm_givecash:client:given', src)
    notify(src, ('Kamu memberi $%s.'):format(amount), 'success')
    notify(targetId, ('Kamu menerima $%s.'):format(amount), 'success')

    print(('[sm_givecash] %s (%s) -> %s (%s): $%d'):format(
        GetPlayerName(src), player.PlayerData.citizenid, GetPlayerName(targetId), target.PlayerData.citizenid, amount))
end)

AddEventHandler('playerDropped', function()
    last[source] = nil
end)
