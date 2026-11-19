--[[
    fleecarobbery :: server
    Tiga jenis bank dengan kunci terpisah. Config lokasi dipegang server dan disinkronkan.
]]

local shared = localmodule 'config.shared'
local srv = localmodule 'config.server'

local REQUIRED = srv.requiredJob or {}
local COOLDOWN = srv.cooldown or {}
local LIMIT = srv.robberyLimit or {}
local REWARDS = srv.rewards or {}
local MECHANIC = shared.itemMechanic or {}

local MAX_FAILS = MECHANIC.maxFails or 2

local KEYMAP = {
    hack_vault_door = 'door_hack',
    hack_bar_door = 'door_hack',
    hack_computer = 'computer',
    hack_door = 'doors',
    loot_trolley = 'trolley',
    drill_deposit_box = 'deposit_box',
    loot_center_table = 'center_table',
}

local busy = {}
local cooldownUntil = {}
local history = {}
local fails = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function countJob(jobName)
    local total = 0
    for _, raw in ipairs(GetPlayers()) do
        local player = playerOf(tonumber(raw))
        if player and player.PlayerData.job.name == jobName then total = total + 1 end
    end
    return total
end

local function near(src, coords, radius)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(coords.x, coords.y, coords.z)) <= radius
end

local function root(kind, bankId)
    if kind == 'basic' then return shared.basic[tonumber(bankId) or 0] end
    return shared[kind]
end

local function nodeAt(kind, bankId, stage, index)
    local tree = root(kind, bankId)
    if not tree then return nil end

    local bucket = tree[KEYMAP[stage] or stage]
    if not bucket then return nil end

    if stage == 'hack_vault_door' then return bucket[1] end
    if stage == 'hack_bar_door' then return bucket[2] end
    if index and bucket[tonumber(index)] then return bucket[tonumber(index)] end
    if bucket.coords or bucket.requiredItem then return bucket end

    return nil
end

local function busyKey(kind, bankId, stage, index)
    return ('%s:%s:%s:%s'):format(kind, tostring(bankId or '-'), stage, tostring(index or '-'))
end

local function isBusy(...)
    return busy[busyKey(...)] == true
end

local function setBusy(state, ...)
    local key = busyKey(...)
    if state then busy[key] = true else busy[key] = nil end
end

local function minutesOf(kind)
    local entry = COOLDOWN[kind]
    if not entry then return 0 end
    return (entry.time or 0) * 60
end

local function cooling(cid, kind)
    local entry = cooldownUntil[cid]
    if not entry then return false end
    return (entry[kind] or 0) > os.time()
end

local function limitReached(cid, kind)
    local rule = LIMIT[kind]
    if not rule then return false end

    history[cid] = history[cid] or {}
    local stamp = os.time()
    local window = (rule.time or 60) * 60
    local kept = {}

    for i = 1, #history[cid] do
        if stamp - history[cid][i] <= window then kept[#kept + 1] = history[cid][i] end
    end

    history[cid] = kept
    return #kept >= (rule.max or 2)
end

local function pushHistory(cid, kind)
    history[cid] = history[cid] or {}
    history[cid][#history[cid] + 1] = os.time()
    cooldownUntil[cid] = cooldownUntil[cid] or {}
    cooldownUntil[cid][kind] = os.time() + minutesOf(kind)
end

local function syncFleeca(bankId)
    local data = shared.basic[tonumber(bankId) or 0]
    if not data then return end

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('illegal_fleeca:sync_config_data', tonumber(raw), bankId, data, {})
    end
end

local function syncSingle(prefix, kind)
    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent(('%s:sync_config_data'):format(prefix), tonumber(raw), shared[kind], {})
    end
end

local function syncGeneric(kind)
    if kind == 'basic' then
        for bankId in pairs(shared.basic) do syncFleeca(bankId) end
    elseif kind == 'blaneCounty' then
        syncSingle('illegal_blaneCounty', kind)
    else
        syncSingle('illegal_pacificBank', kind)
    end
end

local function guard(src, kind, bankId, stage, checkPolice, index)
    local player = playerOf(src)
    if not player then return false end

    local node = nodeAt(kind, bankId, stage, index)
    if not node then return false end
    if node.isOpened or node.looted then return false end
    if isBusy(kind, bankId, stage, index) then return false end

    local point = node.coords
    if point and not near(src, point, 4.0) then return false end

    local cid = player.PlayerData.citizenid
    if cooling(cid, kind) then return false end

    if checkPolice then
        if limitReached(cid, kind) then return false end

        local need = REQUIRED[kind] or {}
        if countJob('police') < (need.police or 0) then return false end
        if countJob('ems') < (need.ems or 0) then return false end
    end

    return true, player, node
end

local function consume(player, node)
    if not node.requiredItem then return true end

    local src = player.PlayerData.source
    local cid = player.PlayerData.citizenid

    for item, amount in pairs(node.requiredItem) do
        if (ox_inventory:GetItemCount(src, item) or 0) < amount then return false end
    end

    fails[cid] = fails[cid] or {}
    local key = tostring(node.id or 'item')
    fails[cid][key] = (fails[cid][key] or 0) + 1

    local destroy = fails[cid][key] >= MAX_FAILS
    if destroy then fails[cid][key] = 0 end

    for item, amount in pairs(node.requiredItem) do
        if destroy or MECHANIC.removeOnSuccess then
            ox_inventory:RemoveItem(src, item, amount)
        end
    end

    return true
end

lib.callback.register('illegal_fleeca:canExecute', function(src, args)
    if type(args) ~= 'table' then return false end
    return guard(src, 'basic', args[1], args[2], args[3], args[4])
end)

lib.callback.register('illegal_fleeca:consumeItem', function(src, args)
    local player = playerOf(src)
    if not player or type(args) ~= 'table' then return false end

    local node = nodeAt('basic', args[1], args[2], args[3])
    if not node then return false end

    return consume(player, node)
end)

RegisterNetEvent('illegal_fleeca:resetBusy', function(bankId, stage)
    setBusy(false, 'basic', bankId, stage)
end)

RegisterNetEvent('illegal_fleeca:onVaultDoorHacked', function(data)
    local bankId = type(data) == 'table' and data.bankId
    local node = nodeAt('basic', bankId, 'hack_vault_door')
    if not node then return end

    node.isOpened = true
    setBusy(false, 'basic', bankId, 'hack_vault_door')

    pushHistory(playerOf(source) and playerOf(source).PlayerData.citizenid or '', 'basic')
    syncFleeca(bankId)

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('illegal_fleeca:openDoor', tonumber(raw), bankId)
    end
end)

RegisterNetEvent('illegal_fleeca:onBarDoorHacked', function(data)
    local bankId = type(data) == 'table' and data.bankId
    local node = nodeAt('basic', bankId, 'hack_bar_door')
    if not node then return end

    node.isOpened = true
    setBusy(false, 'basic', bankId, 'hack_bar_door')
    syncFleeca(bankId)
end)

RegisterNetEvent('illegal_fleeca:onTrolleyLooted', function(data)
    local src = source
    local bankId, index = data[1], tonumber(data[2])
    local node = nodeAt('basic', bankId, 'loot_trolley', index)
    if not node or node.looted then return end

    node.looted = true
    setBusy(false, 'basic', bankId, 'loot_trolley', index)

    local reward = (REWARDS.basic or {}).trolley
    if reward then ox_inventory:AddItem(src, reward.item, reward.amount) end

    syncFleeca(bankId)
end)

RegisterNetEvent('illegal_fleeca:onDepositBoxDrilled', function(data)
    local src = source
    local bankId, index = data[1], tonumber(data[2])
    local node = nodeAt('basic', bankId, 'drill_deposit_box', index)
    if not node or node.looted then return end

    node.looted = true
    setBusy(false, 'basic', bankId, 'drill_deposit_box', index)

    local box = (REWARDS.basic or {}).deposit_box
    if box then
        if math.random(1, 100) <= (box.lucky.chance or 0) then
            ox_inventory:AddItem(src, box.lucky.item, math.random(1, box.lucky.max or 1))
        else
            local zonk = box.zonk[math.random(#box.zonk)]
            if zonk then ox_inventory:AddItem(src, zonk.item, zonk.amount) end
        end
    end

    syncFleeca(bankId)
end)

local function genericCanExecute(kind, prefix)
    lib.callback.register(('%s:canExecute'):format(prefix), function(src, args)
        if type(args) ~= 'table' then return false end
        return guard(src, kind, nil, args[1], args[2], args[3])
    end)
end

genericCanExecute('blaneCounty', 'illegal_blaneCounty')
genericCanExecute('pacificBank', 'illegal_pacificBank')

lib.callback.register('illegal_blaneCounty:consumeItem', function(src, stage)
    local player = playerOf(src)
    if not player then return false end

    local node = nodeAt('blaneCounty', nil, tostring(stage or ''))
    if not node then return false end

    return consume(player, node)
end)

lib.callback.register('illegal_pacificBank:consumeItem', function(src, doorIndex)
    local player = playerOf(src)
    if not player then return false end

    local node = nodeAt('pacificBank', nil, 'hack_door', doorIndex)
    if not node then return false end

    return consume(player, node)
end)

local function genericReset(kind, prefix)
    RegisterNetEvent(('%s:resetBusy'):format(prefix), function(stage)
        setBusy(false, kind, nil, tostring(stage or ''))
    end)
end

genericReset('blaneCounty', 'illegal_blaneCounty')
genericReset('pacificBank', 'illegal_pacificBank')

local function finish(kind, prefix, stage, index, field)
    local node = nodeAt(kind, nil, stage, index)
    if not node then return nil end

    node[field or 'looted'] = true
    setBusy(false, kind, nil, stage, index)

    return node
end

RegisterNetEvent('illegal_blaneCounty:onComputerHacked', function()
    local player = playerOf(source)
    if player then pushHistory(player.PlayerData.citizenid, 'blaneCounty') end

    finish('blaneCounty', 'illegal_blaneCounty', 'hack_computer', nil, 'isOpened')
    syncGeneric('blaneCounty')
end)

RegisterNetEvent('illegal_blaneCounty:onVaultDoorHacked', function()
    finish('blaneCounty', 'illegal_blaneCounty', 'hack_vault_door', nil, 'isOpened')
    syncGeneric('blaneCounty')
end)

RegisterNetEvent('illegal_blaneCounty:onBarDoorHacked', function()
    finish('blaneCounty', 'illegal_blaneCounty', 'hack_bar_door', nil, 'isOpened')
    syncGeneric('blaneCounty')
end)

RegisterNetEvent('illegal_blaneCounty:onTrolleyLooted', function(data)
    local src = source
    local index = tonumber(type(data) == 'table' and data[1] or data)
    if not finish('blaneCounty', 'illegal_blaneCounty', 'loot_trolley', index) then return end

    local reward = (REWARDS.blaneCounty or {}).trolley
    if reward then ox_inventory:AddItem(src, reward.item, reward.amount) end

    syncGeneric('blaneCounty')
end)

RegisterNetEvent('illegal_blaneCounty:onDepositBoxDrilled', function(data)
    local src = source
    local index = tonumber(type(data) == 'table' and data[1] or data)
    if not finish('blaneCounty', 'illegal_blaneCounty', 'drill_deposit_box', index) then return end

    local reward = (REWARDS.blaneCounty or {}).drill
    if reward then ox_inventory:AddItem(src, reward.item, reward.amount) end

    syncGeneric('blaneCounty')
end)

RegisterNetEvent('illegal_blaneCounty:onDepositBoxDrillFailed', function()
    setBusy(false, 'blaneCounty', nil, 'drill_deposit_box')
end)

RegisterNetEvent('illegal_blaneCounty:onCenterTableLooted', function()
    local src = source
    if not finish('blaneCounty', 'illegal_blaneCounty', 'loot_center_table') then return end

    local table_ = (REWARDS.blaneCounty or {}).centerTable
    if table_ then
        if math.random(1, 100) <= (table_.lucky.chance or 0) then
            ox_inventory:AddItem(src, table_.lucky.item, math.random(1, table_.lucky.max or 1))
        else
            local zonk = table_.zonk[math.random(#table_.zonk)]
            if zonk then ox_inventory:AddItem(src, zonk.item, zonk.amount) end
        end
    end

    syncGeneric('blaneCounty')
end)

RegisterNetEvent('illegal_pacificBank:onDoorHacked', function(data)
    local src = source
    local doorIndex = tonumber(type(data) == 'table' and data[1] or data)
    local player = playerOf(src)

    if player then pushHistory(player.PlayerData.citizenid, 'pacificBank') end

    if not finish('pacificBank', 'illegal_pacificBank', 'hack_door', doorIndex, 'isOpened') then return end

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('illegal_pacificBank:sync_door', tonumber(raw), doorIndex, true)
    end

    syncGeneric('pacificBank')
end)

RegisterNetEvent('illegal_pacificBank:onTrolleyLooted', function(data)
    local src = source
    local index = tonumber(type(data) == 'table' and data[1] or data)
    if not finish('pacificBank', 'illegal_pacificBank', 'loot_trolley', index) then return end

    local reward = (REWARDS.pacificBank or {}).trolley
    if reward then ox_inventory:AddItem(src, reward.item, reward.amount) end

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('illegal_pacificBank:sync_trolley', tonumber(raw), index, true)
    end

    syncGeneric('pacificBank')
end)

RegisterNetEvent('illegal_pacificBank:onDepositBoxDrilled', function(data)
    local src = source
    local index = tonumber(type(data) == 'table' and data[1] or data)
    if not finish('pacificBank', 'illegal_pacificBank', 'drill_deposit_box', index) then return end

    local reward = (REWARDS.pacificBank or {}).drill
    if reward then ox_inventory:AddItem(src, reward.item, reward.amount) end

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('illegal_pacificBank:sync_drill', tonumber(raw), index, true)
    end

    syncGeneric('pacificBank')
end)

RegisterNetEvent('illegal_pacificBank:onDepositBoxDrillFailed', function()
    setBusy(false, 'pacificBank', nil, 'drill_deposit_box')
end)

RegisterNetEvent('illegal_pacificBank:onCenterTableLooted', function()
    local src = source
    if not finish('pacificBank', 'illegal_pacificBank', 'loot_center_table') then return end

    local table_ = (REWARDS.pacificBank or {}).centerTable
    if table_ and table_.rewards then
        local reward = table_.rewards[math.random(#table_.rewards)]
        if reward then ox_inventory:AddItem(src, reward.item, reward.amount) end
    end

    syncGeneric('pacificBank')
end)

RegisterNetEvent('illegal_fleeca:request_config', function()
    TriggerClientEvent('illegal_fleeca:sync_config', source, shared.basic)
end)

RegisterNetEvent('illegal_blaneCounty:request_config', function()
    TriggerClientEvent('illegal_blaneCounty:sync_config', source, shared.blaneCounty)
end)

RegisterNetEvent('illegal_pacificBank:request_config', function()
    TriggerClientEvent('illegal_pacificBank:sync_config', source, shared.pacificBank)
end)

AddEventHandler('playerDropped', function()
    fails[source] = nil
end)

print('^2[fleecarobbery] server siap^7')