--[[
    videoPlayer :: server
    Video publik per pelaku. Link divalidasi ke YouTube/Vimeo/MP4 langsung,
    lalu disiarkan ke pemain dalam radius supaya layar bareng.
]]

local RADIUS = 30.0
local DEFAULT_VOLUME = 0.5
local ALLOWED = {
    '^https?://[%w%-%._~:/?#%[%]@!$&\'()*+,;=%%]+$'
}

local playing = {}

local function notify(src, message, nType)
    lib.notify(src, { description = message, type = nType or 'inform' })
end

local function validLink(link)
    if type(link) ~= 'string' or #link > 512 then return false end

    for i = 1, #ALLOWED do
        if link:match(ALLOWED[i]) then return true end
    end

    return false
end

local function nearby(src)
    local coords = GetEntityCoords(GetPlayerPed(src))
    local list = {}

    for _, player in pairs(GetPlayers()) do
        local id = tonumber(player)

        if id then
            local ped = GetPlayerPed(id)

            if ped ~= 0 and #(GetEntityCoords(ped) - coords) <= RADIUS then
                list[#list + 1] = id
            end
        end
    end

    return list, coords
end

RegisterNetEvent('rhd_video_player:submitVideo', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end

    local link = payload.link
    if not validLink(link) then return notify(src, 'Link video tidak valid.', 'error') end

    local volume = tonumber(payload.volume)
    if volume then volume = math.max(0.0, math.min(1.0, volume)) else volume = DEFAULT_VOLUME end

    local list, coords = nearby(src)

    playing[src] = { link = link, volume = volume, coords = coords }

    for i = 1, #list do
        TriggerClientEvent('rhd_video_player:playVideo', list[i], link, volume)
    end

    notify(src, ('Video diputar untuk %d pemain.'):format(#list), 'success')
end)

RegisterNetEvent('rhd_video_player:setVolume', function(payload)
    local src = source
    local state = playing[src]
    if not state then return end

    local volume = tonumber(type(payload) == 'table' and payload.volume or payload)
    if not volume then return end

    volume = math.max(0.0, math.min(1.0, volume))
    state.volume = volume

    local list = nearby(src)

    for i = 1, #list do
        TriggerClientEvent('rhd_video_player:setVolume', list[i], volume)
    end
end)

RegisterNetEvent('rhd_video_player:stopped', function()
    local src = source
    if not playing[src] then return end

    playing[src] = nil

    local list = nearby(src)

    for i = 1, #list do
        TriggerClientEvent('rhd_video_player:sendAction', list[i], 'stop')
    end
end)

lib.addCommand('video', { help = 'Putar video di sekitar' }, function(src)
    TriggerClientEvent('rhd_video_player:sendAction', src, 'play')
end)

AddEventHandler('playerDropped', function()
    local src = source

    if playing[src] then
        playing[src] = nil

        for _, player in pairs(GetPlayers()) do
            local id = tonumber(player)
            if id then TriggerClientEvent('rhd_video_player:sendAction', id, 'stop') end
        end
    end
end)