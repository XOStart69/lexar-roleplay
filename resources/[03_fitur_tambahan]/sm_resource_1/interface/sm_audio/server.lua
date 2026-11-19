--[[
    sm_audio :: server
    Speaker per citizenid, izin lewat permissions.lua, grup, filter, attach kendaraan.
]]

local Config = localmodule 'config'
local Util = localmodule 'modules.util'
local Net = localmodule 'modules.net'
local PERM = localmodule 'modules.permissions'
local RateLimit = localmodule 'modules.ratelimit'

local ITEM = Config.inventoryItemId or 'speaker'
local ADMIN = Config.adminPrincipal or 'group.admin'
local MAX_PER_PLAYER = Config.speakersAllowedPerPlayer or 4
local RATE = Config.rateLimit or {}
local PUBLIC = Config.publicSpeakerPermissions or {}
local FILTER_LIMITS = Config.filterLimits or {}
local MAX_VOLUME = 1.0
local MAX_RANGE = 50.0

local TYPES = {}
for id, image in pairs(Config.typeImages or {}) do
    TYPES[tonumber(id)] = { id = tonumber(id), image = image, maxVolume = MAX_VOLUME, maxRange = MAX_RANGE }
end

local SPEAKERS = 'sm_audio_speakers'
local GROUPS = 'sm_audio_groups'
local MEMBERS = 'sm_audio_group_members'

local speakers = {}
local groups = {}
local rate = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function isAdmin(src)
    return IsPlayerAceAllowed(src, ADMIN)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function limited(src, expensive)
    local gap = expensive and (RATE.expensive or 3000) or (RATE.default or 1000)
    return not RateLimit.check(src, expensive and 'expensive' or 'default', gap)
end

local function quotaOf(src)
    local player = playerOf(src)
    if not player then return 0 end

    local limit = MAX_PER_PLAYER

    for _, raw in ipairs(GetPlayers()) do
        local other = tonumber(raw)
        if other == src then
            local ids = GetPlayerIdentifiers(src) or {}
            for i = 1, #ids do
                local extra = Config.speakerWhitelist and Config.speakerWhitelist[ids[i]]
                if extra then limit = extra break end
            end
        end
    end

    local used = 0
    for _, speaker in pairs(speakers) do
        if speaker.owner == player.PlayerData.citizenid then used = used + 1 end
    end

    return limit - used
end

local function canUse(src, speaker, key)
    if not speaker then return false end
    if isAdmin(src) then return true end

    local player = playerOf(src)
    if not player then return false end

    local cid = player.PlayerData.citizenid
    if speaker.owner == cid then return true end

    if speaker.group_id then
        local member = MySQL.single.await(
            'SELECT 1 AS ok FROM ' .. MEMBERS .. ' WHERE group_id = ? AND citizenid = ?', { speaker.group_id, cid }
        )
        if member then return true end
    end

    if speaker.is_public and PUBLIC[key] then return true end

    return false
end

local function pack(speaker)
    return {
        id = speaker.id,
        typeId = speaker.type_id,
        coords = vector3(speaker.x, speaker.y, speaker.z),
        heading = speaker.h,
        volume = speaker.volume,
        range = speaker.range_v,
        public = speaker.is_public == true or speaker.is_public == 1,
        permanent = speaker.is_permanent == true or speaker.is_permanent == 1,
        groupId = speaker.group_id,
        plate = speaker.plate,
        owner = speaker.owner,
        filters = speaker.filters and json.decode(speaker.filters) or {},
        safety = speaker.safety,
        typeImage = Config.typeImages and Config.typeImages[speaker.type_id],
        maxVolume = MAX_VOLUME,
        maxRange = MAX_RANGE,
    }
end

local function store(speaker)
    MySQL.update(
        ('UPDATE %s SET x = ?, y = ?, z = ?, h = ?, volume = ?, range_v = ?, is_public = ?, group_id = ?, plate = ?, filters = ?, safety = ?, seen = ? WHERE id = ?'):format(SPEAKERS),
        {
            speaker.x, speaker.y, speaker.z, speaker.h, speaker.volume, speaker.range_v,
            speaker.is_public and 1 or 0, speaker.group_id, speaker.plate,
            speaker.filters, speaker.safety, os.time(), speaker.id,
        }
    )
end

local function broadcastAll(event, ...)
    Net.emitLatentAll(event, ...)
end

lib.callback.register('sm_audio:server:getInteractionData', function(src, speakerId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker then return false, nil end

    local allowed = {
        playMusic = canUse(src, speaker, PERM.PLAY_MUSIC),
        useQueue = canUse(src, speaker, PERM.QUEUE),
        pauseResume = canUse(src, speaker, PERM.PAUSE_RESUME),
        volumeRange = canUse(src, speaker, PERM.VOLUME_RANGE),
        addGroup = canUse(src, speaker, PERM.ADD_GROUP),
        rename = canUse(src, speaker, PERM.RENAME),
        useFilters = canUse(src, speaker, PERM.FILTERS),
        settings = canUse(src, speaker, PERM.SETTINGS),
        carry = canUse(src, speaker, PERM.CARRY),
        store = canUse(src, speaker, PERM.STORE),
        gizmo = canUse(src, speaker, PERM.GIZMO),
        attachVehicle = canUse(src, speaker, PERM.VEHICLE_ATTACH),
        permanent = canUse(src, speaker, PERM.PERMANENT),
    }

    return true, { allowed = allowed, speaker = pack(speaker) }
end)

lib.callback.register('sm_audio:server:requestStartup', function(src)
    local points, filters = {}, {}

    for id, speaker in pairs(speakers) do
        points[#points + 1] = { id = id, coords = vector3(speaker.x, speaker.y, speaker.z), typeId = speaker.type_id }
        filters[id] = speaker.filters and json.decode(speaker.filters) or {}
    end

    return points, filters, FILTER_LIMITS
end)

lib.callback.register('sm_audio:server:requestSoundTypes', function()
    return TYPES
end)

lib.callback.register('sm_audio:server:requestAttachRegistry', function()
    local out = {}
    for id, speaker in pairs(speakers) do
        if speaker.plate then out[#out + 1] = { id = id, plate = speaker.plate } end
    end
    return out
end)

lib.callback.register('sm_audio:server:requestAllSounds', function()
    return {}
end)

lib.callback.register('sm_audio:server:createSpeaker', function(src, typeId, coords, heading, attach)
    if limited(src, true) then return nil end
    if quotaOf(src) <= 0 then notify(src, 'Kuota speaker habis.') return nil end

    local player = playerOf(src)
    if not player then return nil end
    if type(coords) ~= 'table' then return nil end

    local typeData = TYPES[tonumber(typeId) or 0]
    if not typeData then return nil end

    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
    if #(GetEntityCoords(GetPlayerPed(src)) - pos) > 5.0 then return nil end

    if (ox_inventory:GetItemCount(src, ITEM) or 0) < 1 then
        notify(src, 'Speaker tidak ada di tas.')
        return nil
    end

    if not ox_inventory:RemoveItem(src, ITEM, 1) then return nil end

    local name = Util.generateSpeakerName()
    local speaker = {
        owner = player.PlayerData.citizenid,
        type_id = tonumber(typeId),
        x = pos.x, y = pos.y, z = pos.z,
        h = (tonumber(heading) or 0.0) % 360.0,
        volume = Config.defaultVolume or 0.3,
        range_v = math.min(Config.defaultRange or 25.0, typeData.maxRange or 25.0),
        is_public = Config.speakersPublicByDefault,
        is_permanent = Config.speakersPermanentByDefault,
        filters = '{}',
        safety = true,
        plate = type(attach) == 'table' and attach.plate or nil,
    }

    local id = MySQL.insert.await(
        ('INSERT INTO %s (owner, type_id, name, x, y, z, h, volume, range_v, is_public, is_permanent, filters, safety, plate, created, seen) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(SPEAKERS),
        {
            speaker.owner, speaker.type_id, name, speaker.x, speaker.y, speaker.z, speaker.h,
            speaker.volume, speaker.range_v, speaker.is_public and 1 or 0, speaker.is_permanent and 1 or 0,
            speaker.filters, 1, speaker.plate, os.time(), os.time(),
        }
    )

    if not id then return nil end

    speaker.id = id
    speaker.name = name
    speakers[id] = speaker

    broadcastAll('sm_audio:client:speakerCreated', pack(speaker))

    return pack(speaker)
end)

lib.callback.register('sm_audio:server:removeSpeaker', function(src, speakerId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.STORE) then return false end

    speakers[speaker.id] = nil
    MySQL.update('DELETE FROM ' .. SPEAKERS .. ' WHERE id = ?', { speaker.id })

    broadcastAll('sm_audio:client:speakerRemoved', speaker.id)
    return true
end)

lib.callback.register('sm_audio:server:carrySpeaker', function(src, speakerId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.CARRY) then return false end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - vector3(speaker.x, speaker.y, speaker.z)) > 4.0 then return false end

    if not ox_inventory:AddItem(src, ITEM, 1, { speakerId = speaker.id }) then return false end

    speaker.plate = nil
    speaker.carried = true
    store(speaker)

    broadcastAll('sm_audio:client:speakerRemoved', speaker.id)
    return true
end)

lib.callback.register('sm_audio:server:dropSpeaker', function(src, speakerId, coords, heading)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.CARRY) then return false end
    if type(coords) ~= 'table' then return false end

    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)

    speaker.x, speaker.y, speaker.z = pos.x, pos.y, pos.z
    speaker.h = (tonumber(heading) or 0.0) % 360.0
    speaker.carried = nil
    store(speaker)

    broadcastAll('sm_audio:client:speakerCreated', pack(speaker))
    return true
end)

lib.callback.register('sm_audio:server:attachSpeaker', function(src, speakerId, plate, offset, rot)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.VEHICLE_ATTACH) then return false end
    if type(offset) ~= 'table' then return false end

    speaker.plate = tostring(plate or '')
    speaker.attach_offset = json.encode(offset)
    speaker.attach_rot = json.encode(rot or {})
    store(speaker)

    broadcastAll('sm_audio:client:speakerAttached', speaker.id, speaker.plate, offset, rot)
    return true
end)

lib.callback.register('sm_audio:server:detachSpeaker', function(src, speakerId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not speaker.plate then return false end
    if Config.onlyOwnerCanDetachFromVehicle then
        local player = playerOf(src)
        if player and player.PlayerData.citizenid ~= speaker.owner and not isAdmin(src) then return false end
    end

    speaker.plate = nil
    store(speaker)

    broadcastAll('sm_audio:client:speakerDetached', speaker.id)
    return true
end)

lib.callback.register('sm_audio:server:renameSpeaker', function(src, speakerId, name)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.RENAME) then return false end

    name = tostring(name or ''):sub(1, 32)
    if name == '' then return false end

    speaker.name = name
    MySQL.update('UPDATE ' .. SPEAKERS .. ' SET name = ? WHERE id = ?', { name, speaker.id })

    broadcastAll('sm_audio:client:speakerRenamed', speaker.id, name)
    return true
end)

lib.callback.register('sm_audio:server:changeVolumeRange', function(src, speakerId, input)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.VOLUME_RANGE) then return false end

    local typeData = TYPES[speaker.type_id] or {}

    local volume = math.min(math.max(tonumber(input.volume) or speaker.volume, 0.0), typeData.maxVolume or 1.0)
    local range = math.min(math.max(tonumber(input.range) or speaker.range_v, 1.0), typeData.maxRange or 25.0)

    speaker.volume, speaker.range_v = Util.formatFloat(volume), Util.formatFloat(range)
    store(speaker)

    broadcastAll('sm_audio:client:speakerVolume', speaker.id, speaker.volume, speaker.range_v)
    return true
end)

lib.callback.register('sm_audio:server:playMusic', function(src, speakerId, input)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.PLAY_MUSIC) then return false, 'Tidak punya izin.' end
    if limited(src, true) then return false, 'Terlalu cepat.' end

    input = tostring(input or '')
    if input == '' then return false end

    local url, videoId, playlistId, startTime

    if Util.isValidYouTubeUrl(input) then
        url = Util.formatShortUrl(input)
        videoId, playlistId, startTime = Util.getYouTubeIds(url)
    else
        url = input
    end

    broadcastAll('sm_audio:client:playMusic', speaker.id, {
        url = url, videoId = videoId, playlistId = playlistId,
        startTime = startTime and Util.isoToSeconds(startTime) or 0,
    })

    return true
end)

lib.callback.register('sm_audio:server:addToQueue', function(src, speakerId, input)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.QUEUE) then return false end

    local url = Util.formatShortUrl(tostring(input or ''))
    if not Util.isValidYouTubeUrl(url) then return false end

    local videoId, playlistId = Util.getYouTubeIds(url)
    broadcastAll('sm_audio:client:queueAdd', speaker.id, { url = url, videoId = videoId, playlistId = playlistId })

    return true
end)

lib.callback.register('sm_audio:server:nextQueuedSong', function(src, speakerId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.QUEUE) then return false end

    broadcastAll('sm_audio:client:queueNext', speaker.id)
    return true
end)

lib.callback.register('sm_audio:server:pauseResume', function(src, speakerId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.PAUSE_RESUME) then return false end

    broadcastAll('sm_audio:client:pauseResume', speaker.id)
    return true
end)

local function sanitizeFilter(filterType, values)
    local allowed = Config.filters and Config.filters[filterType]
    if not allowed then return nil end

    local out = {}
    for i = 1, #allowed do
        local key = allowed[i]
        local limit = FILTER_LIMITS[key]
        local value = tonumber(values[key])

        if limit then
            value = math.min(math.max(value or limit.default, limit.min), limit.max)
        end

        out[key] = value
    end

    return out
end

lib.callback.register('sm_audio:server:addFilter', function(src, speakerId, filterType, values)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.FILTERS) then return false end

    local clean = sanitizeFilter(tostring(filterType or ''), type(values) == 'table' and values or {})
    if not clean then return false end

    local list = speaker.filters and json.decode(speaker.filters) or {}
    list[#list + 1] = { type = filterType, values = clean }

    speaker.filters = json.encode(list)
    store(speaker)

    broadcastAll('sm_audio:client:filtersChanged', speaker.id, list)
    return true
end)

lib.callback.register('sm_audio:server:addForcedFilter', function(src, speakerId, filterType, values)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not isAdmin(src) then return false end

    local clean = sanitizeFilter(tostring(filterType or ''), type(values) == 'table' and values or {})
    if not clean then return false end

    local list = speaker.filters and json.decode(speaker.filters) or {}
    list[#list + 1] = { type = filterType, values = clean, forced = true }

    speaker.filters = json.encode(list)
    store(speaker)

    broadcastAll('sm_audio:client:filtersChanged', speaker.id, list)
    return true
end)

lib.callback.register('sm_audio:server:updateForcedFilter', function(src, speakerId, index, values)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not isAdmin(src) then return false end

    local list = speaker.filters and json.decode(speaker.filters) or {}
    local entry = list[tonumber(index) or 0]
    if not entry or not entry.forced then return false end

    local clean = sanitizeFilter(entry.type, type(values) == 'table' and values or {})
    if not clean then return false end

    entry.values = clean
    speaker.filters = json.encode(list)
    store(speaker)

    broadcastAll('sm_audio:client:filtersChanged', speaker.id, list)
    return true
end)

lib.callback.register('sm_audio:server:createGroup', function(src, name)
    local player = playerOf(src)
    if not player then return nil end

    name = tostring(name or ''):sub(1, 32)
    if name == '' then return nil end

    local id = MySQL.insert.await('INSERT INTO ' .. GROUPS .. ' (owner, name, created) VALUES (?, ?, ?)', {
        player.PlayerData.citizenid, name, os.time(),
    })

    if not id then return nil end

    MySQL.insert('INSERT IGNORE INTO ' .. MEMBERS .. ' (group_id, citizenid) VALUES (?, ?)', {
        id, player.PlayerData.citizenid,
    })

    groups[id] = { id = id, owner = player.PlayerData.citizenid, name = name, volume = 0.3 }

    return groups[id]
end)

lib.callback.register('sm_audio:server:accessGroup', function(src, groupId)
    local player = playerOf(src)
    local group = groups[tonumber(groupId) or 0]
    if not player or not group then return nil end

    local member = MySQL.single.await(
        'SELECT 1 AS ok FROM ' .. MEMBERS .. ' WHERE group_id = ? AND citizenid = ?', { group.id, player.PlayerData.citizenid }
    )

    if not member and group.owner ~= player.PlayerData.citizenid then return nil end

    local members = MySQL.query.await('SELECT citizenid FROM ' .. MEMBERS .. ' WHERE group_id = ?', { group.id }) or {}

    return { group = group, members = members }
end)

lib.callback.register('sm_audio:server:addSpeakerToGroup', function(src, speakerId, groupId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.ADD_GROUP) then return false end

    speaker.group_id = tonumber(groupId)
    store(speaker)

    broadcastAll('sm_audio:client:speakerGroup', speaker.id, speaker.group_id)
    return true
end)

lib.callback.register('sm_audio:server:removeSpeakerFromGroup', function(src, speakerId)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.ADD_GROUP) then return false end

    speaker.group_id = nil
    store(speaker)

    broadcastAll('sm_audio:client:speakerGroup', speaker.id, nil)
    return true
end)

lib.callback.register('sm_audio:server:changeSafetyPreference', function(src, speakerId, state)
    local speaker = speakers[tonumber(speakerId) or 0]
    if not speaker or not canUse(src, speaker, PERM.SETTINGS) then return false end

    speaker.safety = state and 1 or 0
    store(speaker)

    broadcastAll('sm_audio:client:speakerSafety', speaker.id, speaker.safety == 1)
    return true
end)

lib.callback.register('sm_audio:server:requestShop', function(src)
    if not Config.shop or not Config.shop.enabled then return nil end
    return TYPES
end)

lib.callback.register('sm_audio:server:purchaseSpeaker', function(src, typeId)
    local player = playerOf(src)
    local typeData = TYPES[tonumber(typeId) or 0]
    if not player or not typeData or not typeData.price then return false end

    if not player.Functions.RemoveMoney('bank', typeData.price, 'speaker') then
        if not player.Functions.RemoveMoney('cash', typeData.price, 'speaker') then return false end
    end

    return ox_inventory:AddItem(src, ITEM, 1, { speakerType = tonumber(typeId) })
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `sm_audio_speakers` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `owner` varchar(64) NOT NULL,
        `type_id` int(11) NOT NULL,
        `name` varchar(48) DEFAULT NULL,
        `x` double NOT NULL, `y` double NOT NULL, `z` double NOT NULL, `h` double NOT NULL DEFAULT 0,
        `volume` double NOT NULL DEFAULT 0.3,
        `range_v` double NOT NULL DEFAULT 25,
        `is_public` tinyint(1) NOT NULL DEFAULT 0,
        `is_permanent` tinyint(1) NOT NULL DEFAULT 0,
        `group_id` int(11) DEFAULT NULL,
        `filters` longtext DEFAULT NULL,
        `safety` tinyint(1) NOT NULL DEFAULT 1,
        `plate` varchar(16) DEFAULT NULL,
        `created` int(11) NOT NULL,
        `seen` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `owner` (`owner`),
        KEY `group_id` (`group_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `sm_audio_groups` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `owner` varchar(64) NOT NULL,
        `name` varchar(48) NOT NULL,
        `volume` double NOT NULL DEFAULT 0.3,
        `created` int(11) NOT NULL,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `sm_audio_group_members` (
        `group_id` int(11) NOT NULL,
        `citizenid` varchar(64) NOT NULL,
        PRIMARY KEY (`group_id`, `citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local rows = MySQL.query.await('SELECT * FROM ' .. SPEAKERS) or {}
    for i = 1, #rows do speakers[rows[i].id] = rows[i] end

    local groupRows = MySQL.query.await('SELECT * FROM ' .. GROUPS) or {}
    for i = 1, #groupRows do groups[groupRows[i].id] = groupRows[i] end

    while true do
        Wait(600000)
        local cut = os.time() - ((Config.abandonedSpeakerHours or 24) * 3600)

        local stale = MySQL.query.await(
            ('SELECT id FROM %s WHERE is_permanent = 0 AND plate IS NULL AND seen < ?'):format(SPEAKERS), { cut }
        ) or {}

        for i = 1, #stale do
            speakers[stale[i].id] = nil
            MySQL.update('DELETE FROM ' .. SPEAKERS .. ' WHERE id = ?', { stale[i].id })
            broadcastAll('sm_audio:client:speakerRemoved', stale[i].id)
        end
    end
end)

AddEventHandler('playerDropped', function()
    rate[source] = nil
end)

print('^2[sm_audio] server siap^7')