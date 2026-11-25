--[[
    sm_musicpoint :: server
    Titik musik (xsound). Job point dicek di server, volume/radius dibatasi config.
]]

local config = localmodule 'config'

local PREFIX = 'sm_music_'
local USE_DISTANCE = (config.useDistance or 3.0) + 3.0

local playing = {}

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

---@return table?, table?
local function authorize(src, key)
    local point = config.points[tostring(key)]
    local player = qb_ecore:GetPlayer(src)
    if not point or not player then return nil end

    if point.job and player.PlayerData.job.name ~= point.job then return nil end

    local ped = GetPlayerPed(src)
    local coords = point.target or point.coords
    if ped == 0 or #(GetEntityCoords(ped) - coords) > USE_DISTANCE + (point.radius or 0.0) then return nil end

    return point, player
end

local function clamp(value, max)
    return math.max(0, math.min(tonumber(value) or 0, max))
end

RegisterTokenEvent('sm_musicpoint:play', function(key, url, volume, range)
    local src = source
    local point = authorize(src, key)
    if not point then return notify(src, 'Tidak bisa memutar musik di sini.') end

    url = tostring(url or '')
    if #url < 8 or #url > 300 or not url:match('^https?://') then
        return notify(src, 'URL musik tidak valid.')
    end

    local id = PREFIX .. key
    volume = clamp(volume, config.maxVolume)
    range = clamp(range, config.maxRange)

    if playing[key] then exports.xsound:Destroy(-1, id) end

    exports.xsound:PlayUrlPos(-1, id, url, volume / 100, point.coords, false)
    exports.xsound:Distance(-1, id, range)
    playing[key] = true
end)

RegisterTokenEvent('sm_musicpoint:stop', function(key)
    local src = source
    if not authorize(src, key) then return end

    exports.xsound:Destroy(-1, PREFIX .. key)
    playing[key] = nil
end)

RegisterTokenEvent('sm_musicpoint:status', function(key, volume, range)
    local src = source
    if not authorize(src, key) or not playing[key] then return end

    local id = PREFIX .. key
    exports.xsound:setVolume(-1, id, clamp(volume, config.statusMax) / 100)
    exports.xsound:Distance(-1, id, clamp(range, config.statusMax))
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key in pairs(playing) do exports.xsound:Destroy(-1, PREFIX .. key) end
end)
