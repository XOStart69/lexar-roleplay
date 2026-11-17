local Config = localmodule 'config'
local ClientUtil = localmodule 'modules/clientutil'

local GetEntityCoords = GetEntityCoords
local GetFinalRenderedCamRot = GetFinalRenderedCamRot
local GetInteriorFromEntity = GetInteriorFromEntity
local GetEntityType = GetEntityType
local DoesEntityExist = DoesEntityExist
local NetworkDoesEntityExistWithNetworkId = NetworkDoesEntityExistWithNetworkId
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local GetVehicleDoorAngleRatio = GetVehicleDoorAngleRatio
local IsVehicleWindowIntact = IsVehicleWindowIntact
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetCloudTimeAsInt = GetCloudTimeAsInt
local SendDuiMessage = SendDuiMessage
local CreateDui = CreateDui
local DestroyDui = DestroyDui
local Wait = Wait

local mathFloor = math.floor
local mathRad = math.rad
local mathSin = math.sin
local mathCos = math.cos
local mathMin = math.min
local mathPi = math.pi

---@type table[]
local sounds = {}
local soundIndex = {}

local isNear = {}
local activeSounds = {}
local duiObjects = {}
local duiReadySlots = {}

local pendingNetIds = {}
local netIdToEntity = {}
local netIdDirty = {}

local sourceFilters = {}
local sourceEntities = {}
local ogSoundIdToSoundId = {}
local ogKeyToSourceId = {}
local restrictedSounds = {}

local musicVolume = 1.0
local safetyPreference = 'all'
local updateInterval = 100
local stopped = false
local slotCounter = 0

local maxActiveDui = Config.maxActiveDui
local hearingRange = Config.hearingRange

local RANGE_MARGIN = 10.0

local tickContext = {}

local DUI_URL = ('https://cfx-nui-%s/interface/sm_audio/web/build/index.html?slot=%%s'):format(cache.resource)

---@param dui number?
---@param data table
local function sendDui(dui, data)
    if not dui then return end
    SendDuiMessage(dui, json.encode(data))
end

---@param value number
---@return number
local function round(value)
    return mathFloor(value * 100 + 0.5) * 0.01
end

---@param rot vector3
local function getCamDirections(rot)
    local radZ = mathRad(rot.z)
    local radX = mathRad(rot.x)
    local radY = mathRad(rot.y)

    return
        mathSin(radZ), mathSin(radX), mathCos(radZ + mathPi),
        mathSin(radY), mathCos(radX), mathSin(radY)
end

---@param dist number
---@param range number
---@param volume number
---@return number
local function getVolume(dist, range, volume)
    if range < dist or musicVolume == 0 then
        return 0
    end

    local minRange = range * 0.1
    if dist <= minRange then
        return volume * musicVolume
    end

    return volume * (1 - (dist - minRange) / (range * 0.9)) * musicVolume
end

---@param soundId string
---@param source table
---@return number|false|nil
local function getSourceEntity(soundId, source)
    local netId = source.netId

    if netId and netIdToEntity[netId] then
        return netIdToEntity[netId]
    end

    local entities = sourceEntities[soundId]
    return entities and entities[source.id] or nil
end

---@param soundId string
---@param source table
local function indexSource(soundId, source)
    local filters = sourceFilters[soundId]
    if not filters then
        filters = {}
        sourceFilters[soundId] = filters
    end

    local list = filters[source.id]
    if not list then
        list = {}
        filters[source.id] = list
    end

    local incoming = source.filters
    if incoming then
        for i = 1, #incoming do
            list[#list + 1] = incoming[i]
        end
    end

    if not sourceEntities[soundId] then
        sourceEntities[soundId] = {}
    end

    local ogSoundId, ogSourceId = source.ogSoundId, source.ogSourceId

    if ogSoundId then
        ogSoundIdToSoundId[ogSoundId] = soundId
    end

    if ogSourceId then
        ogKeyToSourceId[('%s-%s'):format(ogSoundId, ogSourceId)] = source.id
    end

    if ogSoundId and ogSourceId then
        local origin = sourceEntities[ogSoundId]
        if origin and origin[ogSourceId] then
            sourceEntities[soundId][source.id] = origin[ogSourceId]
        end
    end
end

---@param sound table
local function trackSound(sound)
    local count = #sounds + 1
    sounds[count] = sound
    soundIndex[sound.id] = sound

    local sources = sound.sources
    for i = 1, #sources do
        local netId = sources[i].netId
        if netId then
            pendingNetIds[#pendingNetIds + 1] = netId
        end
    end
end

---@param slot number
---@return number
local function createDuiForSlot(slot)
    local dui = CreateDui(DUI_URL:format(slot), 1280, 720)

    local deadline = GetCloudTimeAsInt() + 5
    while not duiReadySlots[slot] and (deadline - GetCloudTimeAsInt()) > 0 do
        Wait(100)
    end

    duiReadySlots[slot] = nil
    return dui
end

---@type function
local getApplicableFilters

---@param sound table
---@param dui number
---@param ctx table?
local function pushSoundCoords(sound, dui, ctx)
    if not dui then return end

    if not ctx then
        local fX, fY, fZ, uX, uY, uZ = getCamDirections(GetFinalRenderedCamRot())

        ctx = {
            coords = GetEntityCoords(cache.ped),
            interior = GetInteriorFromEntity(cache.ped),
            fX = fX, fY = fY, fZ = fZ,
            uX = uX, uY = uY, uZ = uZ,
        }
    end

    local playerCoords = ctx.coords
    local playerInterior = ctx.interior

    local id = sound.id
    local sources = sound.sources
    local muted = restrictedSounds[id]
    local locations = {}
    local count = 0

    for j = 1, #sources do
        local source = sources[j]
        local entity = getSourceEntity(id, source)

        if entity then
            local entityCoords = GetEntityCoords(entity)
            local dist = #(entityCoords - playerCoords)

            count = count + 1
            locations[count] = {
                id = source.id,
                x = round(entityCoords.x),
                y = round(entityCoords.y),
                z = round(entityCoords.z),
                volume = muted and 0.0 or getVolume(dist, source.range, source.volume),
                filters = getApplicableFilters(
                    id, source.id, entity, dist,
                    playerInterior ~= GetInteriorFromEntity(entity),
                    GetEntityType(entity) == 2
                ),
            }
        end
    end

    sendDui(dui, {
        action = 'updateCoords',
        posX = round(playerCoords.x),
        posY = round(playerCoords.y),
        posZ = round(playerCoords.z),
        fX = round(ctx.fX),
        fY = round(ctx.fY) * -1,
        fZ = round(ctx.fZ),
        uX = round(ctx.uX),
        uY = round(ctx.uY),
        uZ = round(ctx.uZ),
        locations = locations,
    })
end

---@param sound table
---@return boolean
local function createSound(sound)
    local skipTo = sound.timer or 0

    if not (sound.paused and sound.timer) then
        skipTo = skipTo + math.max(0, GetCloudTimeAsInt() - (sound.startedAt or 0))
    end

    slotCounter = slotCounter + 1
    if slotCounter >= 60000 then slotCounter = 1 end

    local dui = createDuiForSlot(slotCounter)
    duiObjects[sound.id] = dui

    sendDui(dui, {
        action = 'play',
        id = sound.id,
        videoId = sound.videoId,
        paused = sound.paused,
        skipTo = skipTo,
    })

    pushSoundCoords(sound, dui)

    return true
end

---@param soundId string
local function destroyDui(soundId)
    local dui = duiObjects[soundId]
    if not dui then return end

    DestroyDui(dui)
    duiObjects[soundId] = nil
end

---@param soundId string
---@param sourceId number
---@param vehicleEntity number
---@param dist number
---@param insideInterior boolean
---@param insideVehicle boolean
---@return table
function getApplicableFilters(soundId, sourceId, vehicleEntity, dist, insideInterior, insideVehicle)
    local result = {}

    local bySound = sourceFilters[soundId]
    if not bySound then return result end

    local filters = bySound[sourceId]
    if not filters then return result end

    local count = 0

    for i = 1, #filters do
        local filter = filters[i]
        local method = filter.applyMethod
        local keep = true

        if method == 'insideInterior' then
            keep = insideInterior
        elseif method == 'insideVehicle' then
            keep = insideVehicle

            if keep and vehicleEntity then
                if vehicleEntity == GetVehiclePedIsIn(cache.ped, false)
                    or GetVehicleDoorAngleRatio(vehicleEntity, 0) ~= 0.0
                    or GetVehicleDoorAngleRatio(vehicleEntity, 1) ~= 0.0
                    or GetVehicleDoorAngleRatio(vehicleEntity, 2) ~= 0.0
                    or GetVehicleDoorAngleRatio(vehicleEntity, 3) ~= 0.0
                    or not IsVehicleWindowIntact(vehicleEntity, 0)
                    or not IsVehicleWindowIntact(vehicleEntity, 1)
                    or not IsVehicleWindowIntact(vehicleEntity, 2)
                    or not IsVehicleWindowIntact(vehicleEntity, 3)
                then
                    keep = false
                end
            end
        elseif method == 'distance' then
            if filter.minDist and dist < filter.minDist then
                keep = false
            elseif filter.maxDist and dist > filter.maxDist then
                keep = false
            end
        end

        if keep then
            count = count + 1
            result[count] = filter
        end
    end

    return result
end

RegisterNetEvent('sm_audio:client:receiveAllSounds', function(allSounds)
    if stopped then return end

    for i = 1, #allSounds do
        local sound = allSounds[i]
        local sources = sound.sources

        if sources then
            for j = 1, #sources do
                indexSource(sound.id, sources[j])
            end
        end

        trackSound(sound)
    end
end)

RegisterNetEvent('sm_audio:client:addSound', function(sound)
    if stopped then return end

    trackSound(sound)

    local sources = sound.sources
    if sources then
        for i = 1, #sources do
            indexSource(sound.id, sources[i])
        end
    end
end)

RegisterNetEvent('sm_audio:client:addSoundSource', function(soundId, source)
    local sound = soundIndex[soundId]

    if sound then
        sound.sources[#sound.sources + 1] = source

        if source.netId then
            pendingNetIds[#pendingNetIds + 1] = source.netId
        end
    end

    indexSource(soundId, source)
end)

RegisterNetEvent('sm_audio:client:updateSoundSource', function(soundId, sourceId, data)
    local sound = soundIndex[soundId]
    if not sound then return end

    local sources = sound.sources

    for i = 1, #sources do
        local source = sources[i]

        if source.id == sourceId then
            local newNetId = data.netId

            if newNetId and newNetId ~= source.netId then
                if NetworkDoesEntityExistWithNetworkId(newNetId) then
                    local entity = NetworkGetEntityFromNetworkId(newNetId)
                    if entity and entity ~= 0 and DoesEntityExist(entity) then
                        netIdToEntity[newNetId] = entity
                    end
                end

                pendingNetIds[#pendingNetIds + 1] = newNetId
            end

            if source.netId and source.netId ~= newNetId then
                local oldNetId = source.netId
                SetTimeout(3000, function()
                    netIdDirty[oldNetId] = true
                end)
            end

            source.netId = newNetId
            source.volume = data.volume
            source.range = data.range
            return
        end
    end
end)

RegisterNetEvent('sm_audio:client:updateSoundSourcesVolumes', function(soundId, volumes)
    local sound = soundIndex[soundId]
    if not sound then return end

    local sources = sound.sources

    for i = 1, #sources do
        local volume = volumes[sources[i].id]
        if volume then
            sources[i].volume = volume
        end
    end
end)

RegisterNetEvent('sm_audio:client:removeSoundSource', function(soundId, sourceId)
    local sound = soundIndex[soundId]
    if not sound then return end

    local sources = sound.sources

    for i = 1, #sources do
        if sources[i].id == sourceId then
            sources[i].remove = true

            if sources[i].netId then
                netIdDirty[sources[i].netId] = true
            end

            return
        end
    end
end)

RegisterNetEvent('sm_audio:client:addSoundSourceFilter', function(soundId, sourceId, filter)
    local bySound = sourceFilters[soundId]
    if not bySound then
        bySound = {}
        sourceFilters[soundId] = bySound
    end

    local list = bySound[sourceId]
    if not list then
        list = {}
        bySound[sourceId] = list
    end

    list[#list + 1] = filter
end)

RegisterNetEvent('sm_audio:client:removeSoundSourceFilter', function(soundId, sourceId, filterId)
    local bySound = sourceFilters[soundId]
    if not bySound then return end

    local list = bySound[sourceId]
    if not list then return end

    for i = #list, 1, -1 do
        if list[i].id == filterId then
            table.remove(list, i)
            return
        end
    end
end)

RegisterNetEvent('sm_audio:client:setSoundPaused', function(soundId, paused, data)
    local sound = soundIndex[soundId]
    if not sound then return end

    sound.paused = paused

    if data then
        if data.timer then sound.timer = data.timer end
        if data.startedAt then sound.startedAt = data.startedAt end
    end

    sendDui(duiObjects[soundId], { action = 'updatePaused', state = paused })
end)

RegisterNetEvent('sm_audio:client:removeSound', function(soundId)
    local sound = soundIndex[soundId]
    if not sound then return end

    sound.remove = true

    local sources = sound.sources
    if sources then
        for i = 1, #sources do
            if sources[i].netId then
                netIdDirty[sources[i].netId] = true
            end
        end
    end
end)

RegisterNetEvent('sm_audio:client:updateSound', function(soundId, data)
    local sound = soundIndex[soundId]
    if not sound then return end

    sendDui(duiObjects[soundId], {
        action = 'updateSound',
        videoId = data.videoId,
        skipTo = data.timer,
    })

    sound.startedAt = data.startedAt
    sound.videoId = data.videoId
    sound.timer = data.timer
    sound.paused = data.paused
    sound.finished = false
end)

RegisterNetEvent('sm_audio:client:setSoundIdLicensedStatus', function(soundId, status)
    restrictedSounds[soundId] = status
end)

RegisterNetEvent('sm_audio:client:setSafetyPreference', function(preference, restricted)
    safetyPreference = preference

    if preference == 'nothing' then
        musicVolume = 0.0
    else
        local storedVolume = GetResourceKvpString('sm_audio-volume')
        musicVolume = storedVolume and mathMin(2.0, tonumber(storedVolume) or 1.0) or 1.0
    end

    table.wipe(restrictedSounds)

    if restricted then
        for soundId, status in pairs(restricted) do
            restrictedSounds[soundId] = status
        end
    end

    if preference == 'nothing' then
        table.wipe(isNear)

        for i = 1, #sounds do
            if activeSounds[sounds[i].id] then
                sounds[i].markedForDestroy = true
            end
        end
    end

    TriggerEvent('sm_audio:client:safetyPreferenceChanged', preference)
    TriggerEvent('sm_audio:streamerMode', preference == 'nothing')
end)

AddEventHandler('sm_audio:client:mapEntityToSource', function(soundId, sourceId, entity)
    local entities = sourceEntities[soundId]
    if not entities then
        entities = {}
        sourceEntities[soundId] = entities
    end

    entities[sourceId] = entity

    local mappedSoundId = ogSoundIdToSoundId[soundId]
    local mappedSourceId = ogKeyToSourceId[('%s-%s'):format(soundId, sourceId)]

    if mappedSoundId and mappedSourceId then
        local mapped = sourceEntities[mappedSoundId]
        if not mapped then
            mapped = {}
            sourceEntities[mappedSoundId] = mapped
        end
        mapped[mappedSourceId] = entity
    end
end)

RegisterNUICallback('sm_audio:duiReady', function(data, cb)
    cb(1)
    duiReadySlots[tonumber(data.slotIndex)] = true
end)

RegisterNUICallback('sm_audio:soundFinished', function(data, cb)
    cb('ok')

    local sound = soundIndex[data.id]
    if sound then
        sound.finished = true
    end
end)

CreateThread(function()
    while true do
        Wait(updateInterval)

        if #sounds > 0 then
            local fX, fY, fZ, uX, uY, uZ = getCamDirections(GetFinalRenderedCamRot())

            tickContext.coords = GetEntityCoords(cache.ped)
            tickContext.interior = GetInteriorFromEntity(cache.ped)
            tickContext.fX, tickContext.fY, tickContext.fZ = fX, fY, fZ
            tickContext.uX, tickContext.uY, tickContext.uZ = uX, uY, uZ

            for i = #sounds, 1, -1 do
                local sound = sounds[i]

                if sound.remove then
                    destroyDui(sound.id)
                    activeSounds[sound.id] = nil
                    isNear[sound.id] = nil
                    soundIndex[sound.id] = nil
                    table.remove(sounds, i)
                    goto continue
                end

                if sound.markedForDestroy then
                    sound.markedForDestroy = false
                    activeSounds[sound.id] = nil
                    isNear[sound.id] = nil
                    destroyDui(sound.id)
                    goto continue
                end

                do
                    local id = sound.id
                    if sound.finished or not activeSounds[id] or not isNear[id] then
                        goto continue
                    end

                    local dui = duiObjects[id]
                    local sources = sound.sources

                    for j = #sources, 1, -1 do
                        if sources[j].remove then
                            sendDui(dui, { action = 'removeSoundLocation', locationId = sources[j].id })
                            table.remove(sources, j)
                        end
                    end

                    pushSoundCoords(sound, dui, tickContext)
                end

                ::continue::
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(100)

        for i = 1, #sounds do
            local sound = sounds[i]
            if sound then
                local id = sound.id
                local near = isNear[id]

                if near and not activeSounds[id] and safetyPreference ~= 'nothing' then
                    activeSounds[id] = createSound(sound)
                elseif not near and activeSounds[id] then
                    sound.markedForDestroy = true
                end
            end
        end
    end
end)

local candidates = {}

CreateThread(function()
    while true do
        Wait(1000)

        local count = #sounds

        if count > 0 and safetyPreference ~= 'nothing' then
            local playerCoords = GetEntityCoords(cache.ped)
            local found = 0

            for i = 1, count do
                local sound = sounds[i]

                if sound then
                    local sources = sound.sources
                    local closest

                    for j = 1, #sources do
                        local source = sources[j]
                        local entity = source.netId and netIdToEntity[source.netId] or getSourceEntity(sound.id, source)

                        if entity and DoesEntityExist(entity) then
                            local entityCoords = GetEntityCoords(entity)

                            if entityCoords.x ~= 0.0 or entityCoords.y ~= 0.0 then
                                local dist = #(playerCoords - entityCoords)
                                local audible = mathMin(hearingRange, (source.range or hearingRange) + RANGE_MARGIN)

                                if dist < audible and (not closest or dist < closest) then
                                    closest = dist
                                end
                            end
                        end
                    end

                    if closest then
                        found = found + 1
                        local entry = candidates[found]

                        if entry then
                            entry.id = sound.id
                            entry.dist = closest
                        else
                            candidates[found] = { id = sound.id, dist = closest }
                        end
                    else
                        isNear[sound.id] = nil
                    end
                end
            end

            for i = #candidates, found + 1, -1 do
                candidates[i] = nil
            end

            if found > 1 then
                table.sort(candidates, function(a, b)
                    return a.dist < b.dist
                end)
            end

            for i = 1, found do
                isNear[candidates[i].id] = i <= maxActiveDui or nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        for i = #pendingNetIds, 1, -1 do
            local netId = pendingNetIds[i]

            if netIdDirty[netId] then
                netIdToEntity[netId] = nil
                netIdDirty[netId] = nil
                table.remove(pendingNetIds, i)
                goto continue
            end

            do
                local cached = netIdToEntity[netId]
                if cached and DoesEntityExist(cached) then
                    goto continue
                end

                if not NetworkDoesEntityExistWithNetworkId(netId) then
                    netIdToEntity[netId] = nil
                else
                    local entity = NetworkGetEntityFromNetworkId(netId)
                    netIdToEntity[netId] = (entity and entity ~= 0) and entity or nil
                end
            end

            ::continue::
        end
    end
end)

local function resetAll()
    for i = 1, #sounds do
        destroyDui(sounds[i].id)
    end

    table.wipe(sounds)
    table.wipe(soundIndex)
    table.wipe(activeSounds)
    table.wipe(isNear)
    table.wipe(pendingNetIds)
    table.wipe(netIdToEntity)
    table.wipe(netIdDirty)
    table.wipe(sourceFilters)
    table.wipe(sourceEntities)
    table.wipe(ogSoundIdToSoundId)
    table.wipe(ogKeyToSourceId)
end

RegisterNetEvent('sm_audio:client:stop', function()
    stopped = true
    resetAll()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        resetAll()
    end
end)

RegisterCommand('musicvolume', function(_, args)
    if safetyPreference == 'nothing' then
        ClientUtil.notify(locale("Music volume can't be changed while streamer mode is on."), 'error')
        return
    end

    local value = tonumber(args[1])
    if not value or value < 0 or value > 2 then
        ClientUtil.notify('/musicvolume 0-2', 'error')
        return
    end

    musicVolume = value
    SetResourceKvp('sm_audio-volume', tostring(value))

    ClientUtil.notify(locale('Music volume modifier is now %s.', value), 'success')
    TriggerEvent('sm_audio:client:musicVolumeChanged', value)
end)

RegisterCommand('updateinterval', function()
    local input = lib.inputDialog(locale('Speakers update interval'), {
        {
            type = 'select',
            label = locale('Interval'),
            description = locale('How frequently we send speaker location updates.'),
            options = {
                { value = 50, label = 'High' },
                { value = 100, label = 'Medium' },
                { value = 300, label = 'Low' },
            },
            default = updateInterval,
        },
    })

    if not input then return end

    updateInterval = input[1]
    SetResourceKvpInt('sm_audio-interval', updateInterval)

    for _, dui in pairs(duiObjects) do
        sendDui(dui, { action = 'updateInterval', interval = updateInterval })
    end

    ClientUtil.notify(locale('Update interval is now %s.', updateInterval), 'success')
end)

CreateThread(function()
    local storedInterval = GetResourceKvpInt('sm_audio-interval')
    if storedInterval and storedInterval > 0 then
        updateInterval = storedInterval
    end

    local storedVolume = GetResourceKvpString('sm_audio-volume')
    if storedVolume then
        musicVolume = mathMin(2.0, tonumber(storedVolume) or 1.0)
    end

    TriggerServerEvent('sm_audio:server:requestAllSounds')
end)

exports('getMusicVolume', function()
    return musicVolume
end)

exports('getSafetyPreference', function()
    return safetyPreference
end)

exports('isStreamerMode', function()
    return safetyPreference == 'nothing'
end)
