--[[
    sm_domino :: server
    Wasit penuh: meja, kursi, dek, giliran, validasi langkah, bot, timer ronde.
    Aturan main dipakai ulang dari modules/engine.lua supaya identik dengan klien.
]]

local config = localmodule 'config'

local engine
do
    local ok, mod = pcall(localmodule, 'modules.engine')
    engine = ok and mod or nil
    if not engine then engine = localmodule 'modules/engine' end
end

local REGISTRY_KEY = 'smdomino:tables'

local MAX_SEATS = 4
local HAND_SIZE = 7
local TURN_SECONDS = config.turnSeconds or 30
local AUTO_PASS_MS = config.autoPassMs or 1500
local RESULT_TIMEOUT_MS = config.resultTimeoutMs or 60000
local DEFAULT_TARGET = config.defaultTarget or 200
local DEFAULT_MODE = config.mode
local TARGETS = config.targets or { 100, 150, 200, 250, 500 }

local MAX_TABLES = config.maxTables or 30
local SPACING = config.minTableSpacing or 3.2
local ACTION_DISTANCE = config.actionDistance or 3.5
local COOLDOWN = config.actionCooldown or 250
local ADMIN_ACE = config.adminAce or 'admin'
local ITEM = config.item
local MODELS = config.models or {}
local TIPS = config.tips

local tables = {}
local bySrc = {}
local byCitizen = {}
local lastAction = {}
local nextId = 0
local animSeq = 0

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function isAdmin(src)
    return IsPlayerAceAllowed(src, ADMIN_ACE)
end

local function citizenOf(src)
    local player = qb_ecore:GetPlayer(src)
    return player and player.PlayerData.citizenid or nil, player
end

local function fullName(player)
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname or '', info.lastname or '')
end

local function tableCount()
    local total = 0
    for _ in pairs(tables) do total = total + 1 end
    return total
end

local function seatedCount(t)
    local total = 0
    for seat = 1, MAX_SEATS do
        if t.seats[seat] then total = total + 1 end
    end
    return total
end

local function publishRegistry()
    local out = {}

    for id, t in pairs(tables) do
        out[id] = { id = id, x = t.x, y = t.y, z = t.z, h = t.h, owner = t.owner }
    end

    GlobalState[REGISTRY_KEY] = out
end

local function audience(t)
    local list = {}

    for seat = 1, MAX_SEATS do
        local occ = t.seats[seat]
        if occ and occ.src then list[#list + 1] = occ.src end
    end

    for src in pairs(t.watchers) do
        if not bySrc[src] then list[#list + 1] = src end
    end

    return list
end

local function handOf(t, seat)
    if not t.hand or not t.hand.hands then return {} end
    return t.hand.hands[seat] or {}
end

local function modeFor(count, ffa)
    if engine.getMode then
        local ok, mode = pcall(engine.getMode, count, ffa)
        if ok and mode then return mode end
    end
    if count == 2 then return 'duel' end
    if count == 3 then return 'ffa' end
    return ffa and 'ffa4' or 'pairs'
end

local function buildSnap(t)
    local snap = t.snap

    snap.id = t.id
    snap.host = t.hostSeat or 0
    snap.phase = t.phase
    snap.seq = (snap.seq or 0) + 1
    snap.tips = TIPS

    local seats = {}
    for seat = 1, MAX_SEATS do
        local occ = t.seats[seat]
        if occ then
            seats[seat] = { count = #handOf(t, seat), name = occ.name, bot = occ.bot or nil, model = occ.model }
        end
    end
    snap.seats = seats

    if t.hand then
        snap.board = t.hand.board or {}
        snap.turn = t.hand.turn or 0
        snap.stock = #(t.hand.stock or {})

        local pile = {}
        for i, tile in ipairs(t.hand.stock or {}) do
            pile[i] = { i = i, t = tile.id }
        end
        snap.pile = pile
    else
        snap.board = {}
        snap.turn = 0
        snap.stock = 0
        snap.pile = {}
    end

    return snap
end

local function push(t, handFor)
    local snap = buildSnap(t)
    local targets = audience(t)

    for i = 1, #targets do
        TriggerClientEvent('sm_domino:client:state', targets[i], snap)
    end

    if handFor and bySrc[handFor] then
        local seat = bySrc[handFor].seat
        local occ = t.seats[seat]
        if occ and not occ.bot then
            TriggerClientEvent('sm_domino:client:hand', handFor, t.id, handOf(t, seat))
        end
    end

    return snap
end

local function markLast(t, seat, kind)
    animSeq = animSeq + 1
    t.snap.last = { seq = animSeq, seat = seat, kind = kind }
end

local function nextOccupied(t, from)
    for step = 1, MAX_SEATS do
        local seat = ((from + step - 1) % MAX_SEATS) + 1
        if t.seats[seat] then return seat end
    end
    return nil
end

local function advance(t, from)
    local seat = nextOccupied(t, from)
    if not seat then return end
    t.hand.turn = seat
    t.turnStarted = os.time()
end

local function dealHands(t)
    for seat = 1, MAX_SEATS do
        local occ = t.seats[seat]
        if occ and not occ.bot then
            TriggerClientEvent('sm_domino:client:hand', occ.src, t.id, handOf(t, seat))
        end
    end
end

local function finishHand(t, winnerSeat)
    if not t.hand or t.phase == 'result' then return end

    local result = engine.score(t.match, t.hand, winnerSeat)
    result.reveal = {}
    for seat, tiles in pairs(t.hand.hands) do
        result.reveal[seat] = tiles
    end

    t.phase = 'result'
    t.snap.result = result

    dealHands(t)
    push(t)

    local token = (t.resultToken or 0) + 1
    t.resultToken = token

    SetTimeout(RESULT_TIMEOUT_MS, function()
        if t.resultToken ~= token or not tables[t.id] then return end

        if result.over then
            for seat = 1, MAX_SEATS do
                local occ = t.seats[seat]
                if occ and not occ.bot then
                    TriggerClientEvent('sm_domino:client:kicked', occ.src, t.id, 'matchOver')
                end
            end
            t.phase = 'lobby'
            t.hand = nil
            t.match = nil
            t.snap.result = nil
            return push(t)
        end

        startHand(t)
    end)
end

local function startHand(t)
    if t.phase == 'play' then return end

    local seats = {}
    for seat = 1, MAX_SEATS do
        if t.seats[seat] then seats[#seats + 1] = seat end
    end

    if #seats < 2 then
        t.phase = 'lobby'
        return push(t)
    end

    if not t.match or (t.match.over) then
        t.match = engine.newMatch(seats, t.mode or modeFor(#seats, t.ffa), t.target)
    end

    t.phase = 'deal'
    t.snap.result = nil
    markLast(t, 0, 'shuffle')
    push(t)

    SetTimeout(700, function()
        if not tables[t.id] or t.phase ~= 'deal' then return end

        t.hand = engine.newHand(t.match)
        t.phase = 'play'
        t.turnStarted = os.time()

        dealHands(t)
        push(t)
        runBot(t)
    end)
end

function runBot(t)
    if not t.hand or t.phase ~= 'play' then return end

    local seat = t.hand.turn
    local occ = t.seats[seat]
    if not occ or not occ.bot then return end

    local kind, tileId, side = engine.botMove(t.hand, seat)

    SetTimeout(AUTO_PASS_MS, function()
        if not tables[t.id] or t.phase ~= 'play' or t.hand.turn ~= seat then return end

        if kind == 'draw' then
            local tile = engine.draw(t.hand, seat)
            if tile then
                t.snap.takes = { { slot = #handOf(t, seat), seat = seat } }
                markLast(t, seat, 'draw')
                push(t, occ.src)
            end
            return runBot(t)
        end

        if kind == 'pass' then
            t.snap.takes = {}
            markLast(t, seat, 'pass')
            advance(t, seat)
            push(t)
            return runBot(t)
        end

        local res = engine.play(t.hand, seat, tileId, side)
        t.snap.takes = {}

        if not res then
            markLast(t, seat, 'pass')
            advance(t, seat)
            push(t)
            return runBot(t)
        end

        markLast(t, seat, 'play')

        if res.domino or #handOf(t, seat) == 0 then
            return finishHand(t, seat)
        end

        advance(t, seat)
        push(t)
        runBot(t)
    end)
end

local function newTable(src, player, coords, heading)
    nextId = nextId + 1
    local id = nextId

    local t = {
        id = id,
        x = coords.x, y = coords.y, z = coords.z,
        h = heading % 360.0,
        owner = player.PlayerData.citizenid,
        ownerSrc = src,
        seats = {},
        watchers = {},
        phase = 'unpack',
        hostSeat = 1,
        mode = DEFAULT_MODE,
        target = DEFAULT_TARGET,
        snap = { id = id, seq = 0, board = {}, pile = {}, takes = {}, seats = {}, stock = 0, turn = 0, host = 1, phase = 'unpack' },
    }

    tables[id] = t

    t.seats[1] = { src = src, cid = t.owner, name = fullName(player) }
    bySrc[src] = { id = id, seat = 1 }
    byCitizen[t.owner] = { id = id, seat = 1 }

    publishRegistry()
    push(t, src)

    SetTimeout(1200, function()
        if not tables[id] then return end
        t.phase = 'lobby'
        push(t)
    end)

    return id
end

lib.callback.register('sm_domino:place', function(src, slot, coords, heading)
    local cid, player = citizenOf(src)
    if not player then return false, 'db' end
    if bySrc[src] then return false, 'seated' end
    if type(coords) ~= 'table' then return false, 'space' end

    local pos = vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
    if #(GetEntityCoords(GetPlayerPed(src)) - pos) > ACTION_DISTANCE + 2.0 then return false, 'far' end
    if tableCount() >= MAX_TABLES then return false, 'limit' end

    for _, other in pairs(tables) do
        if #(vector3(other.x, other.y, other.z) - pos) < SPACING then return false, 'space' end
    end

    if ITEM then
        if (ox_inventory:GetItemCount(src, ITEM) or 0) < 1 then return false, 'item' end
        if not ox_inventory:RemoveItem(src, ITEM, 1, nil, slot) then return false, 'item' end
    end

    local id = newTable(src, player, pos, tonumber(heading) or 0.0)

    return true, id
end)

lib.callback.register('sm_domino:sit', function(src, id, seat)
    local cid, player = citizenOf(src)
    if not player then return false, 'db' end

    local t = tables[tonumber(id) or 0]
    if not t then return false, 'gone' end
    if bySrc[src] then return false, 'seated' end
    if not seat or seat < 1 or seat > MAX_SEATS then return false, 'taken' end
    if t.seats[seat] then return false, 'taken' end
    if t.phase ~= 'lobby' and t.phase ~= 'unpack' then return false, 'phase' end
    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(t.x, t.y, t.z)) > ACTION_DISTANCE + 1.0 then
        return false, 'far'
    end

    t.seats[seat] = { src = src, cid = cid, name = fullName(player) }
    bySrc[src] = { id = t.id, seat = seat }
    byCitizen[cid] = { id = t.id, seat = seat }

    push(t)

    return true
end)

lib.callback.register('sm_domino:stand', function(src)
    local seated = bySrc[src]
    if not seated then return true end

    bySrc[src] = nil

    local t = tables[seated.id]
    if not t then return true end

    local occ = t.seats[seated.seat]
    if occ then byCitizen[occ.cid] = nil end
    t.seats[seated.seat] = nil

    if t.hand and t.phase == 'play' and t.hand.turn == seated.seat then
        advance(t, seated.seat)
        push(t)
        runBot(t)
    else
        push(t)
    end

    if seatedCount(t) == 0 then
        tables[t.id] = nil
        publishRegistry()
    end

    return true
end)

lib.callback.register('sm_domino:pack', function(src, id)
    local cid, player = citizenOf(src)
    if not player then return false, 'db' end

    local t = tables[tonumber(id) or 0]
    if not t then return false, 'gone' end
    if t.owner ~= cid and not isAdmin(src) then return false, 'owner' end

    for seat = 1, MAX_SEATS do
        local occ = t.seats[seat]
        if occ and occ.src then
            bySrc[occ.src] = nil
            TriggerClientEvent('sm_domino:client:kicked', occ.src, t.id, 'packed')
        end
    end

    tables[t.id] = nil
    publishRegistry()

    return true
end)

lib.callback.register('sm_domino:watch', function(src, id)
    local t = tables[tonumber(id) or 0]
    if not t then return false end

    if not bySrc[src] then t.watchers[src] = true end

    return true, buildSnap(t)
end)

lib.callback.register('sm_domino:unwatch', function(src, id)
    local t = tables[tonumber(id) or 0]
    if t then t.watchers[src] = nil end
    return true
end)

lib.callback.register('sm_domino:pick', function(src, slot)
    local seated = bySrc[src]
    if not seated then return false end

    local t = tables[seated.id]
    if not t or not t.hand then return false end

    local tiles = t.hand.hands[seated.seat]
    return true, tiles and tiles[slot] or nil
end)

lib.callback.register('sm_domino:act', function(src, action, a, b)
    local seated = bySrc[src]
    if not seated then return false, 'seated' end

    local t = tables[seated.id]
    if not t or not t.hand then return false, 'phase' end
    if t.phase ~= 'play' then return false, 'phase' end
    if t.hand.turn ~= seated.seat then return false, 'turn' end

    local stamp = GetGameTimer()
    if lastAction[src] and stamp - lastAction[src] < COOLDOWN then return false, 'turn' end
    lastAction[src] = stamp

    if action == 'draw' then
        if #t.hand.stock == 0 then return false, 'deck' end
        if #engine.moves(t.hand, seated.seat) > 0 then return false, 'draw' end

        local tile = engine.draw(t.hand, seated.seat)
        if not tile then return false, 'deck' end

        t.snap.takes = { { slot = a or #handOf(t, seated.seat), seat = seated.seat } }
        markLast(t, seated.seat, 'draw')
        push(t, src)

        return true
    end

    if action == 'pass' then
        if not engine.canPass(t.hand, seated.seat) then return false, 'pass' end

        t.snap.takes = {}
        markLast(t, seated.seat, 'pass')
        advance(t, seated.seat)
        push(t)
        runBot(t)

        return true
    end

    if action == 'play' then
        local res = engine.play(t.hand, seated.seat, a, b)
        if not res then return false, 'move' end

        t.snap.takes = {}
        markLast(t, seated.seat, 'play')

        if res.domino or #handOf(t, seated.seat) == 0 then
            finishHand(t, seated.seat)
            return true
        end

        advance(t, seated.seat)
        push(t)
        runBot(t)

        return true
    end

    return false, 'move'
end)

lib.callback.register('sm_domino:host', function(src, action, value)
    local seated = bySrc[src]
    if not seated then return false, 'seated' end

    local t = tables[seated.id]
    if not t then return false, 'gone' end

    local admin = isAdmin(src)
    if t.hostSeat ~= seated.seat and not admin then return false, 'host' end

    if action == 'target' then
        local want = tonumber(value)
        local found = false
        for i = 1, #TARGETS do
            if TARGETS[i] == want then found = true break end
        end
        if not found then return false, 'move' end
        t.target = want
        push(t)
        return true
    end

    if action == 'bot' or action == 'addBot' then
        if t.phase == 'play' then return false, 'phase' end
        if seatedCount(t) >= MAX_SEATS then return false, 'full' end

        local seat = tonumber(value)
        if not seat or seat < 1 or seat > MAX_SEATS or t.seats[seat] then return false, 'full' end

        t.seats[seat] = {
            bot = true,
            name = ('Bot %d'):format(seat),
            model = MODELS[#MODELS > 0 and ((seat - 1) % #MODELS) + 1 or nil],
        }

        push(t)
        return true
    end

    if action == 'kick' then
        if t.phase == 'play' then return false, 'phase' end

        local seat = tonumber(value)
        local occ = seat and t.seats[seat]
        if not occ then return false, 'occupied' end

        t.seats[seat] = nil
        if occ.src then
            bySrc[occ.src] = nil
            TriggerClientEvent('sm_domino:client:kicked', occ.src, t.id, 'removed')
        end

        push(t)
        return true
    end

    if action == 'start' or action == 'deal' then
        if seatedCount(t) < 2 then return false, 'players' end
        if t.phase == 'play' or t.phase == 'deal' then return false, 'phase' end
        startHand(t)
        return true
    end

    if action == 'close' or action == 'pack' then
        for seat = 1, MAX_SEATS do
            local occ = t.seats[seat]
            if occ and occ.src then
                bySrc[occ.src] = nil
                TriggerClientEvent('sm_domino:client:kicked', occ.src, t.id, 'packed')
            end
        end
        tables[t.id] = nil
        publishRegistry()
        return true
    end

    if action == 'reset' then
        t.hand = nil
        t.match = nil
        t.snap.result = nil
        t.phase = 'lobby'
        push(t)
        return true
    end

    return false, 'move'
end)

lib.callback.register('sm_domino:ready', function(src)
    local seated = bySrc[src]
    if not seated then return false end
    local t = tables[seated.id]
    return t ~= nil and t.phase == 'result'
end)

CreateThread(function()
    while true do
        Wait(1000)

        local stamp = os.time()

        for _, t in pairs(tables) do
            if t.phase == 'play' and t.hand and t.turnStarted and stamp - t.turnStarted > TURN_SECONDS then
                local seat = t.hand.turn
                local occ = t.seats[seat]

                if occ and not occ.bot then
                    t.snap.takes = {}
                    markLast(t, seat, 'pass')
                    advance(t, seat)
                    push(t)
                    runBot(t)
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local seated = bySrc[src]
    if not seated then return end

    bySrc[src] = nil

    local t = tables[seated.id]
    if not t then return end

    t.seats[seated.seat] = nil

    if seatedCount(t) == 0 then
        tables[t.id] = nil
        publishRegistry()
        return
    end

    if t.hostSeat == seated.seat then
        t.hostSeat = nextOccupied(t, seated.seat) or 0
    end

    if t.hand and t.phase == 'play' and t.hand.turn == seated.seat then
        advance(t, seated.seat)
        runBot(t)
    end

    push(t)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    tables = {}
    GlobalState[REGISTRY_KEY] = {}
end)

print('^2[sm_domino] server siap^7')