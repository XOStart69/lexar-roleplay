local config = require 'config.server'
local shared = require 'config.shared'
local net = require 'modules.net'
local Group = require 'modules.groups'

local HISTORY = shared.chatHistory or 100
local MAX_MEMBERS = shared.maxMembers or 8
local NAME_MIN = shared.nameMin or 3
local NAME_MAX = shared.nameMax or 24

local groups = {}
local bySource = {}

local function push(source)
    local id = bySource[source]
    local group = id and groups[id]

    net.emitLatentClient('rhd_playergroup:state', source, group and group:toData() or false)
end

local function pushAll(group)
    for i = 1, #group.members do
        push(group.members[i].source)
    end
end

local function notify(source, kind, text)
    net.emitLatentClient('rhd_playergroup:notify', source, { kind = kind, text = text })
end

local function groupOf(source)
    local id = bySource[source]

    return id and groups[id] or nil
end

local function destroy(group)
    for i = 1, #group.members do
        bySource[group.members[i].source] = nil
    end

    groups[group.id] = nil
    group:release()
end

local function validName(name)
    return type(name) == 'string' and #name >= NAME_MIN and #name <= NAME_MAX
end

lib.callback.register('rhd_playergroup:getState', function(source)
    local group = groupOf(source)

    return group and group:toData() or false
end)

lib.callback.register('rhd_playergroup:create', function(source, name)
    if groupOf(source) then return false, 'Kamu sudah punya grup' end
    if not validName(name) then return false, ('Nama grup %d-%d karakter'):format(NAME_MIN, NAME_MAX) end

    local group = Group(source, name, GetPlayerName(tostring(source)))

    groups[group.id] = group
    bySource[source] = group.id

    push(source)

    return true, group:toData()
end)

lib.callback.register('rhd_playergroup:requestJoin', function(source, groupId)
    local group = groups[groupId]

    if not group then return false, 'Grup tidak ditemukan' end
    if group:hasMember(source) then return false, 'Kamu sudah di grup ini' end
    if groupOf(source) and not config.allowRequestWhileInGroup then return false, 'Keluar dulu dari grup sekarang' end
    if #group.members >= MAX_MEMBERS then return false, 'Grup sudah penuh' end
    if group:hasRequest(source) then return false, 'Permintaan sudah dikirim' end

    group:addRequest({ source = source, name = GetPlayerName(tostring(source)) })

    for i = 1, #group.members do
        notify(group.members[i].source, 'request', ('%s ingin bergabung'):format(GetPlayerName(tostring(source))))
    end

    pushAll(group)

    return true
end)

lib.callback.register('rhd_playergroup:cancelRequest', function(source)
    for id, group in pairs(groups) do
        if group:removeRequest(source) then
            pushAll(groups[id])
            return true
        end
    end

    return false
end)

lib.callback.register('rhd_playergroup:sendChat', function(source, text)
    local group = groupOf(source)

    if not group then return false end
    if type(text) ~= 'string' or text:match('^%s*$') then return false end

    text = text:sub(1, 250)

    local message = group:addChatMessage({
        source = source,
        name = GetPlayerName(tostring(source)),
        text = text,
    }, HISTORY)

    for i = 1, #group.members do
        local member = group.members[i]

        notify(member.source, 'chat', message)

        if config.chatToGameChat then
            TriggerClientEvent('chat:addMessage', member.source, {
                color = config.chatColor,
                multiline = true,
                args = { ('[%s] %s'):format(group.name, message.name), text },
            })
        end
    end

    return true
end)

RegisterNetEvent('rhd_playergroup:leave', function()
    local source = source
    local group = groupOf(source)

    if not group then return end

    group:removeMember(source)
    bySource[source] = nil
    push(source)

    if #group.members == 0 then return destroy(group) end

    if group.owner == source then
        local next = group:transferOwnership()

        if next then notify(next, 'owner', 'Kamu jadi pemilik grup') end
    end

    pushAll(group)
end)

RegisterNetEvent('rhd_playergroup:acceptRequest', function(target)
    local source = source
    local group = groupOf(source)

    if not group or group.owner ~= source then return end
    if not group:hasRequest(target) then return end

    group:removeRequest(target)

    if groupOf(target) then
        pushAll(group)
        return notify(target, 'error', 'Kamu sudah di grup lain')
    end

    group:addMember({ source = target, name = GetPlayerName(tostring(target)) })
    bySource[target] = group.id

    notify(target, 'joined', ('Kamu bergabung ke %s'):format(group.name))

    pushAll(group)
end)

RegisterNetEvent('rhd_playergroup:denyRequest', function(target)
    local source = source
    local group = groupOf(source)

    if not group or group.owner ~= source then return end

    group:removeRequest(target)
    pushAll(group)
end)

RegisterNetEvent('rhd_playergroup:kick', function(target)
    local source = source
    local group = groupOf(source)

    if not group or group.owner ~= source or target == source then return end
    if not group:hasMember(target) then return end

    group:removeMember(target)
    bySource[target] = nil

    notify(target, 'kicked', ('Kamu dikeluarkan dari %s'):format(group.name))
    push(target)
    pushAll(group)
end)

RegisterNetEvent('rhd_playergroup:reachedLocation', function(taskId)
    local source = source
    local group = groupOf(source)

    if not group then return end

    local task = group:getTask(taskId)

    if not task or task.type ~= 'location' or task.isDone or task.isFailed then return end

    group:setTaskDone(taskId)

    for i = 1, #group.members do
        notify(group.members[i].source, 'task', ('%s selesai'):format(task.name))
    end

    pushAll(group)
end)

AddEventHandler('playerDropped', function()
    local source = source
    local group = groupOf(source)

    if not group then return end

    group:removeMember(source)
    bySource[source] = nil

    if #group.members == 0 then return destroy(group) end

    if group.owner == source then
        group:transferOwnership()
    end

    pushAll(group)
end)

lib.print.info('sm_playergroup server siap')
