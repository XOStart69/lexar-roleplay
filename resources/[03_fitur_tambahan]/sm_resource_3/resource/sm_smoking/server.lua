--[[
    sm_smoking :: server
    Item rokok -> client menawarkan gaya merokok -> start (konsumsi 1 batang) -> stress turun berkala.
    Bungkus rokok dibuka jadi batang sesuai config.packs.
]]

local config = localmodule 'config'

local LIGHTER = config.lighter or 'lighter'
local STRESS_INTERVAL = config.stressInterval or 120000
local OFFER_TTL = 30000

local pending = {}  -- src -> { item, at }
local session = {}  -- src -> { item, stress, lastStress }

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function count(src, item)
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

for item, def in pairs(config.smokes or {}) do
    qb_ecore:CreateUseableItem(item, function(src)
        if session[src] then return notify(src, 'Anda sudah sedang merokok!') end
        if count(src, LIGHTER) < 1 then return notify(src, 'Butuh korek api.') end
        if count(src, item) < 1 then return end

        pending[src] = { item = item, at = GetGameTimer() }
        TriggerClientEvent('sm_smoking:client:offer', src, item, def.prop, def.type, def.stress)
    end)
end

for i = 1, #(config.packs or {}) do
    local pack = config.packs[i]

    qb_ecore:CreateUseableItem(pack.pack, function(src)
        if exports.ox_inventory:RemoveItem(src, pack.pack, 1) then
            TriggerClientEvent('sm_smoking:client:unpack', src)
            SetTimeout(config.unpackTime or 4000, function()
                if GetPlayerPing(src) > 0 then
                    exports.ox_inventory:AddItem(src, pack.cigarette, pack.amount or 12)
                end
            end)
        end
    end)
end

lib.callback.register('sm_smoking:server:start', function(src)
    local offer = pending[src]
    pending[src] = nil

    if not offer or GetGameTimer() - offer.at > OFFER_TTL then return false end
    if session[src] then return false end
    if count(src, LIGHTER) < 1 then return false end

    if not exports.ox_inventory:RemoveItem(src, offer.item, 1) then return false end

    local def = config.smokes[offer.item]
    session[src] = { item = offer.item, stress = def and def.stress or 1, lastStress = GetGameTimer() }

    return true
end)

RegisterTokenEvent('sm_smoking:server:stop', function()
    local src = source
    session[src] = nil
    pending[src] = nil
end)

RegisterTokenEvent('sm_smoking:server:stress', function()
    local src = source
    local current = session[src]
    if not current or not config.removeStress then return end

    local now = GetGameTimer()
    if now - current.lastStress < STRESS_INTERVAL * 0.8 then return end
    current.lastStress = now

    local player = qb_ecore:GetPlayer(src)
    if not player then return end

    local stress = tonumber(player.PlayerData.metadata.stress) or 0
    local nextValue = math.max(0, stress - current.stress)
    if nextValue ~= stress then
        player.Functions.SetMetaData('stress', nextValue)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    session[src] = nil
    pending[src] = nil
end)
