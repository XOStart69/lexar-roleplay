local nearbyPlayers
local playerBusy = false

local IsEntityOnScreen = IsEntityOnScreen
local IsEntityOccluded = IsEntityOccluded
local RemoveMpGamerTag = RemoveMpGamerTag
local IsMpGamerTagFree = IsMpGamerTagFree
local GetPlayerServerId = GetPlayerServerId
local IsMpGamerTagActive = IsMpGamerTagActive
local SetMpGamerTagVisibility = SetMpGamerTagVisibility
local SetMpGamerTagColour = SetMpGamerTagColour
local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local GetEntityCollisionDisabled = GetEntityCollisionDisabled
local CreateMpGamerTagWithCrewColor = CreateMpGamerTagWithCrewColor

local function onPressed()
    if playerBusy then
        return
    end

    local myCoords = GetEntityCoords(cache.ped)

    if not nearbyPlayers then
        nearbyPlayers = lib.getNearbyPlayers(myCoords, 5.0, true)
    end

    lib.array.forEach(nearbyPlayers, function (v)
        local playerId = v.id
        local serverId = GetPlayerServerId(v.id)
        local playerState = Player(serverId).state

        local isNew, isHealing

        if playerState then
            isNew = playerState.antitroll
            isHealing = playerState.healing_progress
        end

        local isPedNoclip = GetEntityCollisionDisabled(v.ped)
        local isInvisible = playerState and playerState.invisible

        if not isPedNoclip and
            not isInvisible and
            IsEntityOnScreen(v.ped) and
            not IsEntityOccluded(v.ped) and
            HasEntityClearLosToEntity(cache.ped, v.ped, 17) and
            not IsMpGamerTagActive(playerId)
        then
            local displayName = ('%s [%s] %s'):format(
                isNew and '[NEW]' or '',
                serverId,
                isHealing and '(healing in progress)' or ''
            )

            CreateMpGamerTagWithCrewColor(
                playerId,
                displayName,
                false,
                false,
                '',
                0, 255, 255, 255
            )

            SetMpGamerTagVisibility(playerId, 0, true)

            if isHealing then
                SetMpGamerTagColour(playerId, 0, 6) -- 6 = merah
            end
        end
    end)
end

local function onReleased()
    if not nearbyPlayers then return end

    lib.array.forEach(nearbyPlayers, function (v)
        local playerId = v.id
        if IsMpGamerTagActive(playerId) then
            RemoveMpGamerTag(playerId)
            repeat Wait(0) until IsMpGamerTagFree(playerId)
        end
    end)
    nearbyPlayers = nil
end

lib.addKeybind({
    name = 'lihatID',
    description = 'Lihat ID pemain',
    defaultKey = 'LMENU',
    onPressed = onPressed,
    onReleased = onReleased
})