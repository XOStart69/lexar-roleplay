-- Rekonstruksi sm_core/server/events.lua

AddEventHandler('playerDropped', function()
    local src = source
    local player = QBCore.Players[src]
    if not player then return end

    player.Functions.Save()
    TriggerEvent('QBCore:Server:OnPlayerUnload', src)

    QBCore.Player_Buckets[src] = nil
    QBCore.Players[src] = nil
end)

-- Toggle duty dari client (misal lewat menu/radial)
RegisterNetEvent('QBCore:ToggleDuty', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local onDuty = not player.PlayerData.job.onduty
    player.Functions.SetJobDuty(onDuty)
    QBCore.Functions.Notify(src, Lang:t(onDuty and 'info.on_duty' or 'info.off_duty'), onDuty and 'success' or 'inform')
end)

-- Client hanya boleh mengubah status kebutuhan dasar (hunger/thirst/stress).
-- Versi qb-core asli mengizinkan metadata apa pun dari client; itu celah, jadi dibatasi di sini.
local clientMeta = { hunger = true, thirst = true, stress = true }

RegisterNetEvent('QBCore:Server:SetMetaData', function(meta, data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if not clientMeta[meta] or type(data) ~= 'number' then return end

    player.Functions.SetMetaData(meta, data)

    if meta == 'hunger' or meta == 'thirst' then
        TriggerClientEvent('hud:client:UpdateNeeds', src,
            player.PlayerData.metadata.hunger, player.PlayerData.metadata.thirst)
    end
end)

-- Resource lain (mis. sm_character) sering memanggil ini setelah karakter dipilih.
-- Hanya diteruskan sebagai event server; core tidak melakukan apa-apa selain broadcast.
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    if not QBCore.Players[src] then return end
    TriggerEvent('QBCore:Server:PlayerLoadedFromClient', src)
end)
