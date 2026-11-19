--[[
    adjudicator :: server
    Pengumuman antar organisasi. Pengirim memilih organisasi tujuan, pesan diteruskan
    ke semua anggota online organisasi itu.
]]

local Config = localmodule 'config.shared'

local QBCore = exports['qb-core']:GetCoreObject()

local ORGS = Config or {}
local MESSAGE_MAX = 400
local COOLDOWN_MS = 5000
local SHOW_MS = 12000

local cooldown = {}

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function orgLabel(name)
    for i = 1, #ORGS do
        if ORGS[i].name == name then return ORGS[i].label end
    end
end

local function jobOf(src)
    local player = QBCore.Functions.GetPlayer(src)
    local job = player and player.PlayerData.job

    return job and job.name or nil
end

lib.callback.register('adjudicator:getMenu', function(src)
    local name = jobOf(src)
    if not name or not orgLabel(name) then return nil end

    local online = {}

    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        local job = player.PlayerData.job

        if job and orgLabel(job.name) then
            online[job.name] = (online[job.name] or 0) + 1
        end
    end

    local list = {}

    for i = 1, #ORGS do
        local org = ORGS[i]

        if org.name ~= name then
            list[#list + 1] = {
                name = org.name,
                label = org.label,
                online = online[org.name] or 0
            }
        end
    end

    return {
        from = name,
        fromLabel = orgLabel(name),
        orgs = list
    }
end)

lib.callback.register('adjudicator:send', function(src, target, message)
    local name = jobOf(src)
    if not name or not orgLabel(name) then return { ok = false, error = 'Kamu bukan anggota organisasi.' } end

    local now = GetGameTimer()
    if cooldown[src] and now < cooldown[src] then
        return { ok = false, error = 'Tunggu sebentar sebelum mengirim lagi.' }
    end

    if type(target) ~= 'string' or not orgLabel(target) then
        return { ok = false, error = 'Organisasi tujuan tidak valid.' }
    end

    if type(message) ~= 'string' then return { ok = false, error = 'Pesan kosong.' } end

    message = message:gsub('^%s*(.-)%s*$', '%1')
    if #message < 3 then return { ok = false, error = 'Pesan terlalu pendek.' } end
    if #message > MESSAGE_MAX then message = message:sub(1, MESSAGE_MAX) end

    cooldown[src] = now + COOLDOWN_MS

    local payload = {
        from = orgLabel(name),
        message = message,
        duration = SHOW_MS
    }

    local sent = 0

    for _, player in pairs(QBCore.Functions.GetQBPlayers()) do
        local job = player.PlayerData.job
        local playerSrc = player.PlayerData.source

        if job and job.name == target and playerSrc then
            TriggerClientEvent('adjudicator:show', playerSrc, payload)
            sent = sent + 1
        end
    end

    return { ok = true, sent = sent }
end)

AddEventHandler('playerDropped', function()
    cooldown[source] = nil
end)