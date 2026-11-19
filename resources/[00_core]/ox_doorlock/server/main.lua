local framework = require 'server.framework.qb'

local doors = {}
local doorState = {}

local function authorised(source)
    if Config.PlayerAceAuthorised then return true end

    return IsPlayerAceAllowed(tostring(source), 'command.doorlock')
end

local function buildRow(row)
    local data = json.decode(row.data) or {}

    data.id = row.id
    data.name = row.name
    data.state = row.state
    data.coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    data.maxDistance = data.maxDistance or 1.5
    data.hideUi = nil

    return data
end

local function load()
    table.wipe(doors)

    local rows = MySQL.query.await('SELECT id, name, data, state FROM ox_doorlock')

    if not rows then return end

    for i = 1, #rows do
        local door = buildRow(rows[i])

        doors[door.id] = door
        doorState[door.id] = door.state
    end
end

CreateThread(function()
    load()
end)

local function broadcast(id, state, source)
    TriggerClientEvent('ox_doorlock:setState', -1, id, state, source, nil)
end

lib.callback.register('ox_doorlock:getDoors', function()
    return doors
end)

lib.callback.register('ox_doorlock:getSounds', function()
    return {
        'door_bolt',
        'door-bolt-4',
        'door-bolt-2',
        'door-bolt-3',
        'door-bolt-1',
    }
end)

---@return boolean allowed
local function canAccess(source, door, passcode)
    if authorised(source) then return true end

    if door.characters then
        local cid = framework.getCharacterId(source)

        if cid then
            for i = 1, #door.characters do
                if door.characters[i] == cid then return true end
            end
        end
    end

    if door.groups and framework.hasGroup(source, door.groups) then
        return true
    end

    if door.items then
        if framework.hasItem(source, door.items) then return true end
    end

    if door.passcode then
        return passcode ~= nil and tostring(passcode) == tostring(door.passcode)
    end

    return not (door.characters or door.groups or door.items)
end

RegisterNetEvent('ox_doorlock:setState', function(id, state, isPick, passcode)
    local source = source
    local door = doors[id]

    if not door then return end

    state = state == 0 and 0 or 1

    if isPick then
        if not door.lockpick then return end
    elseif not canAccess(source, door, passcode) then
        return framework.notify(source, 'Kamu tidak punya akses')
    end

    if doorState[id] == state then return end

    doorState[id] = state
    door.state = state

    MySQL.update.await('UPDATE ox_doorlock SET state = ? WHERE id = ?', { state, id })

    broadcast(id, state, source)
end)

RegisterNetEvent('ox_doorlock:breakLockpick', function()
    local source = source

    local ok, item = framework.hasItem(source, Config.LockpickItems)

    if ok then framework.removeItem(source, item) end
end)

RegisterNetEvent('ox_doorlock:editDoorlock', function(id, data)
    local source = source

    if not authorised(source) then return framework.notify(source, 'Bukan admin') end

    if not data then
        if not id then return end

        MySQL.update.await('DELETE FROM ox_doorlock WHERE id = ?', { id })

        doors[id] = nil
        doorState[id] = nil

        return TriggerClientEvent('ox_doorlock:editDoorlock', -1, id, false)
    end

    if type(data) ~= 'table' then return end

    data.id = nil
    data.state = data.state == 1 and 1 or 0
    data.maxDistance = data.maxDistance or 1.5

    if data.items and not next(data.items) then data.items = nil end
    if data.groups and not next(data.groups) then data.groups = nil end
    if data.characters and not next(data.characters) then data.characters = nil end
    if data.passcode == '' then data.passcode = nil end

    local encoded = json.encode(data)

    if id then
        MySQL.update.await('UPDATE ox_doorlock SET name = ?, data = ?, state = ? WHERE id = ?', {
            data.name or 'door',
            encoded,
            data.state,
            id,
        })

        local door = doors[id]

        if door then
            local keepId = door.id

            for key in pairs(door) do door[key] = nil end

            local fresh = json.decode(encoded) or {}

            for key, value in pairs(fresh) do door[key] = value end

            door.id = keepId
            door.coords = vector3(door.coords.x, door.coords.y, door.coords.z)
            door.state = data.state
        end

        doorState[id] = data.state

        return TriggerClientEvent('ox_doorlock:editDoorlock', -1, id, door)
    end

    local newId = MySQL.insert.await('INSERT INTO ox_doorlock (name, data, state) VALUES (?, ?, ?)', {
        data.name or 'door',
        encoded,
        data.state,
    })

    if not newId then return end

    local row = MySQL.single.await('SELECT id, name, data, state FROM ox_doorlock WHERE id = ?', { newId })

    if not row then return end

    local door = buildRow(row)

    doors[door.id] = door
    doorState[door.id] = door.state

    TriggerClientEvent('ox_doorlock:editDoorlock', -1, door.id, door)
end)

RegisterCommand('doorlock', function(source, args)
    local id = tonumber(args[1])

    if source == 0 then
        if id and doors[id] then
            local door = doors[id]
            local state = doorState[id] == 1 and 0 or 1

            doorState[id] = state
            door.state = state

            MySQL.update.await('UPDATE ox_doorlock SET state = ? WHERE id = ?', { state, id })
            broadcast(id, state)
        end

        return
    end

    if not authorised(source) then return framework.notify(source, 'Bukan admin') end

    TriggerClientEvent('ox_doorlock:triggeredCommand', source, id ~= nil)
end, false)

lib.print.info('ox_doorlock server siap')
