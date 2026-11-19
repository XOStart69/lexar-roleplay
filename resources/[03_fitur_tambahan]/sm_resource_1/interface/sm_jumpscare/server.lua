--[[
    sm_jumpscare :: server
    Kirim jumpscare (gambar + suara) ke pemain lain, dibatasi job/ace, jarak, dan cooldown.
]]

local Config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local cooldown = {}

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function allowed(src)
    if Config.ace then
        return IsPlayerAceAllowed(src, Config.ace)
    end

    local player = ply(src)
    if not player then return false end

    local job = player.PlayerData.job
    if not job then return false end

    local required = Config.jobs and Config.jobs[job.name]
    if not required then return false end

    if type(required) == 'table' then
        for i = 1, #required do
            if required[i] == job.grade.level then return true end
        end

        return false
    end

    return job.grade.level >= required
end

lib.callback.register('sm_jumpscare:canUse', function(src)
    return allowed(src)
end)

lib.callback.register('sm_jumpscare:send', function(src, target, sound, url)
    if not allowed(src) then
        return { success = false, message = 'Kamu tidak punya akses.' }
    end

    target = tonumber(target)

    if not target or not ply(target) then
        return { success = false, message = 'Player target tidak ditemukan.' }
    end

    if target == src then
        return { success = false, message = 'Tidak bisa mengirim ke diri sendiri.' }
    end

    if type(url) ~= 'string' or not url:match('^https?://') then
        return { success = false, message = 'URL gambar tidak valid.' }
    end

    if #url > (Config.maxUrlLength or 500) then
        return { success = false, message = 'URL terlalu panjang.' }
    end

    local validSound = false
    for i = 1, #(Config.sounds or {}) do
        if Config.sounds[i].value == sound then
            validSound = true
            break
        end
    end

    if not validSound then
        return { success = false, message = 'Sound tidak dikenal.' }
    end

    local maxDistance = Config.maxDistance or 0
    if maxDistance > 0 then
        local from = GetEntityCoords(GetPlayerPed(src))
        local to = GetEntityCoords(GetPlayerPed(target))

        if #(from - to) > maxDistance then
            return { success = false, message = 'Target di luar jangkauan.' }
        end
    end

    local player = ply(src)
    local citizenid = player.PlayerData.citizenid
    local wait = cooldown[citizenid]

    if wait and wait > os.time() then
        return { success = false, message = ('Tunggu %d detik lagi.'):format(wait - os.time()) }
    end

    cooldown[citizenid] = os.time() + (Config.cooldown or 10)

    TriggerClientEvent('jumpscare:show', target, sound, url)

    return { success = true, message = ('Jumpscare dikirim ke ID %d.'):format(target) }
end)