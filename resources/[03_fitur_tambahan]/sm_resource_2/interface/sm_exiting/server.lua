--[[
    sm_exiting :: server
    Simpan posisi + identitas pemain, lalu broadcast kartu keluar ke pemain di sekitarnya saat disconnect.
]]

local config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local RADIUS = config.notifyRadius or 50.0
local cache = {}

local function resolveReason(reason)
    if type(reason) ~= 'string' then return end

    local lower = reason:lower()

    for i = 1, #(config.reasons or {}) do
        local entry = config.reasons[i]

        if entry.keyword and lower:find(entry.keyword:lower(), 1, true) then
            return entry
        end
    end
end

CreateThread(function()
    while true do
        for _, src in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(src)

            if ped ~= 0 then
                local player = QBCore.Functions.GetPlayer(tonumber(src))
                local charinfo = player and player.PlayerData.charinfo

                cache[src] = {
                    coords = GetEntityCoords(ped),
                    name = charinfo and ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '') or 'Unknown',
                    meta = player and player.PlayerData.job and player.PlayerData.job.label or '-'
                }
            end
        end

        Wait(5000)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local snapshot = cache[src]
    cache[src] = nil

    if not snapshot then return end

    local entry = resolveReason(reason)
    if not entry or entry.skip then return end

    local data = {
        name = snapshot.name,
        meta = snapshot.meta,
        reason = entry.detail and reason or '',
        type = entry.type or 'exit',
        coords = { x = snapshot.coords.x, y = snapshot.coords.y, z = snapshot.coords.z }
    }

    for _, other in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(other)

        if ped ~= 0 and #(GetEntityCoords(ped) - snapshot.coords) <= RADIUS then
            TriggerClientEvent('sm_exiting:client:show', tonumber(other), data)
        end
    end
end)