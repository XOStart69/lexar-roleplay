local config = localmodule 'config'

local SOUND_PREFIX = 'sm_music_'
local TARGET_DISTANCE = 2.5

---@param job? string
---@return boolean
local function hasJob(job)
    if not job then return true end
    local current = QBPlayerData.job
    return current ~= nil and current.name == job
end

---@param id string
---@return boolean
local function soundExists(id)
    local ok, exists = pcall(exports.xsound.soundExists, exports.xsound, id)
    return ok and exists == true
end

---@param key string
local function playSong(key)
    local input = lib.inputDialog('Putar musik', {
        { type = 'input', icon = 'fab fa-youtube', label = 'URL Musik', required = true },
        { type = 'slider', icon = 'volume-up', label = 'Volume musik', required = true, min = 0, max = config.maxVolume },
        { type = 'slider', icon = 'expand', label = 'Radius musik', required = true, min = 0, max = config.maxRange },
    })
    if not input then return end
    TriggerTokenEvent('sm_musicpoint:play', key, input[1], input[2], input[3])
end

---@param key string
local function changeStatus(key)
    local input = lib.inputDialog('Ubah status musik', {
        { type = 'slider', icon = 'volume-up', label = 'Volume musik', required = true, min = 0, max = config.statusMax },
        { type = 'slider', icon = 'expand', label = 'Radius musik', required = true, min = 0, max = config.statusMax },
    })
    if not input then return end
    TriggerTokenEvent('sm_musicpoint:status', key, input[1], input[2])
end

for key, point in pairs(config.points) do
    local id = SOUND_PREFIX .. key
    local job = point.job

    local function canUse()
        return hasJob(job)
    end

    local function canControl()
        return hasJob(job) and soundExists(id)
    end

    ox_target:addSphereZone({
        coords = point.target or point.coords,
        radius = point.radius,
        name = 'sm_musicpoint_' .. key,
        options = {
            {
                name = 'sm_music_play',
                label = 'Putar musik',
                icon = 'fas fa-play',
                distance = TARGET_DISTANCE,
                canInteract = canUse,
                onSelect = function() playSong(key) end,
            },
            {
                name = 'sm_music_stop',
                label = 'Hentikan musik',
                icon = 'fas fa-pause',
                distance = TARGET_DISTANCE,
                canInteract = canControl,
                onSelect = function() TriggerTokenEvent('sm_musicpoint:stop', key) end,
            },
            {
                name = 'sm_music_status',
                label = 'Ubah status musik',
                icon = 'fas fa-sync-alt',
                distance = TARGET_DISTANCE,
                canInteract = canControl,
                onSelect = function() changeStatus(key) end,
            },
        },
    })
end
