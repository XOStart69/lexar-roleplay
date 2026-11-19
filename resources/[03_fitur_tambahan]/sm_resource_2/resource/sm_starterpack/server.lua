--[[ sm_starterpack / server.lua ]]

local TABLE = 'sm_starterpack_claims'

local DEFAULTS = {
    cooldown = 5,
    money    = 500,
    items    = {
        { item = 'water',    count = 3 },
        { item = 'sandwich', count = 3 },
        { item = 'phone',    count = 1 },
    },
}

local lastUse  = {}
local claiming = {}

local function cfg()
    local c = (Config and (Config.StarterPack or Config.starterpack)) or {}
    return {
        cooldown = tonumber(c.cooldown) or DEFAULTS.cooldown,
        money    = tonumber(c.money) or DEFAULTS.money,
        items    = c.items or DEFAULTS.items,
    }
end

local function framework()
    for _, name in ipairs({ 'sm_core', 'qb-core', 'qbx_core' }) do
        if GetResourceState(name) == 'started' then return name end
    end
end

local function getPlayer(src)
    local fw = framework()
    if not fw then return nil end
    local ok, player = pcall(function() return exports[fw]:GetPlayer(src) end)
    if ok and player then return player end
end

local function notify(src, msg, kind)
    pcall(function() lib.notify(src, { title = 'Starter Pack', description = msg, type = kind or 'inform' }) end)
end

local function ownsPack(citizenid)
    local row = MySQL.single.await(('SELECT claimed_at FROM %s WHERE citizenid = ?'):format(TABLE), { citizenid })
    return row ~= nil, row and row.claimed_at or nil
end

RegisterNetEvent('sm_starterpack:server:start', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end

    local now = os.time()
    if lastUse[src] and (now - lastUse[src]) < cfg().cooldown then return end
    lastUse[src] = now

    local owned, claimedAt = ownsPack(player.PlayerData.citizenid)
    TriggerClientEvent('sm_starterpack:client:open', src, {
        eligible  = not owned,
        claimedAt = claimedAt,
        items     = cfg().items,
        money     = cfg().money,
    })
end)

RegisterNetEvent('sm_starterpack:server:claim', function()
    local src = source
    if claiming[src] then return end

    local player = getPlayer(src)
    if not player then return end

    claiming[src] = true

    local citizenid = player.PlayerData.citizenid
    local affected = MySQL.update.await(
        ('INSERT IGNORE INTO %s (citizenid, license, claimed_at) VALUES (?, ?, ?)'):format(TABLE),
        { citizenid, player.PlayerData.license, os.time() }
    )

    if affected == 0 then
        claiming[src] = false
        notify(src, 'Kamu sudah pernah klaim starter pack.', 'error')
        TriggerClientEvent('sm_starterpack:client:state', src, { eligible = false })
        return
    end

    local given = {}
    for _, entry in ipairs(cfg().items) do
        local ok = pcall(function()
            return exports.ox_inventory:AddItem(src, entry.item, entry.count)
        end)

        if ok then
            given[#given + 1] = entry
        else
            for _, back in ipairs(given) do
                pcall(function() exports.ox_inventory:RemoveItem(src, back.item, back.count) end)
            end
            MySQL.update.await(('DELETE FROM %s WHERE citizenid = ?'):format(TABLE), { citizenid })
            claiming[src] = false
            notify(src, 'Inventory penuh, klaim dibatalkan.', 'error')
            return
        end
    end

    local money = cfg().money
    if money > 0 then
        player.Functions.AddMoney('cash', money, 'starterpack')
    end

    claiming[src] = false
    notify(src, ('Starter pack diterima: %d item + $%d.'):format(#given, money), 'success')
    TriggerClientEvent('sm_starterpack:client:state', src, { eligible = false })
end)

RegisterCommand('starterpack', function(src)
    if src == 0 then return end
    local player = getPlayer(src)
    if not player then return end
    local owned, claimedAt = ownsPack(player.PlayerData.citizenid)
    TriggerClientEvent('sm_starterpack:client:open', src, {
        eligible  = not owned,
        claimedAt = claimedAt,
        items     = cfg().items,
        money     = cfg().money,
    })
end, false)

RegisterCommand('starterpack_reset', function(src, args)
    local cid = args[1]
    if not cid then
        notify(src, 'Pemakaian: /starterpack_reset <citizenid>', 'error')
        return
    end
    MySQL.update.await(('DELETE FROM %s WHERE citizenid = ?'):format(TABLE), { cid })
    notify(src, ('Klaim %s direset.'):format(cid), 'success')
end, true)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `sm_starterpack_claims` (
        `citizenid` VARCHAR(50) NOT NULL,
        `license`   VARCHAR(100) DEFAULT NULL,
        `claimed_at` INT UNSIGNED NOT NULL,
        PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]])
end)