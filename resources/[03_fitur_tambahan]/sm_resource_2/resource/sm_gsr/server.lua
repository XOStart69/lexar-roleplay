--[[
    sm_gsr :: server
    Cek residu mesiu: server menanyakan status ke client target, lalu menampilkan hasilnya.
]]

local config = localmodule 'config'

local JOBS = {}
for i = 1, #config.jobs do JOBS[config.jobs[i]] = true end

local last = {}

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'inform' })
end

RegisterTokenEvent('sm_gsr:server:check', function(targetId)
    local src = source
    targetId = tonumber(targetId)
    if not targetId then return end

    local player = qb_ecore:GetPlayer(src)
    if not player or not JOBS[player.PlayerData.job.name] then
        return notify(src, 'Kamu tidak berwenang.', 'error')
    end

    local now = GetGameTimer()
    if last[src] and now - last[src] < config.cooldown then return end
    last[src] = now

    if not qb_ecore:GetPlayer(targetId) then return end

    local a, b = GetPlayerPed(src), GetPlayerPed(targetId)
    if a == 0 or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > config.checkDistance + 3.0 then
        return notify(src, 'Targetnya terlalu jauh.', 'error')
    end

    local ok, positive = pcall(lib.callback.await, 'sm_gsr:client:status', targetId, 3000)
    if not ok then return notify(src, 'Gagal membaca hasil.', 'error') end

    if positive then
        notify(src, 'Terdeteksi residu mesiu pada tangan target.', 'warning')

        local center = GetEntityCoords(b)
        for _, raw in ipairs(GetPlayers()) do
            local id = tonumber(raw)
            local ped = GetPlayerPed(id)
            if ped ~= 0 and #(GetEntityCoords(ped) - center) <= (config.particle.viewRadius or 10.0) then
                TriggerClientEvent('sm_gsr:client:particle', id, targetId)
            end
        end
    else
        notify(src, 'Tidak terdeteksi residu mesiu.', 'success')
    end
end)

AddEventHandler('playerDropped', function()
    last[source] = nil
end)
