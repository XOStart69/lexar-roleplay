local CONFIG = require 'shared.config'
local RES = GetCurrentResourceName()
local SAVE_FILE = 'data/saved.json'
local SEED_FILE = 'data/target.lua'

local zones = {}

local function isAllowed(source)
    local identifiers = GetPlayerIdentifiers(source)

    for i = 1, #identifiers do
        if CONFIG.server.permissions[identifiers[i]] then
            return true
        end
    end

    return IsPlayerAceAllowed(source, 'sm_seatcreator.use')
end

local function loadZones()
    local raw = LoadResourceFile(RES, SAVE_FILE)

    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)

        if ok and type(decoded) == 'table' then
            zones = decoded
            return
        end
    end

    local seed = LoadResourceFile(RES, SEED_FILE)

    if not seed then return end

    local chunk = load(seed, '@' .. SEED_FILE)

    if not chunk then return end

    local ok, result = pcall(chunk)

    if ok and type(result) == 'table' then
        zones = result
    end
end

local function saveZones()
    SaveResourceFile(RES, SAVE_FILE, json.encode(zones), -1)
end

local function sync(target)
    TriggerClientEvent('rhd_animplacer:client:sync', target, zones, true)
end

local function sanitize(data)
    local clean = {}

    for id, zone in pairs(data) do
        if type(zone) == 'table' and zone.TargetCoords and zone.TargetRadius then
            local options = {}

            for _, option in pairs(zone.Options or {}) do
                if type(option) == 'table' and option.TargetLabel and option.PlayerCoords and option.Animation then
                    options[#options + 1] = {
                        PlayerCoords = option.PlayerCoords,
                        TargetLabel = option.TargetLabel,
                        TargetIcon = option.TargetIcon,
                        Animation = option.Animation,
                        Emote = option.Emote
                    }
                end
            end

            clean[id] = {
                TargetCoords = zone.TargetCoords,
                TargetRadius = zone.TargetRadius,
                Options = options
            }
        end
    end

    return clean
end

local function notify(source, message)
    TriggerClientEvent('ox_lib:notify', source, { description = message, type = 'error' })
end

RegisterNetEvent('rhd_animplacer:server:saveData', function(data, edit)
    local source = source

    if not isAllowed(source) then
        return notify(source, 'Kamu tidak punya akses seat creator')
    end

    if type(data) ~= 'table' then return end

    zones = sanitize(data)
    saveZones()

    if edit then
        TriggerClientEvent('rhd_animplacer:client:sync', -1, zones, true)
    else
        sync(source)
    end
end)

RegisterNetEvent('sm_seatcreator:server:sync', function()
    sync(source)
end)

RegisterCommand('seatcreator', function(source)
    if source == 0 then return end

    if not isAllowed(source) then
        return notify(source, 'Kamu tidak punya akses seat creator')
    end

    TriggerClientEvent('rhd_animplacer:client:start', source)
end, false)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local source = player and player.PlayerData and player.PlayerData.source

    if source then sync(source) end
end)

AddEventHandler('playerJoining', function()
    local source = source

    SetTimeout(3000, function()
        if GetPlayerName(source) then sync(source) end
    end)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= RES then return end

    loadZones()
end)

lib.print.info('sm_seatcreator server siap')
