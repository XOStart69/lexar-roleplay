--[[
    sm_drugsell :: server
    Jual item ke bandar NPC. Harga acak per butir dalam rentang config.items.
]]

local config = localmodule 'config'

local MAX_PER_SALE = 10          -- SESUAIKAN: maksimal butir per transaksi
local POLICE_JOBS = { police = true, sasp = true, bcso = true, usmarshal = true }

local ITEMS = {}
for i = 1, #config.items do ITEMS[config.items[i].name] = config.items[i] end

local sessions, last = {}, {}

local function hasAccess(player)
    local job = player.PlayerData.job
    local grade = config.access[job.name]
    return grade ~= nil and (job.grade.level or 0) >= grade
end

local function policeOnline()
    local total = 0
    for _, raw in ipairs(GetPlayers()) do
        local p = qb_ecore:GetPlayer(tonumber(raw))
        if p and POLICE_JOBS[p.PlayerData.job.name] and p.PlayerData.job.onduty then total = total + 1 end
    end
    return total
end

lib.callback.register('sm_drugsell:start', function(src, name)
    local player = qb_ecore:GetPlayer(src)
    if not player then return false, 'Karakter belum siap.' end

    local item = ITEMS[tostring(name)]
    if not item then return false, 'Item tidak dijual di sini.' end
    if not hasAccess(player) then return false, 'Bandar tidak mengenalmu.' end

    local now = GetGameTimer()
    if last[src] and now - last[src] < config.cooldown then return false, 'Tunggu sebentar.' end

    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - config.ped.coords.xyz) > config.sellDistance + 4.0 then
        return false, 'Terlalu jauh dari bandar.'
    end

    if (config.minPolice or 0) > 0 and policeOnline() < config.minPolice then
        return false, 'Bandar sedang tidak mau transaksi.'
    end

    local count = exports.ox_inventory:GetItemCount(src, item.name) or 0
    if count < 1 then return false, 'Kamu tidak punya barangnya.' end

    last[src] = now
    sessions[src] = { item = item, at = now }
    return true
end)

lib.callback.register('sm_drugsell:finish', function(src)
    local session = sessions[src]
    sessions[src] = nil

    local player = qb_ecore:GetPlayer(src)
    if not session or not player then return false end
    if GetGameTimer() - session.at < config.sellDuration * 0.8 then return false end

    local item = session.item
    local count = math.min(exports.ox_inventory:GetItemCount(src, item.name) or 0, MAX_PER_SALE)
    if count < 1 then return false end

    if not exports.ox_inventory:RemoveItem(src, item.name, count) then return false end

    local reward = 0
    for _ = 1, count do reward = reward + math.random(item.min, item.max) end

    player.Functions.AddMoney('cash', reward, 'drugsell-' .. item.name)

    return true, count, reward
end)

AddEventHandler('playerDropped', function()
    local src = source
    sessions[src], last[src] = nil, nil
end)
