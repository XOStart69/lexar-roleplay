--[[
    sm_npcmedic :: server
    /helpme   : dokter NPC berbayar kalau tidak ada EMS online (status -> complete).
    /helpems, /doklokems : khusus petugas medis (emsDoctor -> complete).
    Biaya dan revive dilakukan di sini, bukan di client.
]]

local config = localmodule 'config'

local PRICE = config.price or 35000
local INTENT_TTL = 120000

-- SESUAIKAN: job medis yang dihitung sebagai "EMS online" dan boleh memakai /helpems
local EMS_JOBS = { ambulance = true, ems = true, medic = true }

local roxwoodJob = config.roxwood and config.roxwood.job
local roxwoodPoints = config.roxwood and config.roxwood.points or {}

local intent = {}  -- src -> { paid = bool, at = ms }

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function inPolygon(coords, points)
    if #points < 3 then return false end

    local x, y = coords.x, coords.y
    local inside = false
    local j = #points

    for i = 1, #points do
        local xi, yi, xj, yj = points[i].x, points[i].y, points[j].x, points[j].y

        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end

        j = i
    end

    return inside
end

local function isRoxwood(src)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and inPolygon(GetEntityCoords(ped), roxwoodPoints)
end

local function medicsOnDuty(roxwood)
    local total = 0

    for _, raw in ipairs(GetPlayers()) do
        local other = qb_ecore:GetPlayer(tonumber(raw))
        local job = other and other.PlayerData.job

        if job and job.onduty then
            if roxwood then
                if job.name == roxwoodJob then total = total + 1 end
            elseif EMS_JOBS[job.name] then
                total = total + 1
            end
        end
    end

    return total
end

local function canPay(player)
    local money = player.PlayerData.money
    return (money.cash or 0) >= PRICE or (money.bank or 0) >= PRICE
end

local function charge(player)
    for _, account in ipairs({ 'cash', 'bank' }) do
        if (player.PlayerData.money[account] or 0) >= PRICE
            and player.Functions.RemoveMoney(account, PRICE, 'npc-medic') then
            return true
        end
    end
    return false
end

lib.callback.register('sm_npcmedic:server:status', function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return 99, false, false end

    local roxwood = isRoxwood(src)
    local count = medicsOnDuty(roxwood)
    local payable = canPay(player)

    if count == 0 and payable then
        intent[src] = { paid = true, at = GetGameTimer() }
    end

    return count, payable, roxwood
end)

lib.callback.register('sm_npcmedic:server:emsDoctor', function(src, mode)
    local player = qb_ecore:GetPlayer(src)
    if not player then return false, 'Karakter belum siap.' end

    local job = player.PlayerData.job
    if not EMS_JOBS[job.name] and job.name ~= roxwoodJob then
        return false, 'Anda tidak memiliki akses perintah ini.'
    end

    if mode == 'doklokems' then
        if not canPay(player) then return false, 'Uang Anda tidak cukup.' end
        intent[src] = { paid = true, at = GetGameTimer() }
    elseif mode == 'helpems' then
        intent[src] = { paid = false, at = GetGameTimer() }
    else
        return false, 'Mode tidak dikenal.'
    end

    return true
end)

lib.callback.register('sm_npcmedic:server:complete', function(src)
    local current = intent[src]
    intent[src] = nil

    if not current or GetGameTimer() - current.at > INTENT_TTL then return false end

    local player = qb_ecore:GetPlayer(src)
    if not player then return false end

    if current.paid and not charge(player) then
        notify(src, 'Uang Anda tidak cukup untuk membayar dokter.')
        return false
    end

    TriggerClientEvent('ambulance:client:revive', src)
    TriggerClientEvent('hospital:client:RevivePlayer', src)

    if not current.paid then
        player.Functions.SetMetaData('deathCooldown', false)
    end

    return true
end)

RegisterTokenEvent('sm_npcmedic:server:deathCooldown', function(active)
    local player = qb_ecore:GetPlayer(source)
    if not player then return end

    player.Functions.SetMetaData('deathCooldown', active == true)
end)

AddEventHandler('playerDropped', function()
    intent[source] = nil
end)
