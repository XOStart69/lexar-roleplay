local target_dance = {}

local emotes = require 'data.emotes'.shared

---@param emoteData CacheEmote
local function allowedSync(emoteData)
    local category = emoteData?.category
    local customDance = emoteData.category == 'customanimations' and not (
        emoteData.secondPlayersAnim
    )

    return category and (
        category == 'dances' or customDance
    )
end

---@param ped number
---@param source number
---@param emote string
---@param keepHeading? boolean
function target_dance.sync(ped, source, emote, keepHeading)
    if not (ped and source and emote) then
        return
    end

    local emoteData = emotes[emote] ---@type CacheEmote

    if not (emoteData and allowedSync(emoteData)) then
        return
    end

    local dict, anim in emoteData

    if IsEntityPlayingAnim(source, dict, anim, 3) then
        local targetTime = GetEntityAnimCurrentTime(source, dict, anim)

        if not keepHeading then
            SetEntityHeading(ped, GetEntityHeading(source))
        end

        SetEntityAnimCurrentTime(ped, dict, anim, targetTime)
    end
end

---@param entity number
---@return number? serverId
---@return string? emote
---@return CacheEmote? emotedata
local function getSyncTarget(entity)
    local playerId = NetworkGetPlayerIndexFromPed(entity)
    local serverId = GetPlayerServerId(playerId)
    local emote = Player(serverId).state.currentEmote

    if not emote then
        lib.notify({
            description = 'Player tidak sedang melakukan emote',
            type = 'error'
        })
        return
    end

    local emotedata = emotes[emote] ---@type CacheEmote

    if not emotedata then
        lib.notify({
            description = 'Emote data tidak ditemukan',
            type = 'error'
        })
        return
    end

    if not allowedSync(emotedata) then
        lib.notify({
            description = 'Emote ini tidak bisa di-sync',
            type = 'error'
        })
        return
    end

    if not IsEntityPlayingAnim(entity, emotedata.dict, emotedata.anim, 3) then
        return
    end

    return serverId, emote, emotedata
end

local function syncSamePosition(data)
    local entity = data.entity
    local serverId, _, emotedata = getSyncTarget(entity)

    if not emotedata then return end

    local dict, anim in emotedata

    Emote.play(emotedata)

    Wait(300)

    if IsEntityPlayingAnim(entity, dict, anim, 3) then
        local heading = GetEntityHeading(entity)
        local targetTime = GetEntityAnimCurrentTime(entity, dict, anim)
        SetEntityAnimCurrentTime(cache.ped, dict, anim, targetTime)
        SetEntityHeading(cache.ped, heading)
        LocalPlayer.state:set('targetAnim', serverId, true)
    else
        Emote.cancel()
    end
end

local function syncFreePosition(data)
    local entity = data.entity
    local serverId, emote, emotedata = getSyncTarget(entity)

    if not emotedata then return end

    local dict, anim in emotedata

    placement.start(emote, function()
        Wait(300)

        if not DoesEntityExist(entity) then return end

        if not IsEntityPlayingAnim(entity, dict, anim, 3) then return end

        if not IsEntityPlayingAnim(cache.ped, dict, anim, 3) then return end

        local targetTime = GetEntityAnimCurrentTime(entity, dict, anim)

        SetEntityAnimCurrentTime(cache.ped, dict, anim, targetTime)
        LocalPlayer.state:set('targetAnim', { source = serverId }, true)
    end, true)
end

CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        {
            label = 'Sync Emote',
            icon = 'fas fa-child-reaching',
            distance = 1.5,
            onSelect = syncSamePosition
        },
        {
            label = 'Sync Emote (Atur Posisi)',
            icon = 'fas fa-arrows-up-down-left-right',
            distance = 3.0,
            onSelect = syncFreePosition
        },
    })
end)

_ENV.target_dance = target_dance
