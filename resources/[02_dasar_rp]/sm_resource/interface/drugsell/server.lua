--[[
    drugsell :: server
    Jual barang terlarang ke NPC pelanggan. Jumlah, harga, dan item diambil dari
    state bag ped supaya klien tidak bisa mengarang harga.
]]

local cfg = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local SELLING = cfg.selling or {}
local PRICE_MIN = SELLING.price and SELLING.price.min or 6000
local PRICE_MAX = SELLING.price and SELLING.price.max or 10000
local JACKPOT = SELLING.price and SELLING.price.jackpot or 20000
local MAX_SELL = SELLING.maxSell or 10
local REQUIRED_JOB = cfg.start and cfg.start.requiredJob

local sold = {}

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function isAllowedJob(src)
    local player = QBCore.Functions.GetPlayer(src)
    local job = player and player.PlayerData.job

    if not job or not REQUIRED_JOB then return true end
    if not REQUIRED_JOB[job.name] then return false end

    if job.onduty == false then return false end

    local grade = tonumber(type(job.grade) == 'table' and job.grade.level or job.grade) or 0
    return grade >= (REQUIRED_JOB[job.name] or 0)
end

lib.callback.register('drugsell:canStart', function(src)
    if not isAllowedJob(src) then
        notify(src, 'Job kamu tidak bisa berjualan sekarang (atau sedang off duty).', 'error')
        return false
    end

    return true
end)

lib.callback.register('drugsell:sell', function(src, netId)
    if not isAllowedJob(src) then return false end

    netId = tonumber(netId)
    if not netId then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then return false end

    local state = Entity(entity).state
    local data = state.drugsell

    if not data or not data.available then return false end

    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end
    if data.owner ~= player.PlayerData.citizenid then return false end

    local item = data.item
    local count = tonumber(data.count) or 0
    local price = tonumber(data.price) or 0

    if not item or count <= 0 then return false end
    if price < PRICE_MIN or price > JACKPOT then price = math.random(PRICE_MIN, PRICE_MAX) end

    if exports.ox_inventory:GetItemCount(src, item) < count then
        notify(src, ('Kamu tidak punya %dx %s.'):format(count, item), 'error')
        return false
    end

    if not exports.ox_inventory:RemoveItem(src, item, count) then return false end

    local total = count * price
    player.Functions.AddMoney('cash', total, 'drug-sell')

    data.available = false
    state:set('drugsell', data, true)

    sold[src] = (sold[src] or 0) + 1

    notify(src, ('%dx %s terjual $%s.'):format(count, item, total), 'success')

    if sold[src] >= MAX_SELL then
        sold[src] = 0
        notify(src, 'Batas penjualan tercapai, kembali ke banda.', 'warning')
    end

    return true
end)

AddEventHandler('playerDropped', function()
    sold[source] = nil
end)