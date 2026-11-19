local VOLUME = 0.3

local function coordsOf(source)
    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return nil end

    return GetEntityCoords(ped)
end

RegisterNetEvent('InteractSound_SV:PlayOnOne', function(soundFile, soundVolume)
    if type(soundFile) ~= 'string' then return end

    TriggerClientEvent('InteractSound_CL:PlayOnOne', source, soundFile, tonumber(soundVolume) or VOLUME)
end)

RegisterNetEvent('InteractSound_SV:PlayOnAll', function(soundFile, soundVolume)
    if type(soundFile) ~= 'string' then return end

    TriggerClientEvent('InteractSound_CL:PlayOnAll', -1, soundFile, tonumber(soundVolume) or VOLUME)
end)

RegisterNetEvent('InteractSound_SV:PlayWithinDistance', function(distance, soundFile, soundVolume)
    if type(soundFile) ~= 'string' then return end

    local coords = coordsOf(source)

    if not coords then return end

    distance = tonumber(distance) or 10.0

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('InteractSound_CL:PlayWithinDistance', tonumber(raw), coords, distance, soundFile, tonumber(soundVolume) or VOLUME)
    end
end)

lib.print.info('interact-sound server siap')
