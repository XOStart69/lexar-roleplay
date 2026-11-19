local Config = require 'config.config'

local QBCore = exports['qb-core']:GetCoreObject()

local MAX_LEN = 400
local RATE_MS = 400

local lastSent = {}
local typing = {}

local REPORTER_JOBS = {
    reporter = true,
    wartelsm = true,
    digitalden = true,
    digitaldenroxwood = true,
    musicsm = true,
}

local function charinfo(source)
    local Player = QBCore.Functions.GetPlayer(source)

    return Player and Player.PlayerData.charinfo or nil
end

local function fullname(source)
    local info = charinfo(source)

    if not info then return GetPlayerName(tostring(source)) end

    return ('%s %s'):format(info.firstname or '?', info.lastname or '')
end

local function anon(source)
    local Player = QBCore.Functions.GetPlayer(source)

    return Player and Player.PlayerData.job or nil
end

local function broadcast(list, payload)
    for i = 1, #list do
        TriggerClientEvent('sm_chatheme:client:sendMessage', list[i], payload)
    end
end

local function everyone()
    local list = {}

    for _, raw in ipairs(GetPlayers()) do list[#list + 1] = tonumber(raw) end

    return list
end

local function sameJob(source, name)
    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local Player = QBCore.Functions.GetPlayer(src)

        if Player and Player.PlayerData.job.name == name then list[#list + 1] = src end
    end

    return list
end

local function nearby(source, range)
    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return { source } end

    local coords = GetEntityCoords(ped)
    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local other = GetPlayerPed(src)

        if other and other ~= 0 and #(coords - GetEntityCoords(other)) <= range then
            list[#list + 1] = src
        end
    end

    return list
end

local function sameJobFiltered(source, allowed)
    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local Player = QBCore.Functions.GetPlayer(src)

        if Player and allowed[Player.PlayerData.job.name] then list[#list + 1] = src end
    end

    return list
end
local function isAdmin(source)
    return IsPlayerAceAllowed(tostring(source), 'admin')
        or IsPlayerAceAllowed(tostring(source), 'command.adminchat')
        or IsPlayerAceAllowed(tostring(source), 'command.clearallchat')
end

local function rpsHand()
    local hands = { 'Batu', 'Gunting', 'Kertas' }

    return hands[math.random(#hands)]
end

local function charinfoText(source)
    local info = charinfo(source)
    local Player = QBCore.Functions.GetPlayer(source)

    if not info or not Player then return 'Data karakter tidak tersedia' end

    local job = Player.PlayerData.job

    return ('Nama: %s %s | Lahir: %s | Kelamin: %s | Warga: %s | Pekerjaan: %s'):format(
        info.firstname or '?',
        info.lastname or '',
        info.birthdate or '?',
        info.gender == 1 and 'Perempuan' or 'Laki-laki',
        info.nationality or '?',
        job and job.label or '-'
    )
end

local function imageOk(url)
    if type(url) ~= 'string' then return false end

    for i = 1, #Config.ImageSettings.allowedURLs do
        if url:find(Config.ImageSettings.allowedURLs[i], 1, true) == 1 then return true end
    end

    return false
end

RegisterNetEvent('sm_chatheme:server:writing', function(state)
    local source = source

    state = state == true

    if typing[source] == state then return end

    typing[source] = state

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)

        if target ~= source then
            TriggerClientEvent('sm_chatheme:client:writingText', target, source, state)
        end
    end
end)

lib.callback.register('sm_chatheme:callback:getFrameworkJobs', function()
    local list = {}

    for name in pairs(QBCore.Shared.Jobs or {}) do list[#list + 1] = name end

    table.sort(list)

    return list
end)

RegisterNetEvent('sm_chatheme:server:clearAllChat', function()
    local source = source

    if not isAdmin(source) then return end

    TriggerClientEvent('sm_chatheme:client:clearAllChat', -1)
end)

RegisterNetEvent('sm_chatheme:server:sendMessage', function(data)
    local source = source

    if type(data) ~= 'table' or type(data.category) ~= 'string' then return end

    local now = GetGameTimer()

    if lastSent[source] and now - lastSent[source] < RATE_MS then return end

    lastSent[source] = now

    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then return end

    local category = data.category
    local mask = data.mask == true and Config.AnonymousWithMask
    local name = mask and 'Warga Tak Dikenal' or fullname(source)

    local payload = {
        category = category,
        source = source,
        fullname = name,
        mask = mask,
        isImage = false,
        id = ('%d_%d'):format(source, now),
    }

    if category == 'charinfo' then
        payload.message = charinfoText(source)
        payload.fullname = 'Identitas'
    elseif category == 'dice' then
        payload.message = ('Melempar dadu: %d'):format(math.random(1, 6))
        payload.isDice = true
    elseif category == 'rps' then
        payload.hand = rpsHand()
        payload.message = ('Memilih: %s'):format(payload.hand)
        payload.isRPS = true
    elseif category == 'custom' then
        payload.message = data.message
        payload.isImage = data.isImage == true
    else
        if type(data.message) ~= 'string' then return end

        local text = data.message:gsub('^%s+', '')

        if text == '' then return end

        if data.isImage then
            if not imageOk(text) then return end
            payload.isImage = true
        end

        payload.message = text:sub(1, MAX_LEN)
    end

    local job = Player.PlayerData.job.name

    if category == '311' then
        if not Config.Chat311Jobs[job] then
            return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Job kamu tidak punya akses 311' })
        end

        return broadcast(sameJobFiltered(source, Config.Chat311Jobs), payload)
    end

    if category == 'iklan' or category == 'berita' then
        if not REPORTER_JOBS[job] then
            return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Hanya reporter yang bisa /' .. category })
        end

        return broadcast(everyone(), payload)
    end

    if category == 'joba' then
        payload.category = Config.MessageColors['joba_' .. job] and ('joba_' .. job) or 'joba'

        return broadcast(sameJob(source, job), payload)
    end

    if category == 'jobc' then
        payload.category = 'jobc'

        return broadcast(sameJob(source, job), payload)
    end

    if category == 'oocl' then
        return broadcast(nearby(source, 30.0), payload)
    end

    if category == 'adminchat' then
        if not isAdmin(source) then
            return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Bukan admin' })
        end

        local list = {}

        for _, raw in ipairs(GetPlayers()) do
            local src = tonumber(raw)

            if isAdmin(src) then list[#list + 1] = src end
        end

        return broadcast(list, payload)
    end

    broadcast(everyone(), payload)
end)


AddEventHandler('playerDropped', function()
    local source = source

    lastSent[source] = nil

    if typing[source] then
        typing[source] = nil

        for _, raw in ipairs(GetPlayers()) do
            TriggerClientEvent('sm_chatheme:client:writingText', tonumber(raw), source, false)
        end
    end
end)

lib.print.info('sm_chatheme server siap')
