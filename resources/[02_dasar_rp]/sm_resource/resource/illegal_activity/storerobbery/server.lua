--[[
    storerobbery :: server
    Kunci per tahap per toko, PIN brankas dari server, limit perampokan per warga.
]]

local cfg = localmodule 'config.storerobbery'

local REQUIRED = cfg.requiredJob or {}
local ITEM = cfg.requiredItem or 'advancedlockpick'
local MECHANIC = cfg.itemMechanic or {}
local REWARD = cfg.reward or {}
local LIMIT = cfg.robberyLimit or {}
local MAX_TRY = cfg.maxTry or {}
local SHOPS = cfg.locations or {}

local MAX_FAILS = MECHANIC.maxFails or 2
local LIMIT_MAX = LIMIT.max or 2
local LIMIT_WINDOW = (LIMIT.time or 60) * 60

local busy = {}
local pins = {}
local tries = {}
local fails = {}
local history = {}

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
    return #(GetEntityCoords(ped) - coords) <= radius
end

local function key(stage, shopId)
    return ('%s:%s'):format(stage, shopId)
end

local function isBusy(stage, shopId)
    return busy[key(stage, shopId)] == true
end

local function setBusy(stage, shopId, state)
    if state then
        busy[key(stage, shopId)] = true
    else
        busy[key(stage, shopId)] = nil
    end
end

local function broadcast(keyName, value)
    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('storerobbery:sync', tonumber(raw), keyName, value)
    end
end

local function windowCount(cid)
    history[cid] = history[cid] or {}
    local stamp = os.time()
    local kept = {}

    for i = 1, #history[cid] do
        if stamp - history[cid][i] <= LIMIT_WINDOW then kept[#kept + 1] = history[cid][i] end
    end

    history[cid] = kept
    return #kept
end

lib.callback.register('storerobbery:canExecute', function(src, data)
    local player = playerOf(src)
    if not player or type(data) ~= 'table' then return false end

    local shopId = tostring(data.shopId or '')
    local shop = SHOPS[shopId]
    if not shop then return false end

    local stage = data.stage and tostring(data.stage) or nil

    if stage then
        local point = shop[stage]
        if not point then return false end
        if point.looted then return false end
        if isBusy(stage, shopId) then return false end
        if not near(src, point.coords, 3.5) then return false end
    end

    if data.checkPolice then
        if shop.robbed then return false end
        if countJob('police') < (REQUIRED.police or 0) then return false end
        if countJob('ems') < (REQUIRED.ems or 0) then return false end
        if windowCount(player.PlayerData.citizenid) >= LIMIT_MAX then return false end
    end

    return true
end)

lib.callback.register('storerobbery:consumeLockpick', function(src, shopId)
    if (ox_inventory:GetItemCount(src, ITEM) or 0) < 1 then return false end

    fails[src] = fails[src] or {}
    fails[src][shopId] = (fails[src][shopId] or 0) + 1

    if fails[src][shopId] >= MAX_FAILS then
        fails[src][shopId] = 0
        ox_inventory:RemoveItem(src, ITEM, 1)
        notify(src, ('%s hancur.'):format(ITEM))
        return true
    end

    if MECHANIC.removeOnSuccess then ox_inventory:RemoveItem(src, ITEM, 1) end
    return true
end)

RegisterNetEvent('storerobbery:resetBusy', function(stage, shopId, state)
    setBusy(tostring(stage or ''), tostring(shopId or ''), state)
end)

RegisterNetEvent('storerobbery:onRegisterLooted', function(shopId, dispatch)
    local src = source
    local player = playerOf(src)
    local shop = SHOPS[tostring(shopId or '')]
    if not player or not shop or shop.register.looted then return end

    shop.register.looted = true
    shop.robbed = true
    setBusy('register', shopId, false)

    local cash = (REWARD.cash_register or {}).black_money or 0
    if cash > 0 then ox_inventory:AddItem(src, 'black_money', cash) end

    local bonus = REWARD.bonus
    if bonus and math.random(1, 100) <= (bonus.chance or 0) then
        ox_inventory:AddItem(src, bonus.item, math.random(bonus.min or 1, bonus.max or 1))
    end

    history[player.PlayerData.citizenid] = history[player.PlayerData.citizenid] or {}
    history[player.PlayerData.citizenid][#history[player.PlayerData.citizenid] + 1] = os.time()

    broadcast(('%s.register'):format(shopId), true)
    broadcast(('%s.robbed'):format(shopId), true)

    if dispatch then
        for _, raw in ipairs(GetPlayers()) do
            local target = playerOf(tonumber(raw))
            if target and target.PlayerData.job.name == 'police' then
                TriggerClientEvent('storerobbery:client:dispatch', tonumber(raw), shop.register.coords)
            end
        end
    end
end)

RegisterNetEvent('storerobbery:onComputerHacked', function(shopId)
    local src = source
    shopId = tostring(shopId or '')

    local shop = SHOPS[shopId]
    if not shop or shop.computer.looted then return end

    shop.computer.looted = true
    setBusy('computer', shopId, false)

    local code = ('%04d'):format(math.random(0, 9999))
    pins[shopId] = code
    tries[shopId] = MAX_TRY.safe or 3

    TriggerClientEvent('storerobbery:onComputerHacked', src, code)
    broadcast(('%s.computer'):format(shopId), true)

    local computer = REWARD.computer or {}
    if computer.lucky and math.random(1, 100) <= (computer.lucky.chance or 0) then
        ox_inventory:AddItem(src, computer.lucky.item, math.random(1, computer.lucky.max or 1))
    elseif computer.zonk then
        local zonk = computer.zonk[math.random(#computer.zonk)]
        if zonk then ox_inventory:AddItem(src, zonk.item, math.random(zonk.min or 1, zonk.max or 1)) end
    end
end)

lib.callback.register('storerobbery:validateSafePin', function(src, data)
    if type(data) ~= 'table' then return false end

    local shopId = tostring(data.shopId or '')
    local shop = SHOPS[shopId]
    if not shop or not pins[shopId] then return false end

    if tostring(data.pin or '') ~= pins[shopId] then
        tries[shopId] = (tries[shopId] or 1) - 1
        if tries[shopId] <= 0 then
            pins[shopId] = nil
            setBusy('safe', shopId, false)
            notify(src, 'Brankas terkunci ulang.')
        end
        return false
    end

    pins[shopId] = nil
    return true
end)

RegisterNetEvent('storerobbery:onSafeHacked', function(shopId)
    local src = source
    shopId = tostring(shopId or '')

    local shop = SHOPS[shopId]
    if not shop or shop.safe.looted then return end

    shop.safe.looted = true
    setBusy('safe', shopId, false)

    local cash = (REWARD.safe or {}).black_money or 0
    if cash > 0 then ox_inventory:AddItem(src, 'black_money', cash) end

    broadcast(('%s.safe'):format(shopId), true)
end)

RegisterNetEvent('storerobbery:server:open', function(shopId)
    local src = source
    local shop = SHOPS[tostring(shopId or '')]
    if not shop then return end
    if not near(src, shop.register.coords, 4.0) then return end

    TriggerClientEvent('storerobbery:client:open', src, shopId)
end)

AddEventHandler('playerDropped', function()
    fails[source] = nil
end)

print('^2[storerobbery] server siap^7')