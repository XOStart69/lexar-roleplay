--[[
    sm_crutch :: server
    Satu alat aktif per warga. Waktu dihitung absolut, di-cap oleh maxAssignTime,
    dan dipulihkan saat relog lewat checkInjuryTime.
]]

local Config = localmodule 'config.shared'

local ITEMS = Config.items or {}
local MAX_TIME = Config.maxAssignTime or {}
local ON_DEATH = Config.disableOnDeath or {}
local JOB = Config.jobRequirement or {}
local ALLOW_SELF = Config.allowSelfUse == true

local TYPES = { 'crutch', 'chair', 'infus' }
local TABLE = 'sm_crutch_active'

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'inform' })
end

local function label(equipType)
    if equipType == 'chair' then return 'wheelchair' end
    return equipType
end

local function cap(equipType)
    return MAX_TIME[equipType] or MAX_TIME[label(equipType)] or 10
end

local function allowed(player)
    if not JOB.enabled then return true end
    if not player then return false end

    for i = 1, #(JOB.jobs or {}) do
        if JOB.jobs[i] == player.PlayerData.job.name then return true end
    end

    return false
end

local function itemName(equipType)
    local entry = ITEMS[label(equipType)]
    if not entry or not entry.enabled then return nil end
    return entry.name
end

local function rowOf(citizenid)
    return MySQL.single.await('SELECT * FROM ' .. TABLE .. ' WHERE citizenid = ?', { citizenid })
end

local function remaining(row)
    if not row then return 0 end
    return math.max(math.floor(row.expires_at - os.time()), 0)
end

lib.callback.register('sm_crutch:checkInjuryTime', function(src)
    local player = playerOf(src)
    if not player then return nil end

    local row = rowOf(player.PlayerData.citizenid)
    if not row then return nil end

    local left = remaining(row)
    if left <= 0 then
        MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE citizenid = ?', { player.PlayerData.citizenid })
        return nil
    end

    return { type = row.equip_type, remaining = left }
end)

lib.callback.register('sm_crutch:getPlayerData', function(src, list)
    if type(list) ~= 'table' then return {} end

    local ped = GetPlayerPed(src)
    if ped == 0 then return {} end

    local coords = GetEntityCoords(ped)
    local out = {}

    for i = 1, #list do
        local target = tonumber(type(list[i]) == 'table' and list[i].id or list[i])
        local player = target and playerOf(target)

        if player then
            local tped = GetPlayerPed(target)
            if tped ~= 0 and #(coords - GetEntityCoords(tped)) <= 12.0 then
                out[#out + 1] = {
                    id = target,
                    name = ('%s %s'):format(player.PlayerData.charinfo.firstname or '', player.PlayerData.charinfo.lastname or ''),
                }
            end
        end
    end

    return out
end)

RegisterNetEvent('sm_crutch:update', function(equipType, state, targetId)
    local src = source
    local target = tonumber(targetId) or src
    local player = playerOf(target)
    if not player or not ITEMS[equipType] then return end

    local row = rowOf(player.PlayerData.citizenid)

    if state == false or state == 0 then
        MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE citizenid = ?', { player.PlayerData.citizenid })
        TriggerClientEvent('sm_crutch:stop', target)
        return
    end

    local amount = tonumber(state) or 1
    if not row then return end

    local capSeconds = cap(equipType) * 60
    local nextExpiry = math.min(row.expires_at + (amount * 60), os.time() + capSeconds)

    MySQL.update('UPDATE ' .. TABLE .. ' SET expires_at = ? WHERE citizenid = ?', {
        nextExpiry, player.PlayerData.citizenid,
    })
end)

RegisterNetEvent('sm_crutch:assign', function(equipType, targetId, amount)
    local src = source
    local giver = playerOf(src)
    local target = tonumber(targetId) or src
    local patient = playerOf(target)

    if not giver or not patient then return end
    if not allowed(giver) then return notify(src, (Config.strings or {}).not_authorized) end

    if target == src and not ALLOW_SELF then
        return notify(src, (Config.strings or {}).not_authorized)
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return notify(src, (Config.strings or {}).invalid_entry) end

    local limit = cap(equipType)
    if amount > limit then
        return notify(src, ((Config.strings or {}).invalid_entry_max or '%s'):format(limit))
    end

    local expires = os.time() + (amount * 60)

    MySQL.insert(
        ('INSERT INTO %s (citizenid, equip_type, started_at, expires_at) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE equip_type = VALUES(equip_type), started_at = VALUES(started_at), expires_at = VALUES(expires_at)'):format(TABLE),
        { patient.PlayerData.citizenid, equipType, os.time(), expires }
    )

    TriggerClientEvent('sm_crutch:start', target, equipType, amount)
end)

RegisterNetEvent('sm_crutch:removeItem', function(item)
    local src = source
    item = tostring(item or '')
    if item == '' then return end

    if (ox_inventory:GetItemCount(src, item) or 0) < 1 then return end
    ox_inventory:RemoveItem(src, item, 1)
end)

RegisterNetEvent('sm_crutch:server:openMenu', function(equipType, isItem)
    local src = source
    local player = playerOf(src)
    if not player then return end
    if not allowed(player) then return notify(src, (Config.strings or {}).not_authorized) end

    TriggerClientEvent('sm_crutch:openMenu', src, equipType, isItem == true)
end)

RegisterNetEvent('sm_crutch:server:death', function()
    local src = source
    local player = playerOf(src)
    if not player then return end

    local row = rowOf(player.PlayerData.citizenid)
    if not row then return end

    local key = label(row.equip_type)
    if ON_DEATH[key] == false then return end

    MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE citizenid = ?', { player.PlayerData.citizenid })
    TriggerClientEvent('sm_crutch:stop', src)
end)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `citizenid` varchar(64) NOT NULL,
        `equip_type` varchar(16) NOT NULL,
        `started_at` int(11) NOT NULL,
        `expires_at` int(11) NOT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(TABLE))
end)

print('^2[sm_crutch] server siap^7')