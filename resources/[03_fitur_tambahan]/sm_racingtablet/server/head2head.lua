---@type table<number, table>
local races = {}
---@type table<number, number>
local ofSource = {}

local seq = 0

---@param id number
---@return table?
local function raceOf(id)
    return races[id]
end

---@param race table
---@param event string
---@param ... any
local function send(race, event, ...)
    for _, racer in pairs(race.racers) do
        TriggerClientEvent(event, racer.source, ...)
    end
end

---@param race table
---@param citizenid string
---@param time number
local function finish(race, citizenid, time)
    local racer = race.racers[citizenid]
    if not racer or racer.time then return end

    racer.time = time

    local done = 0

    for _, other in pairs(race.racers) do
        if other.time then done = done + 1 end
    end

    if done < 2 then return end

    race.finished = true
    races[race.id] = nil

    local winner

    for _, other in pairs(race.racers) do
        if not winner or other.time < winner.time then winner = other end
    end

    if not winner then return end

    if race.pot > 0 then addMoney(winner.source, 'bank', race.pot) end

    for _, other in pairs(race.racers) do
        ofSource[other.source] = nil
        clearBucket(other.source)

        if other == winner then
            TriggerClientEvent('sm_racingtablet:h2h:client:notifyFinish', other.source, ('Kamu menang. Hadiah $%d'):format(race.pot))
        else
            TriggerClientEvent('sm_racingtablet:h2h:client:notifyFinish', other.source, ('Kamu kalah dengan selisih %s'):format(formatClock(other.time - winner.time)))
        end
    end
end

RegisterNetEvent('sm_racingtablet:h2h:server:setupRace', function(_, racerName, startCoords, amount, _, finishCoords)
    local src = source
    local citizenid = getCitizenId(src)
    if not citizenid then return end
    if ofSource[src] then return notify(src, 'Sudah berada di balapan.', 'error') end
    if not finishCoords then return notify(src, 'Pasang waypoint dulu.', 'error') end

    amount = math.floor(tonumber(amount) or 0)

    if amount > 0 and not removeMoney(src, 'bank', amount) then
        return notify(src, 'Uang tidak cukup.', 'error')
    end

    seq = seq + 1

    local race = {
        id = seq,
        amount = amount,
        pot = amount,
        startCoords = startCoords,
        finishCoords = finishCoords,
        started = false,
        racers = {},
    }

    race.racers[citizenid] = { source = src, name = racerName, citizenid = citizenid }

    races[race.id] = race
    ofSource[src] = race.id

    TriggerClientEvent('sm_racingtablet:h2h:client:setupRace', src, {
        raceId = race.id,
        startCoords = startCoords,
        finishCoords = finishCoords,
        amount = amount,
    })
end)

RegisterNetEvent('sm_racingtablet:h2h:server:invitePlayer', function(target, raceId, amount, inviterName)
    local race = raceOf(tonumber(raceId))
    if not race then return end

    target = tonumber(target)
    if not target or ofSource[target] then return end

    TriggerClientEvent('sm_racingtablet:h2h:client:invite', target, race.id, amount, inviterName)
end)

RegisterNetEvent('sm_racingtablet:h2h:server:joinRace', function(_, racerName, raceId)
    local src = source
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local race = raceOf(tonumber(raceId))
    if not race or race.started then return notify(src, 'Balapan tidak tersedia.', 'error') end
    if ofSource[src] then return notify(src, 'Sudah berada di balapan.', 'error') end
    if race.amount > 0 and not removeMoney(src, 'bank', race.amount) then
        return notify(src, 'Uang tidak cukup.', 'error')
    end

    race.pot = race.pot + race.amount
    race.racers[citizenid] = { source = src, name = racerName, citizenid = citizenid }
    ofSource[src] = race.id

    TriggerClientEvent('sm_racingtablet:h2h:client:joinRace', src)

    if #(function() local t = {} for _ in pairs(race.racers) do t[#t + 1] = 1 end return t end)() >= 2 then
        send(race, 'sm_racingtablet:h2h:client:checkDistance', race.id, race.amount)

        for _, racer in pairs(race.racers) do
            setBucket(racer.source, race.id)
            TriggerClientEvent('sm_racingtablet:h2h:client:raceCountdown', racer.source, {
                raceId = race.id,
                finishCoords = race.finishCoords,
                racers = race.racers,
            })
        end
    end
end)

RegisterNetEvent('sm_racingtablet:h2h:server:raceStarted', function(raceId)
    local race = raceOf(tonumber(raceId))
    if not race then return end

    race.started = true
end)

RegisterNetEvent('sm_racingtablet:h2h:server:finishRacer', function(raceId, citizenid, time)
    local race = raceOf(tonumber(raceId))
    if not race or race.finished then return end

    finish(race, citizenid, math.floor(tonumber(time) or 0))
end)

RegisterNetEvent('sm_racingtablet:h2h:server:leaveRace', function(raceId)
    local src = source
    local citizenid = getCitizenId(src)
    local id = ofSource[src]

    ofSource[src] = nil
    clearBucket(src)

    local race = (id and raceOf(id)) or raceOf(tonumber(raceId))
    if not race or race.started then return end

    race.racers[citizenid] = nil

    if race.amount > 0 then addMoney(src, 'bank', race.amount) end

    if next(race.racers) == nil then
        races[race.id] = nil
    else
        race.pot = race.amount
    end
end)