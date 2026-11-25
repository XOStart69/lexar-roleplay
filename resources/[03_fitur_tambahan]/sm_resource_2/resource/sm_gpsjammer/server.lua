--[[
    sm_gpsjammer :: server
    Hancurkan GPS target (job tertentu) dengan item jammer.
    Efek "GPS hancur": item GPS target dihapus + event `sm_gpsjammer:server:destroyed`
    supaya sistem dispatch/tracker kamu bisa menangkapnya.
]]

local config = localmodule 'config'

local GPS_ITEM = 'gps'   -- SESUAIKAN dengan nama item GPS di ox_inventory ('' = jangan hapus item)

local sessions, last = {}, {}

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

lib.callback.register('sm_gpsjammer:server:start', function(src, targetId)
    targetId = tonumber(targetId)
    if not targetId or targetId == src then return false end

    local now = GetGameTimer()
    if last[src] and now - last[src] < config.cooldown then return false end

    if (exports.ox_inventory:GetItemCount(src, config.item) or 0) < 1 then
        notify(src, 'Kamu tidak punya GPS Jammer.')
        return false
    end

    local target = qb_ecore:GetPlayer(targetId)
    if not target then return false end

    if not config.jobs[target.PlayerData.job.name] then
        notify(src, 'GPS orang ini tidak bisa dihancurkan.')
        return false
    end

    local a, b = GetPlayerPed(src), GetPlayerPed(targetId)
    if a == 0 or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > config.maxDistance + 2.0 then
        notify(src, 'Targetnya terlalu jauh.')
        return false
    end

    last[src] = now
    sessions[src] = { target = targetId, at = now }
    return true
end)

RegisterTokenEvent('sm_gpsjammer:server:cancel', function()
    sessions[source] = nil
end)

RegisterTokenEvent('sm_gpsjammer:server:finish', function()
    local src = source
    local session = sessions[src]
    sessions[src] = nil

    if not session then return end

    local elapsed = GetGameTimer() - session.at
    if elapsed < config.duration * 0.8 or elapsed > config.timeout then return end

    local target = qb_ecore:GetPlayer(session.target)
    if not target then return end

    local a, b = GetPlayerPed(src), GetPlayerPed(session.target)
    if a == 0 or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > config.maxDistance + 3.0 then return end

    if not exports.ox_inventory:RemoveItem(src, config.item, 1) then return end

    if GPS_ITEM ~= '' then
        local count = exports.ox_inventory:GetItemCount(session.target, GPS_ITEM) or 0
        if count > 0 then exports.ox_inventory:RemoveItem(session.target, GPS_ITEM, count) end
    end

    TriggerEvent('sm_gpsjammer:server:destroyed', session.target, src)
    notify(src, 'GPS berhasil dihancurkan.', 'success')
    notify(session.target, 'GPS-mu rusak!', 'error')
end)

AddEventHandler('playerDropped', function()
    local src = source
    sessions[src], last[src] = nil, nil
end)
