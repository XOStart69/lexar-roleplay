local MAX_MEMBERS = 8

local groups = {}
local playerGroup = {}
local seq = 0

local function memberList(group)
    local list = {}

    for src, name in pairs(group.members) do
        list[#list + 1] = { serverId = src, name = name }
    end

    return list
end

local function push(groupId)
    local group = groups[groupId]

    if not group then return end

    local list = memberList(group)

    for src in pairs(group.members) do
        TriggerClientEvent('sm_emote:updateGroup', src, list)
    end
end

local function countMembers(group)
    local count = 0

    for _ in pairs(group.members) do
        count += 1
    end

    return count
end

local function dropGroup(groupId)
    local group = groups[groupId]

    if not group then return end

    for src in pairs(group.members) do
        playerGroup[src] = nil
        TriggerClientEvent('sm_emote:updateGroup', src, {})
    end

    groups[groupId] = nil
end

lib.callback.register('sm_emote:getPlayerGroup', function(source)
    local groupId = playerGroup[source]

    if not groupId then return {} end

    local group = groups[groupId]

    if not group then return {} end

    return memberList(group)
end)

lib.callback.register('sm_emote:invitePlayer', function(source, data)
    local target = type(data) == 'table' and tonumber(data.serverId) or tonumber(data)

    if not target or target == source then return false end
    if not GetPlayerName(target) then return false end
    if playerGroup[target] then return false end

    local groupId = playerGroup[source]

    if not groupId then
        seq += 1
        groupId = ('grp_%s'):format(seq)
        groups[groupId] = { owner = source, members = {} }
        groups[groupId].members[source] = GetPlayerName(source)
        playerGroup[source] = groupId
        push(groupId)
    end

    local group = groups[groupId]

    if not group then return false end
    if countMembers(group) >= MAX_MEMBERS then return false end

    local accepted = lib.callback.await('sm_emote:invitePlayer', target, GetPlayerName(source))

    if not accepted then return false end
    if not groups[groupId] then return false end

    group.members[target] = GetPlayerName(target)
    playerGroup[target] = groupId
    push(groupId)

    return true
end)

lib.callback.register('sm_emote:removePlayer', function(source, data)
    local groupId = playerGroup[source]

    if not groupId then return false end

    local group = groups[groupId]
    local target = type(data) == 'table' and tonumber(data.serverId) or tonumber(data)

    if not group or not target or not group.members[target] then return false end
    if group.owner ~= source and target ~= source then return false end

    group.members[target] = nil
    playerGroup[target] = nil

    TriggerClientEvent('sm_emote:updateGroup', target, {})

    if target == group.owner or countMembers(group) == 0 then
        dropGroup(groupId)
    else
        push(groupId)
    end

    return true
end)

lib.callback.register('sm_emote:leaveGroup', function(source)
    local groupId = playerGroup[source]

    if not groupId then return false end

    local group = groups[groupId]

    if not group then return false end

    group.members[source] = nil
    playerGroup[source] = nil
    TriggerClientEvent('sm_emote:updateGroup', source, {})

    if group.owner == source or countMembers(group) == 0 then
        dropGroup(groupId)
    else
        push(groupId)
    end

    return true
end)

RegisterNetEvent('sm_emote:playGroupEmote', function(command, texture)
    local source = source
    local groupId = playerGroup[source]

    if not groupId or type(command) ~= 'string' then return end

    local group = groups[groupId]

    if not group then return end

    for src in pairs(group.members) do
        TriggerClientEvent('sm_emote:playGroupEmote', src, source, command, texture)
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    local groupId = playerGroup[source]

    if not groupId then return end

    local group = groups[groupId]

    if not group then return end

    group.members[source] = nil
    playerGroup[source] = nil

    if group.owner == source or countMembers(group) == 0 then
        dropGroup(groupId)
    else
        push(groupId)
    end
end)

lib.print.info('sm_emotes group siap')
