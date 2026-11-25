--[[
    sm_taser :: server
    Cartridge (item) -> shots di server. Tembakan divalidasi (senjata, cooldown, sisa shot),
    probe disiarkan ke pemain terdekat, efek ke target lewat state bag `smTaser`
    (dibaca client effect.lua di pemilik entitas).
]]

local config = localmodule 'config'

local WEAPON = joaat(config.weapon or 'WEAPON_STUNGUN')
local ITEM = config.cartridge.item
local PER_CARTRIDGE = config.cartridge.shotsPerCartridge or 3
local COOLDOWN = config.fireCooldown or 3000
local RELOAD_MS = config.reloadTime or 1500
local RANGE = (config.range or 10.0) + 6.0
local PROBES = config.probesPerShot or 2
local TO_LOCK = config.probesToLock or 1
local SYNC = config.syncDistance or 60.0
local PROBE_TTL = 2000

local shots = {}      -- citizenid -> sisa shot
local lastFire = {}   -- src -> ms
local reloadAt = {}   -- src -> ms
local nextProbe = 0

local function cidOf(src)
    local player = qb_ecore:GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

local function push(src, value)
    TriggerClientEvent('sm_taser:client:shots', src, value)
end

lib.callback.register('sm_taser:getShots', function(src)
    local cid = cidOf(src)
    if not cid then return nil end

    return shots[cid] or 0
end)

lib.callback.register('sm_taser:reloadStart', function(src)
    local cid = cidOf(src)
    if not cid then return false end

    if GetSelectedPedWeapon(GetPlayerPed(src)) ~= WEAPON then return false end
    if (shots[cid] or 0) > 0 then return false, ('Cartridge masih punya %d shot.'):format(shots[cid]) end
    if (exports.ox_inventory:GetItemCount(src, ITEM) or 0) < 1 then return false, 'Tidak ada Taser Cartridge.' end

    reloadAt[src] = GetGameTimer()

    return true
end)

lib.callback.register('sm_taser:reloadFinish', function(src)
    local cid = cidOf(src)
    local started = reloadAt[src]
    reloadAt[src] = nil

    if not cid or not started then return false end
    if GetGameTimer() - started < RELOAD_MS * 0.7 then return false, 'Terlalu cepat.' end
    if GetSelectedPedWeapon(GetPlayerPed(src)) ~= WEAPON then return false end
    if (shots[cid] or 0) > 0 then return false end

    if not exports.ox_inventory:RemoveItem(src, ITEM, 1) then
        return false, 'Tidak ada Taser Cartridge.'
    end

    shots[cid] = PER_CARTRIDGE

    return true, PER_CARTRIDGE
end)

local function applyEffect(entity, shooter, lock)
    local cfg = (IsPedAPlayer(entity) and config.player) or config.npc
    local state = Entity(entity).state
    local value

    if lock then
        value = {
            mode = 'lock',
            shooter = shooter,
            shake = cfg.shakeTime,
            twitch = cfg.twitchTime,
            ground = cfg.groundTime,
            at = os.time(),
        }
    else
        value = { mode = 'flinch', shooter = shooter, flinch = config.flinchTime, at = os.time() }
    end

    state:set('smTaser', value, true)
end

RegisterTokenEvent('sm_taser:fire', function(hits)
    local src = source
    local cid = cidOf(src)
    if not cid or type(hits) ~= 'table' then return end

    local ped = GetPlayerPed(src)
    if ped == 0 or GetSelectedPedWeapon(ped) ~= WEAPON then return end

    local now = GetGameTimer()
    if lastFire[src] and now - lastFire[src] < COOLDOWN * 0.8 then return end
    if (shots[cid] or 0) < 1 then return end

    lastFire[src] = now
    shots[cid] = shots[cid] - 1
    push(src, shots[cid])

    local origin = GetEntityCoords(ped)
    local list = {}
    local perTarget = {}

    for i = 1, math.min(#hits, PROBES) do
        local hit = hits[i]
        local point = type(hit) == 'table' and hit.point

        if point and point.x and point.y and point.z then
            nextProbe = nextProbe + 1

            local probe = {
                id = nextProbe,
                point = vec3(point.x, point.y, point.z),
                ttl = PROBE_TTL,
            }

            local netId = tonumber(hit.target)
            local entity = netId and NetworkGetEntityFromNetworkId(netId) or 0

            if entity ~= 0 and DoesEntityExist(entity) and entity ~= ped
                and #(GetEntityCoords(entity) - origin) <= RANGE then
                probe.target = netId
                probe.bone = tonumber(hit.bone) or 0
                perTarget[entity] = (perTarget[entity] or 0) + 1
            end

            list[#list + 1] = probe
        end
    end

    if #list == 0 then return end

    for _, raw in ipairs(GetPlayers()) do
        local other = tonumber(raw)
        local otherPed = GetPlayerPed(other)

        if other == src or (otherPed ~= 0 and #(GetEntityCoords(otherPed) - origin) <= SYNC) then
            TriggerClientEvent('sm_taser:client:shot', other, src, list)
        end
    end

    for entity, struck in pairs(perTarget) do
        if IsPedAPlayer(entity) or config.npc.enabled then
            applyEffect(entity, src, struck >= TO_LOCK)
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    lastFire[src] = nil
    reloadAt[src] = nil
end)
