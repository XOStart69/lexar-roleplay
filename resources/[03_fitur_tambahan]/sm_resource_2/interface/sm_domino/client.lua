local config = localmodule 'config'
local interact = exports.rhd_interact
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local joaat = joaat
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local CreateObjectNoOffset = CreateObjectNoOffset
local SetEntityRotation = SetEntityRotation
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityCollision = SetEntityCollision
local HasModelLoaded = HasModelLoaded
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local DisableControlAction = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsDisabledControlJustReleased = IsDisabledControlJustReleased
local IsDisabledControlPressed = IsDisabledControlPressed
local GetControlNormal = GetControlNormal
local GetWorldCoordFromScreenCoord = GetWorldCoordFromScreenCoord
local SetMouseCursorThisFrame = SetMouseCursorThisFrame
local SetMouseCursorSprite = SetMouseCursorSprite
local SetEntityDrawOutline = SetEntityDrawOutline
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local GetFrameTime = GetFrameTime
local rad, sin, cos, floor, pi, abs = math.rad, math.sin, math.cos, math.floor, math.pi, math.abs
local random = math.random
local pairs = pairs
local tointeger = math.tointeger

local STATE_KEY = 'smdomino:tables'
local TABLE_MODEL = joaat(config.tableModel)
local CHAIR_MODEL = joaat(config.chairModel)
local CASE_MODEL = joaat(config.caseModel)
local LID_MODEL = joaat(config.caseLidModel)
local HANDS = config.hands
local PICK, PLACE, UNPACK = HANDS.pick, HANDS.place, HANDS.unpack
local RIGHT_HAND, LEFT_HAND = 57005, 18905
local IK_RIGHT, IK_LEFT = 4, 3
local CASE_REST_Y = -0.43
local TILE_FMT = config.tileModel
local PELVIS_BONE = 11816
local SIT_SYNC_FLAGS = 1 + 512 + 1024 + 2048
local SHUFFLE = config.shuffleFx
local SHUFFLE_HALF_W, SHUFFLE_HALF_D = SHUFFLE.width * 0.5, SHUFFLE.depth * 0.5
local BOARD_TXD = 'sm_domino_board'
local SURFACE = config.surfaceHeight
local CHAIR_DISTANCE = config.chairDistance
local CHAIR_OFFSET = config.chairHeadingOffset
local SEAT_HEIGHT = config.seatHeight
local HAND_DISTANCE = config.handDistance
local HAND_SPACING = config.handSpacing
local HAND_HEIGHT = config.handHeight
local HAND_TILT = config.handTilt
local YAW_OFFSET = config.tileYawOffset
local DROP_RADIUS = config.dropRadius
local OPEN_DROP_AREA = config.openDropArea
local PICK_RADIUS_SQ = config.pickRadius * config.pickRadius
local STREAM_DISTANCE = config.streamDistance
local INTERACT_DISTANCE = config.interactDistance
local PLACE_DISTANCE = config.placeDistance
local SIT = config.sit
local ANIMS = config.anims
local CAMERAS = config.cameras
local BOT_MODELS = config.bots.models
local INFO_ID = 'sm_domino:hint'
local PLACE_HINT = '[kbd]←[/kbd] [kbd]↑[/kbd] [kbd]↓[/kbd] [kbd]→[/kbd] Move\n[kbd]SCROLL[/kbd] Rotate\n[kbd]ENTER[/kbd] Place  [kbd]BACKSPACE[/kbd] Cancel'

local CONTROL_CLICK, CONTROL_X, CONTROL_V, CONTROL_R = 24, 73, 0, 45
local CONTROL_BACKSPACE = 177
local CONTROL_ENTER, CONTROL_BACK, CONTROL_ESC = 191, 194, 200
local CONTROL_WHEEL_UP, CONTROL_WHEEL_DOWN = 15, 14
local CONTROL_UP, CONTROL_DOWN, CONTROL_LEFT, CONTROL_RIGHT = 172, 173, 174, 175
local PLACE_CONTROLS = { 1, 2, 245, 249 }
local MOVE_SPEED = 1.5
local PLACE_REACH = config.placeDistance - 1.0
local BLOCKED_CONTROLS = { 0, 1, 2, 14, 15, 16, 17, 24, 25, 30, 31, 32, 33, 34, 35, 37, 44, 45, 47, 73, 140, 141, 142, 143, 177, 194, 199, 200, 257, 263, 264 }
local HAND_SIZE = 7

local REASONS = {
    item = 'You no longer have the domino table.',
    bucket = 'You cannot set up a table here.',
    vehicle = 'Get out of the vehicle first.',
    far = 'You are too far away.',
    limit = 'There are too many domino tables in the city.',
    owned = 'You already have a domino table set up. Pack it up first.',
    space = 'Too close to another domino table.',
    db = 'Could not save the table. The item was returned.',
    gone = 'This table no longer exists.',
    owner = 'Only the person who set up this table can pack it up.',
    occupied = 'Everyone must stand up before packing the table.',
    full = 'You have no room for the table.',
    seated = 'You are already sitting at a table.',
    taken = 'That seat is taken.',
    host = 'Only the host can do that.',
    players = 'At least two players or bots are needed.',
    packed = 'The table was packed up.',
    removed = 'The table was removed by an administrator.',
}

---@type table<number, table>
local tables = {}
---@type { id: number, seat: number, view: string, focused: boolean, pose?: { root: vector3, heading: number } }?
local seated
local cam
local myHand, myHandId = {}, 0
local frameMounted, frameReady = false, false
local placing = false
local animSeq = 0
local hovered
---@type { obj: number, tile: table }?
local drag

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = 'Dominos', description = description, type = kind or 'error' })
end

---@param reason? string
---@param fallback string
local function notifyFail(reason, fallback)
    notify(REASONS[reason] or fallback)
end

---@param hash number
---@return boolean
local function loadModel(hash)
    if HasModelLoaded(hash) then return true end
    return pcall(lib.requestModel, hash, 5000)
end

---@param dict string
---@return boolean
local function loadDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    return pcall(lib.requestAnimDict, dict, 5000)
end

---@param lo number
---@param hi number
---@return number
local function tileHash(lo, hi)
    return joaat(TILE_FMT:format(lo, hi))
end

---@param entity number?
local function deleteObject(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param list table
local function deleteAll(list)
    for key, entity in pairs(list) do
        deleteObject(entity)
        list[key] = nil
    end
end

---@param entry table
---@param hash number
---@param lx number
---@param ly number
---@param lz number
---@param pitch number
---@param roll number
---@param yaw number
---@return number?
local function spawnTile(entry, hash, lx, ly, lz, pitch, roll, yaw)
    if not loadModel(hash) then return end
    local base = entry.entity
    if not base or not DoesEntityExist(base) then return end

    local pos = GetOffsetFromEntityInWorldCoords(base, lx, ly, lz)
    local obj = CreateObjectNoOffset(hash, pos.x, pos.y, pos.z, false, false, false)
    SetEntityRotation(obj, pitch, roll, entry.heading + yaw, 2, false)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, false, false)
    return obj
end

---@param seat number
---@param index number
---@return number x
---@return number y
local function rackPosition(seat, index)
    local a = rad((seat - 1) * 90.0)
    local ox = ((index - 1) % 7 - 3) * HAND_SPACING
    local oy = HAND_DISTANCE + floor((index - 1) / 7) * 0.032
    return ox * cos(a) + oy * sin(a), ox * sin(a) - oy * cos(a)
end

---@param index number
---@return number x
---@return number y
local function stockPosition(index)
    return 0.423 + ((index - 1) % 2) * 0.055, 0.18 + floor((index - 1) / 2) * 0.027
end

---@param seat number
---@param ox number
---@param oy number
---@param oz number
---@return number x
---@return number y
---@return number z
local function seatLocal(seat, ox, oy, oz)
    local a = rad((seat - 1) * 90.0)
    local c, s = cos(a), sin(a)
    return ox * c - oy * s, ox * s + oy * c, oz
end

---@param t number
---@return number
local function smooth(t)
    if t <= 0.0 then return 0.0 end
    if t >= 1.0 then return 1.0 end
    return t * t * (3.0 - 2.0 * t)
end

---@param entry table
---@param obj number
---@param lx number
---@param ly number
---@param lz number
---@param pitch number
---@param roll number
---@param yaw number
local function placeLocal(entry, obj, lx, ly, lz, pitch, roll, yaw)
    local pos = GetOffsetFromEntityInWorldCoords(entry.entity, lx, ly, lz)
    SetEntityCoordsNoOffset(obj, pos.x, pos.y, pos.z, false, false, false)
    SetEntityRotation(obj, pitch, roll, entry.heading + yaw, 2, false)
end

---@param entry table
---@param seat number
---@return number? ped
---@return boolean controlled
local function pedForSeat(entry, seat)
    local bot = entry.bots[seat]
    if bot and DoesEntityExist(bot.ped) then return bot.ped, true end
    local info = entry.snap and entry.snap.seats[seat]
    if not info or not info.src or info.src < 1 then return nil, false end
    local player = GetPlayerFromServerId(info.src)
    if player == -1 then return nil, false end
    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return nil, false end
    return ped, ped == cache.ped
end

---@param ped number
---@param spec table
---@param phase number
local function holdClip(ped, spec, phase)
    if not IsEntityPlayingAnim(ped, spec.dict, spec.clip, 3) then
        TaskPlayAnim(ped, spec.dict, spec.clip, 8.0, -8.0, -1, 49, phase, false, false, false)
    end
    SetEntityAnimCurrentTime(ped, spec.dict, spec.clip, phase)
    SetEntityAnimSpeed(ped, spec.dict, spec.clip, 0.0)
end

---@param ped number
---@param spec table
local function stopClip(ped, spec)
    if DoesEntityExist(ped) and IsEntityPlayingAnim(ped, spec.dict, spec.clip, 3) then
        StopEntityAnim(ped, spec.clip, spec.dict, 3.0)
    end
end

---@param ped number
---@param part number
---@param bone number
---@param target vector3
---@param blend number
local function reach(ped, part, bone, target, blend)
    if blend <= 0.0 then return end
    local b = GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0)
    SetIkTarget(ped, part, 0, -1, b.x + (target.x - b.x) * blend, b.y + (target.y - b.y) * blend, b.z + (target.z - b.z) * blend, 17, 60, 120)
end

---@param obj number
---@param ped number
---@param spec table
local function attachToHand(obj, ped, spec)
    local o, r = spec.offset, spec.rotation
    FreezeEntityPosition(obj, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, RIGHT_HAND), o.x, o.y, o.z, r.x, r.y, r.z, false, false, false, false, 2, true)
end

---@param entry table
---@param obj number
---@param from { x: number, y: number, r: number }
---@param seat number
local function flyToRack(entry, obj, from, seat)
    Wait(250)
    local toX, toY = rackPosition(seat, 4)
    local fromZ, toZ = SURFACE + 0.0101, HAND_HEIGHT
    local toYaw = (seat - 1) * 90.0
    local turn = (toYaw - from.r + 180.0) % 360.0 - 180.0
    local started = GetGameTimer()

    while entry.entity and DoesEntityExist(obj) do
        local t = (GetGameTimer() - started) / 500.0
        local e = smooth(t)
        placeLocal(entry, obj, from.x + (toX - from.x) * e, from.y + (toY - from.y) * e, fromZ + (toZ - fromZ) * e + sin(pi * e) * 0.06, HAND_TILT * e, 180.0 * (1.0 - e), from.r + turn * e)
        if t >= 1.0 then break end
        Wait(0)
    end
    deleteObject(obj)
end

---@param entry table
---@param seat number
---@param obj number
---@param from { x: number, y: number, r: number }
local function handPick(entry, seat, obj, from)
    local ped, controlled = pedForSeat(entry, seat)
    if not ped or not loadDict(PICK.dict) then
        return flyToRack(entry, obj, from, seat)
    end

    local started = GetGameTimer()
    local attached = false
    while entry.entity and DoesEntityExist(obj) do
        local p = (GetGameTimer() - started) / PICK.duration
        if p >= PICK.release then break end
        if controlled then holdClip(ped, PICK, p) end
        if p < PICK.grasp then
            reach(ped, IK_RIGHT, RIGHT_HAND, GetEntityCoords(obj), smooth(p / PICK.grasp))
        elseif not attached then
            attached = true
            attachToHand(obj, ped, PICK)
        end
        Wait(0)
    end

    if controlled then stopClip(ped, PICK) end
    deleteObject(obj)
end

---@param entry table
---@param seat number
---@param tile table
---@param obj number
local function handPlace(entry, seat, tile, obj)
    local finalYaw = tile.r + YAW_OFFSET
    local ped, controlled = pedForSeat(entry, seat)
    if ped and loadDict(PLACE.dict) then
        local target = GetOffsetFromEntityInWorldCoords(entry.entity, tile.x, tile.y, SURFACE + 0.03)
        local started = GetGameTimer()
        local attached = false
        while entry.entity and DoesEntityExist(obj) do
            local p = (GetGameTimer() - started) / PLACE.duration
            if p >= PLACE.release then break end
            if controlled then holdClip(ped, PLACE, p) end
            if p < PLACE.grasp then
                reach(ped, IK_RIGHT, RIGHT_HAND, GetEntityCoords(obj), smooth(p / PLACE.grasp))
            else
                if not attached then
                    attached = true
                    attachToHand(obj, ped, PLACE)
                end
                reach(ped, IK_RIGHT, RIGHT_HAND, target, smooth((p - PLACE.grasp) / (PLACE.release - PLACE.grasp)))
            end
            Wait(0)
        end
        if controlled then stopClip(ped, PLACE) end
    end

    if not entry.entity or not DoesEntityExist(obj) then return end
    DetachEntity(obj, false, false)
    placeLocal(entry, obj, tile.x, tile.y, SURFACE + 0.001, 0.0, 0.0, finalYaw)
    FreezeEntityPosition(obj, true)
end

---@param entry table
local function renderBoard(entry)
    local snap = entry.snap
    local board = snap.board
    local objects = entry.board
    local present = {}
    local previous = entry.boardCount
    entry.boardCount = #board

    for i = 1, #board do present[board[i].id] = true end
    for id, obj in pairs(objects) do
        if not present[id] then
            deleteObject(obj)
            objects[id] = nil
        end
    end

    for i = 1, #board do
        local tile = board[i]
        if not objects[tile.id] then
            local hash = tileHash(tile.lo, tile.hi)
            local mine = seated and seated.id == entry.id and seated.seat == tile.seat
            if previous and i == #board and #board == previous + 1 and tile.seat and not mine then
                local fromX, fromY = rackPosition(tile.seat, 4)
                local obj = spawnTile(entry, hash, fromX, fromY, HAND_HEIGHT, HAND_TILT, 0.0, (tile.seat - 1) * 90.0)
                objects[tile.id] = obj
                if obj then
                    CreateThread(function() handPlace(entry, tile.seat, tile, obj) end)
                end
            else
                objects[tile.id] = spawnTile(entry, hash, tile.x, tile.y, SURFACE + 0.001, 0.0, 0.0, tile.r + YAW_OFFSET)
            end
        end
    end
end

---@param entry table
---@param seat number
---@return table?
local function seatTiles(entry, seat)
    local snap = entry.snap
    if snap.result then
        return snap.result.reveal[seat]
    end
    if seated and seated.id == entry.id and seated.seat == seat and myHandId == entry.id then
        return myHand
    end
end

---@param entry table
local function renderRacks(entry)
    local snap = entry.snap
    local hidden = tileHash(0, 0)

    for seat = 1, 4 do
        local info = snap.seats[seat]
        local count = info and info.count or 0
        local tiles = seatTiles(entry, seat)
        if tiles then count = #tiles end

        local parts = { count }
        if tiles then
            for i = 1, #tiles do parts[#parts + 1] = tiles[i].id end
        end
        local signature = table.concat(parts, ',')

        local rack = entry.racks[seat]
        if rack.signature ~= signature then
            deleteAll(rack.objects)
            rack.signature = signature
            rack.tiles = tiles
            for i = 1, count do
                local x, y = rackPosition(seat, i)
                local tile = tiles and tiles[i]
                local hash = tile and tileHash(tile.lo, tile.hi) or hidden
                rack.objects[i] = spawnTile(entry, hash, x, y, HAND_HEIGHT, HAND_TILT, 0.0, (seat - 1) * 90.0)
            end
        end
    end
end

---@param entry table
local function renderStock(entry)
    local snap = entry.snap
    local signature = snap.stock
    if entry.stockSignature == signature then return end

    deleteAll(entry.stock)
    entry.stockSignature = signature
    local hash = tileHash(0, 0)
    for i = 1, snap.stock do
        local x, y = stockPosition(i)
        entry.stock[i] = spawnTile(entry, hash, x, y, SURFACE + 0.0101, 0.0, 180.0, 90.0)
    end
end

---@param ped number
---@param kind string
local function playGesture(ped, kind)
    local anim = ANIMS[kind]
    if not anim or not DoesEntityExist(ped) or not loadDict(anim.dict) then return end
    TaskPlayAnim(ped, anim.dict, anim.clip, 3.0, -3.0, anim.duration, 48, 0.0, false, false, false)
end

---@param entry table
local function renderPile(entry)
    local snap = entry.snap
    local pile = snap.pile
    local objects = entry.pile
    local slots = entry.pileData
    local present = {}
    for i = 1, #pile do present[pile[i].i] = pile[i] end

    local takenBy = {}
    local takes = snap.takes or {}
    for i = 1, #takes do takenBy[takes[i].slot] = takes[i].seat end

    local animated = {}
    if seated and seated.id == entry.id then animated[seated.seat] = true end
    for slot, obj in pairs(objects) do
        if not present[slot] then
            local seat = takenBy[slot]
            local from = slots[slot]
            objects[slot] = nil
            slots[slot] = nil
            if seat and from and DoesEntityExist(obj) and not animated[seat] then
                animated[seat] = true
                CreateThread(function() handPick(entry, seat, obj, from) end)
            elseif seat and from and DoesEntityExist(obj) then
                CreateThread(function() flyToRack(entry, obj, from, seat) end)
            else
                deleteObject(obj)
            end
        end
    end

    local hash = tileHash(0, 0)
    for slot, data in pairs(present) do
        if not objects[slot] then
            objects[slot] = spawnTile(entry, hash, data.x, data.y, SURFACE + 0.0101, 0.0, 180.0, data.r)
            slots[slot] = { x = data.x, y = data.y, r = data.r }
        end
    end
end

---@param hash number
---@return number
local function restZ(hash)
    local minDim = GetModelDimensions(hash)
    return SURFACE - minDim.z
end

---@param entry table
---@return number yaw
---@return number seat
local function caseSeat(entry)
    local seat = entry.snap.host
    if not seat or seat < 1 then seat = 1 end
    return (seat - 1) * 90.0, seat
end

---@param entry table
---@param hash number
---@return number?
local function spawnProp(entry, hash)
    if not loadModel(hash) or not entry.entity then return end
    local c = entry.coords
    local obj = CreateObjectNoOffset(hash, c.x, c.y, c.z, false, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, false, false)
    return obj
end

---@param entry table
local function showCase(entry)
    if entry.caseObj and DoesEntityExist(entry.caseObj) then return end
    local case = spawnProp(entry, CASE_MODEL)
    local lid = spawnProp(entry, LID_MODEL)
    if not case or not lid or not entry.entity then
        deleteObject(case)
        deleteObject(lid)
        return
    end
    local yaw, seat = caseSeat(entry)
    local z = restZ(CASE_MODEL)
    local x, y = seatLocal(seat, 0.0, CASE_REST_Y, 0.0)
    placeLocal(entry, case, x, y, z, 0.0, 0.0, yaw)
    placeLocal(entry, lid, x, y, z, 0.0, 0.0, yaw)
    entry.caseObj, entry.lidObj = case, lid
end

---@param entry table
local function hideCase(entry)
    deleteObject(entry.caseObj)
    deleteObject(entry.lidObj)
    entry.caseObj, entry.lidObj = nil, nil
end

---@param entry table
local function clearScatter(entry)
    local scatter = entry.scatter
    if not scatter then return end
    entry.scatter = nil
    for i = 1, #scatter do deleteObject(scatter[i].obj) end
end

---@param p number
---@param baseZ number
---@return number y
---@return number z
---@return number pitch
---@return number leave
local function openPose(p, baseZ)
    local tilt = smooth((p - 0.3) / 0.12)
    local leave = smooth((p - 0.85) / 0.15)
    local z = baseZ + (SURFACE + 0.065 - baseZ) * smooth(p / 0.15) + 0.085 * tilt + 0.2 * leave
    local pitch = -75.0 * tilt * (1.0 - smooth((p - 0.81) / 0.17))
    return CASE_REST_Y, z, pitch, leave
end

---@param p number
---@param baseZ number
---@param lx number
---@param ly number
---@param lz number
---@return number y
---@return number z
---@return number pitch
local function casePoint(p, baseZ, lx, ly, lz)
    local y, z, pitch = openPose(p, baseZ)
    local pr = rad(pitch)
    return y + ly * cos(pr) - lz * sin(pr), z + ly * sin(pr) + lz * cos(pr), pitch
end

---@param entry table
local function runUnpackFx(entry)
    if entry.unpackFx then return end
    local fx = {}
    entry.unpackFx = fx
    entry.unpacking = true

    CreateThread(function()
        showCase(entry)
        local case, lid = entry.caseObj, entry.lidObj
        entry.caseObj, entry.lidObj = nil, nil

        local hash = tileHash(0, 0)
        local yaw, seat = caseSeat(entry)
        local baseZ = restZ(CASE_MODEL)
        local lidRestZ = restZ(LID_MODEL)
        local ped, controlled = pedForSeat(entry, seat)
        local animReady = ped and loadDict(UNPACK.dict)
        local pieces = {}

        if loadModel(hash) and entry.entity then
            for i = 1, 28 do
                local index = i - 1
                pieces[i] = {
                    slotX = (index % 7 - 3) * 0.027,
                    slotY = ((index // 7) % 2 - 0.5) * 0.052,
                    slotZ = 0.0161 + (index // 14) * 0.0102,
                    start = 0.43 + (27 - index) * 0.0045,
                    x = (random() - 0.5) * SHUFFLE.width,
                    y = (random() - 0.5) * SHUFFLE.depth,
                    z = SURFACE + 0.0101 + (i % 3) * 0.0015,
                    r = random() * 360.0,
                    obj = spawnTile(entry, hash, 0.0, CASE_REST_Y, baseZ, 0.0, 180.0, yaw),
                }
            end
        end

        local started = GetGameTimer()
        while entry.unpackFx == fx and entry.entity do
            local p = (GetGameTimer() - started) / UNPACK.duration
            if p > 1.0 then p = 1.0 end

            local caseY, caseZ, pitch, leave = openPose(p, baseZ)
            local alpha = floor(255 * (1.0 - leave))
            local cx, cy = seatLocal(seat, 0.0, caseY, 0.0)

            if case and DoesEntityExist(case) then
                placeLocal(entry, case, cx, cy, caseZ, pitch, 0.0, yaw)
                SetEntityAlpha(case, alpha, false)
            end

            local lidPos
            if lid and DoesEntityExist(lid) then
                local slide = smooth((p - 0.15) / 0.15)
                local lx, ly = seatLocal(seat, 0.222 * slide, caseY, 0.0)
                local lz = (p < 0.15 and caseZ or caseZ + (lidRestZ - caseZ) * smooth((p - 0.25) / 0.1)) + 0.2 * leave
                placeLocal(entry, lid, lx, ly, lz, p < 0.15 and pitch or 0.0, 0.0, yaw)
                SetEntityAlpha(lid, alpha, false)
                lidPos = GetEntityCoords(lid)
            end

            if animReady and DoesEntityExist(ped) then
                if controlled then holdClip(ped, UNPACK, p) end
                local blend = smooth(p / 0.12) * (1.0 - smooth((p - 0.85) / 0.15))
                local hy, hz = casePoint(p, baseZ, -0.082, 0.0, 0.04)
                local hx, hyy = seatLocal(seat, -0.082, hy, 0.0)
                reach(ped, IK_LEFT, LEFT_HAND, GetOffsetFromEntityInWorldCoords(entry.entity, hx, hyy, hz), blend)
                if lidPos and p > 0.15 and p < 0.3 then
                    reach(ped, IK_RIGHT, RIGHT_HAND, lidPos, blend)
                else
                    local ry, rz = casePoint(p, baseZ, 0.082, 0.0, 0.04)
                    local rx, ryy = seatLocal(seat, 0.082, ry, 0.0)
                    reach(ped, IK_RIGHT, RIGHT_HAND, GetOffsetFromEntityInWorldCoords(entry.entity, rx, ryy, rz), blend)
                end
            end

            for i = 1, #pieces do
                local piece = pieces[i]
                local obj = piece.obj
                if obj and DoesEntityExist(obj) then
                    local current = p < piece.start and p or piece.start
                    local iy, iz, ipitch = casePoint(current, baseZ, piece.slotX, piece.slotY, piece.slotZ)
                    local ix, iyy = seatLocal(seat, piece.slotX, iy, 0.0)
                    local px, py, pz, ppitch, pyaw = ix, iyy, iz, ipitch, yaw

                    if p >= piece.start then
                        local pickup = (p - piece.start) / 0.25
                        if pickup > 1.0 then pickup = 1.0 end
                        local ly, lz = casePoint(piece.start, baseZ, piece.slotX, piece.slotY, 0.085)
                        local lx, lyy = seatLocal(seat, piece.slotX, ly, 0.0)
                        if pickup < 0.3 then
                            local e = smooth(pickup / 0.3)
                            px, py, pz = ix + (lx - ix) * e, iyy + (lyy - iyy) * e, iz + (lz - iz) * e
                        else
                            local m = smooth((pickup - 0.3) / 0.7)
                            local turn = (piece.r - yaw + 180.0) % 360.0 - 180.0
                            px = lx + (piece.x - lx) * m
                            py = lyy + (piece.y - lyy) * m
                            pz = lz + (piece.z - lz) * m + 0.025 * sin(pi * m)
                            ppitch = ipitch * (1.0 - m)
                            pyaw = yaw + turn * m
                        end
                    end
                    placeLocal(entry, obj, px, py, pz, ppitch, 180.0, pyaw)
                end
            end

            if p >= 1.0 then break end
            Wait(0)
        end

        if controlled and ped then stopClip(ped, UNPACK) end
        deleteObject(case)
        deleteObject(lid)

        local phase = entry.snap and entry.snap.phase
        if entry.entity and (phase == 'unpack' or phase == 'shuffle') then
            entry.scatter = pieces
        else
            for i = 1, #pieces do deleteObject(pieces[i].obj) end
        end
        entry.unpacking = false
    end)
end

---@param piece table
local function retarget(piece)
    local tx = piece.x + (random() - 0.5) * 0.16
    local ty = piece.y + (random() - 0.5) * 0.16
    piece.tx = tx < -SHUFFLE_HALF_W and -SHUFFLE_HALF_W or tx > SHUFFLE_HALF_W and SHUFFLE_HALF_W or tx
    piece.ty = ty < -SHUFFLE_HALF_D and -SHUFFLE_HALF_D or ty > SHUFFLE_HALF_D and SHUFFLE_HALF_D or ty
    piece.tr = piece.r + (random() - 0.5) * 180.0
end

---@param entry table
local function runShuffleFx(entry)
    if entry.shuffleFx then return end
    local fx = {}
    entry.shuffleFx = fx

    CreateThread(function()
        local hash = tileHash(0, 0)
        local waitUntil = GetGameTimer() + 1500
        while entry.unpacking and GetGameTimer() < waitUntil do Wait(0) end

        local pieces = entry.scatter
        entry.scatter = nil
        if pieces then
            for i = 1, #pieces do retarget(pieces[i]) end
        elseif loadModel(hash) then
            pieces = {}
            for i = 1, 28 do
                local piece = {
                    x = (random() - 0.5) * SHUFFLE.width,
                    y = (random() - 0.5) * SHUFFLE.depth,
                    z = SURFACE + 0.0101 + (i % 3) * 0.0015,
                    r = random() * 360.0,
                }
                piece.obj = spawnTile(entry, hash, piece.x, piece.y, piece.z, 0.0, 180.0, piece.r)
                retarget(piece)
                pieces[i] = piece
            end
        end

        pieces = pieces or {}
        local speed, turnSpeed = SHUFFLE.speed, SHUFFLE.turnSpeed
        while entry.shuffleFx == fx and entry.entity do
            local base = entry.entity
            local dt = GetFrameTime()
            local step, turn = speed * dt, turnSpeed * dt
            for i = 1, #pieces do
                local piece = pieces[i]
                local obj = piece.obj
                if obj and DoesEntityExist(obj) then
                    local dx, dy = piece.tx - piece.x, piece.ty - piece.y
                    local dist = (dx * dx + dy * dy) ^ 0.5
                    if dist <= step then
                        piece.x, piece.y = piece.tx, piece.ty
                        retarget(piece)
                    else
                        piece.x, piece.y = piece.x + dx / dist * step, piece.y + dy / dist * step
                    end

                    local dr = piece.tr - piece.r
                    piece.r = abs(dr) <= turn and piece.tr or piece.r + (dr > 0 and turn or -turn)

                    local pos = GetOffsetFromEntityInWorldCoords(base, piece.x, piece.y, piece.z)
                    SetEntityCoordsNoOffset(obj, pos.x, pos.y, pos.z, false, false, false)
                    SetEntityRotation(obj, 0.0, 180.0, entry.heading + piece.r, 2, false)
                end
            end
            Wait(0)
        end

        for i = 1, #pieces do deleteObject(pieces[i].obj) end
    end)
end

---@param ped number
---@param pose { root: vector3, heading: number }
local function playSyncedSit(ped, pose)
    local root = pose.root
    TaskPlayAnimAdvanced(ped, SIT.dict, SIT.clip, root.x, root.y, root.z, 0.0, 0.0, pose.heading, 8.0, -8.0, -1, SIT_SYNC_FLAGS, 0.0, 2, 0)
end

---@param entry table
---@param seat number
---@param ped number
---@return { root: vector3, heading: number }?
local function seatSynced(entry, seat, ped)
    if not loadDict(SIT.dict) then return end

    local x, y = seatLocal(seat, 0.0, -CHAIR_DISTANCE, 0.0)
    local chair = GetOffsetFromEntityInWorldCoords(entry.entity, x, y, 0.0)
    local target = vector3(chair.x, chair.y, entry.coords.z + SEAT_HEIGHT)
    local pose = { root = vector3(chair.x, chair.y, entry.coords.z + 0.5), heading = (entry.heading + (seat - 1) * 90.0) % 360.0 }

    FreezeEntityPosition(ped, false)
    SetEntityCoordsNoOffset(ped, chair.x, chair.y, entry.coords.z + 0.9, false, false, true)
    SetEntityHeading(ped, pose.heading)

    for _ = 1, 4 do
        playSyncedSit(ped, pose)
        Wait(400)
        if not DoesEntityExist(ped) then return end
        ForcePedAiAndAnimationUpdate(ped, false, false)

        local offset = target - GetPedBoneCoords(ped, PELVIS_BONE, 0.0, 0.0, 0.0)
        if #offset < 0.01 then break end
        pose.root = pose.root + offset
    end

    playSyncedSit(ped, pose)
    return pose
end

---@param entry table
---@param seat number
---@param ped number
---@return { root: vector3, heading: number }?
local function seatPed(entry, seat, ped)
    local x, y = seatLocal(seat, 0.0, -CHAIR_DISTANCE, 0.0)
    local chair = GetOffsetFromEntityInWorldCoords(entry.entity, x, y, 0.0)
    local pelvisZ = entry.coords.z + SEAT_HEIGHT
    local heading = (entry.heading + (seat - 1) * 90.0) % 360.0

    SetEntityCoordsNoOffset(ped, chair.x, chair.y, entry.coords.z + 0.9, false, false, true)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
    if not loadDict(SIT.dict) then return end

    TaskPlayAnim(ped, SIT.dict, SIT.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    Wait(350)
    if not DoesEntityExist(ped) then return end
    ForcePedAiAndAnimationUpdate(ped, false, false)

    local deadline = GetGameTimer() + 1200
    repeat
        if not DoesEntityExist(ped) then return end
        local pelvis = GetPedBoneCoords(ped, PELVIS_BONE, 0.0, 0.0, 0.0)
        local root = GetEntityCoords(ped)
        SetEntityCoordsNoOffset(ped, root.x + chair.x - pelvis.x, root.y + chair.y - pelvis.y, root.z + pelvisZ - pelvis.z, false, false, true)
        Wait(100)
    until GetGameTimer() >= deadline

    return { root = GetEntityCoords(ped), heading = heading }
end

---@param entry table
local function renderBots(entry)
    local snap = entry.snap
    for seat = 1, 4 do
        local info = snap.seats[seat]
        local current = entry.bots[seat]
        local wanted = info and info.bot and info.model or nil

        if current and current.model ~= wanted then
            deleteObject(current.ped)
            entry.bots[seat] = nil
            current = nil
        end

        if wanted and not current then
            local hash = joaat(BOT_MODELS[wanted] or BOT_MODELS[1])
            if loadModel(hash) and entry.entity then
                local ped = CreatePed(4, hash, 0.0, 0.0, 0.0, 0.0, false, false)
                SetModelAsNoLongerNeeded(hash)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetPedCanRagdoll(ped, false)
                SetEntityCollision(ped, false, false)
                entry.bots[seat] = { ped = ped, model = wanted }
                CreateThread(function() seatPed(entry, seat, ped) end)
            end
        end
    end
end

---@param entry table
local function playLast(entry)
    local last = entry.snap.last
    if not last or last.seq == entry.lastSeq then return end
    entry.lastSeq = last.seq

    local kind = last.kind
    if kind ~= 'shuffle' and kind ~= 'pass' then return end

    local bot = entry.bots[last.seat]
    if bot then
        playGesture(bot.ped, kind)
    elseif seated and seated.id == entry.id and seated.seat == last.seat and animSeq ~= last.seq then
        animSeq = last.seq
        playGesture(cache.ped, kind)
    end
end

---@param entry table
local function renderAll(entry)
    local phase = entry.snap.phase
    if phase == 'unpack' then
        runUnpackFx(entry)
    else
        entry.unpackFx = nil
        if phase == 'lobby' then showCase(entry) else hideCase(entry) end
    end
    if phase == 'shuffle' then
        runShuffleFx(entry)
    else
        entry.shuffleFx = nil
        if phase ~= 'unpack' then clearScatter(entry) end
    end
    renderBots(entry)
    renderBoard(entry)
    renderPile(entry)
    renderRacks(entry)
    local last = entry.snap.last
    if last and last.kind == 'draw' and entry.drawSeq ~= last.seq then
        local first = entry.drawSeq == nil
        entry.drawSeq = last.seq
        local count = #entry.stock
        local obj = entry.stock[count]
        if not first and obj then
            entry.stock[count] = nil
            local x, y = stockPosition(count)
            CreateThread(function() handPick(entry, last.seat, obj, { x = x, y = y, r = 90.0 }) end)
        end
    elseif last and entry.drawSeq == nil then
        entry.drawSeq = last.seq
    end
    renderStock(entry)
    playLast(entry)
end

---@param entry table
local function requestRender(entry)
    if entry.rendering then
        entry.dirty = true
        return
    end

    entry.rendering = true
    CreateThread(function()
        repeat
            entry.dirty = false
            if entry.entity and entry.snap then
                pcall(renderAll, entry)
            end
        until not entry.dirty
        entry.rendering = false
    end)
end

local function pushState()
    if not seated or not frameReady then return end
    local entry = tables[seated.id]
    if not entry or not entry.snap then return end

    interface.send({
        action = 'state',
        data = {
            snap = entry.snap,
            seat = seated.seat,
            hand = myHandId == entry.id and myHand or {},
            view = seated.view,
            targets = config.game.targets,
            turnSeconds = config.game.turnSeconds,
        },
    })
end

local function openFrame()
    if not hasFrame then return end
    if frameReady then
        pushState()
        return
    end
    if not frameMounted then
        frameMounted = true
        interface.show()
    end
end

local function closeFrame()
    if not frameMounted then return end
    interface.focus(false, false)
    if frameReady then interface.send({ action = 'close' }) end

    SetTimeout(50, function()
        if seated or not frameMounted then return end
        frameMounted = false
        frameReady = false
        interface.hide()
    end)
end

local function updateCamera()
    if not seated then return end
    local entry = tables[seated.id]
    if not entry or not entry.entity then return end

    local preset = CAMERAS[seated.view] or CAMERAS.seat
    local px, py, pz = seatLocal(seated.seat, preset.offset.x, preset.offset.y, preset.offset.z)
    local tx, ty, tz = seatLocal(seated.seat, preset.target.x, preset.target.y, preset.target.z)
    local pos = GetOffsetFromEntityInWorldCoords(entry.entity, px, py, pz)
    local target = GetOffsetFromEntityInWorldCoords(entry.entity, tx, ty, tz)

    if not cam then
        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, preset.fov, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 600, true, false)
    else
        SetCamCoord(cam, pos.x, pos.y, pos.z)
        SetCamFov(cam, preset.fov)
    end
    PointCamAtCoord(cam, target.x, target.y, target.z)
end

local function destroyCamera()
    if not cam then return end
    RenderScriptCams(false, true, 600, true, false)
    DestroyCam(cam, false)
    cam = nil
end

---@param on boolean
local function setFocus(on)
    if not seated then return end
    seated.focused = on
    interface.focus(on, on)
end

---@param kind string
---@param text? string
local function sendUi(kind, text)
    if frameReady then interface.send({ action = 'ui', data = { kind = kind, text = text } }) end
end

---@param obj number?
local function setHover(obj)
    if hovered == obj then return end
    if hovered and DoesEntityExist(hovered) then SetEntityDrawOutline(hovered, false) end
    hovered = obj
    if obj then
        SetEntityDrawOutlineColor(0, 204, 201, 255)
        SetEntityDrawOutlineShader(1)
        SetEntityDrawOutline(obj, true)
    end
end

---@param entry table
local function cancelDrag(entry)
    if not drag then return end
    drag = nil
    stopClip(cache.ped, PLACE)
    if seated then
        entry.racks[seated.seat].signature = nil
        requestRender(entry)
    end
end

---@param skipServer? boolean
local function standUp(skipServer)
    local current = seated
    if not current then return end
    seated = nil

    setHover(nil)
    drag = nil
    closeFrame()
    destroyCamera()

    local ped = cache.ped
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)

    local entry = tables[current.id]
    if entry and entry.entity and DoesEntityExist(entry.entity) then
        local x, y = seatLocal(current.seat, 0.0, -(CHAIR_DISTANCE + 0.55), 0.0)
        local pos = GetOffsetFromEntityInWorldCoords(entry.entity, x, y, 0.0)
        SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
        SetEntityHeading(ped, (entry.heading + (current.seat - 1) * 90.0) % 360.0)
    end

    playerState.invBusy = false
    myHand, myHandId = {}, 0

    if entry then requestRender(entry) end
    if not skipServer then
        lib.callback.await('sm_domino:stand', false)
    end
end

---@param planeZ number
---@return vector3?
local function cursorOnPlane(planeZ)
    local origin, dir = GetWorldCoordFromScreenCoord(GetControlNormal(0, 239), GetControlNormal(0, 240))
    if abs(dir.z) < 0.0001 then return end
    local t = (planeZ - origin.z) / dir.z
    if t <= 0.0 then return end
    return origin + dir * t
end

---@param list table
---@param best? number
---@param bestKey? any
---@param bestDist? number
---@return number?
---@return any
---@return number?
local function nearestObject(list, best, bestKey, bestDist)
    for key, obj in pairs(list) do
        if obj and DoesEntityExist(obj) then
            local p = GetEntityCoords(obj)
            local w = cursorOnPlane(p.z)
            if w then
                local dx, dy = w.x - p.x, w.y - p.y
                local d = dx * dx + dy * dy
                if d <= PICK_RADIUS_SQ and (not bestDist or d < bestDist) then
                    best, bestKey, bestDist = obj, key, d
                end
            end
        end
    end
    return best, bestKey, bestDist
end

---@param entry table
---@param world vector3
---@return string?
local function dropSide(entry, world)
    local tips = entry.snap.tips
    local lp = GetOffsetFromEntityGivenWorldCoords(entry.entity, world.x, world.y, world.z)
    if not tips then
        return abs(lp.x) <= OPEN_DROP_AREA and abs(lp.y) <= OPEN_DROP_AREA and 'left' or nil
    end

    local lx, ly = lp.x - tips[1].x, lp.y - tips[1].y
    local rx, ry = lp.x - tips[2].x, lp.y - tips[2].y
    local left, right = (lx * lx + ly * ly) ^ 0.5, (rx * rx + ry * ry) ^ 0.5
    if left <= DROP_RADIUS and left <= right then return 'left' end
    if right <= DROP_RADIUS then return 'right' end
end

---@param entry table
---@param tile table
---@param world vector3?
local function releaseDrag(entry, tile, world)
    drag = nil
    local side = world and dropSide(entry, world)
    if not side then
        sendUi('message', 'table')
        entry.racks[seated.seat].signature = nil
        requestRender(entry)
        return
    end

    CreateThread(function()
        local ok = lib.callback.await('sm_domino:act', false, 'play', tile.id, side)
        if ok then return end
        sendUi('message', 'match')
        if seated then
            entry.racks[seated.seat].signature = nil
            requestRender(entry)
        end
    end)
end

---@param entry table
---@param slot number
local function pickTile(entry, slot)
    local obj, from = entry.pile[slot], entry.pileData[slot]
    entry.pile[slot] = nil
    entry.pileData[slot] = nil
    if obj and from then
        local seat = seated.seat
        CreateThread(function() handPick(entry, seat, obj, from) end)
    else
        deleteObject(obj)
    end
    CreateThread(function()
        if lib.callback.await('sm_domino:pick', false, slot) then return end
        requestRender(entry)
    end)
end

---@param entry table
---@param current table
local function interactFrame(entry, current)
    for i = 1, #BLOCKED_CONTROLS do
        DisableControlAction(0, BLOCKED_CONTROLS[i], true)
    end
    SetMouseCursorThisFrame()

    local snap = entry.snap
    if not snap then return end
    local mySeat = current.seat
    local phase = snap.phase
    local myTurn = phase == 'play' and snap.turn == mySeat

    if IsDisabledControlJustPressed(0, CONTROL_V) then
        current.view = current.view == 'seat' and 'top' or 'seat'
        updateCamera()
        pushState()
    elseif IsDisabledControlJustPressed(0, CONTROL_BACKSPACE) then
        sendUi('menu')
    elseif IsDisabledControlJustPressed(0, CONTROL_R) then
        sendUi('showResult')
    elseif IsDisabledControlJustPressed(0, CONTROL_X) then
        sendUi('leave')
    end

    if drag then
        if not myTurn or not DoesEntityExist(drag.obj) then
            cancelDrag(entry)
            return
        end
        SetMouseCursorSprite(4)
        local world = cursorOnPlane(entry.coords.z + SURFACE + 0.03)
        if world then
            SetEntityCoordsNoOffset(drag.obj, world.x, world.y, world.z, false, false, false)
            SetEntityRotation(drag.obj, 0.0, 0.0, entry.heading + (mySeat - 1) * 90.0, 2, false)
        end
        local ped = cache.ped
        local grip = smooth((GetGameTimer() - drag.started) / 250.0)
        holdClip(ped, PLACE, PLACE.grasp * grip + 0.001)
        reach(ped, IK_RIGHT, RIGHT_HAND, GetEntityCoords(drag.obj), grip)
        if IsDisabledControlJustReleased(0, CONTROL_CLICK) then
            stopClip(ped, PLACE)
            releaseDrag(entry, drag.tile, world)
        end
        return
    end

    local obj, key, dist, kind
    if myTurn then
        obj, key, dist = nearestObject(entry.racks[mySeat].objects)
        if obj then kind = 'rack' end
        if snap.stock > 0 then
            local stockObj, stockKey, stockDist = nearestObject(entry.stock, nil, nil, dist)
            if stockObj then obj, key, dist, kind = stockObj, stockKey, stockDist, 'stock' end
        end
    elseif phase == 'deal' then
        local info = snap.seats[mySeat]
        if info and info.count < HAND_SIZE then
            obj, key, dist = nearestObject(entry.pile)
            if obj then kind = 'pile' end
        end
    end

    setHover(obj)
    SetMouseCursorSprite(obj and 3 or 1)

    if not obj or not IsDisabledControlJustPressed(0, CONTROL_CLICK) then return end

    if kind == 'rack' then
        local tiles = entry.racks[mySeat].tiles
        local tile = tiles and tiles[key]
        if tile then
            setHover(nil)
            drag = { obj = obj, tile = tile, started = GetGameTimer() }
        end
    elseif kind == 'pile' then
        setHover(nil)
        pickTile(entry, key)
    elseif kind == 'stock' then
        setHover(nil)
        CreateThread(function()
            if not lib.callback.await('sm_domino:act', false, 'draw') then sendUi('message', 'draw') end
        end)
    end
end

local function seatLoop()
    while seated do
        local ped = cache.ped
        local current = seated
        local entry = tables[current.id]

        if not entry or not entry.entity or IsPedDeadOrDying(ped, true) then
            standUp()
            break
        end

        if current.pose and not IsEntityPlayingAnim(ped, SIT.dict, SIT.clip, 3) then
            playSyncedSit(ped, current.pose)
        end

        if current.focused then
            setHover(nil)
            if drag then cancelDrag(entry) end
            Wait(100)
        else
            interactFrame(entry, current)
            Wait(0)
        end
    end
end

---@param id number
---@param seat number
local function sit(id, seat)
    if seated or placing then return end
    if cache.vehicle then return notify(REASONS.vehicle) end

    local entry = tables[id]
    if not entry or not entry.entity then return end
    if not loadDict(SIT.dict) then return notify('Could not load the sitting animation.') end

    local ok, reason = lib.callback.await('sm_domino:sit', false, id, seat)
    if not ok then return notifyFail(reason, 'You cannot sit here.') end

    entry = tables[id]
    if not entry or not entry.entity then
        lib.callback.await('sm_domino:stand', false)
        return
    end

    seated = { id = id, seat = seat, view = 'seat', focused = false }
    playerState.invBusy = true
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    local pose = seatSynced(entry, seat, cache.ped)
    if pose and seated then
        seated.pose = pose
    end
    updateCamera()
    openFrame()
    requestRender(entry)
    CreateThread(seatLoop)
end

---@param id number
local function pack(id)
    if seated or placing then return end
    if not lib.progressBar({
        duration = 3000,
        label = 'Packing up the table...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = 'anim@heists@money_grab@briefcase', clip = 'put_down_case' },
    }) then return end

    local ok, reason = lib.callback.await('sm_domino:pack', false, id)
    if ok then
        notify('You packed up the domino table.', 'success')
    else
        notifyFail(reason, 'Could not pack up the table.')
    end
end

local function createBoardTexture()
    local color = config.boardColor
    local txd = CreateRuntimeTxd(BOARD_TXD)
    local texture = CreateRuntimeTexture(txd, 'board', 4, 4)
    for px = 0, 3 do
        for py = 0, 3 do
            SetRuntimeTexturePixel(texture, px, py, color[1], color[2], color[3], 255)
        end
    end
    CommitRuntimeTexture(texture)
end

createBoardTexture()

local function applyBoardTexture()
    AddReplaceTexture(config.tableModel, config.boardTexture, BOARD_TXD, 'board')
end

---@param entry table
local function despawnTable(entry)
    if seated and seated.id == entry.id then standUp(true) end
    entry.shuffleFx = nil
    entry.unpackFx = nil
    hideCase(entry)
    clearScatter(entry)

    for i = 1, #entry.chairs do
        local chair = entry.chairs[i]
        interact:removeLocalEntity(chair)
        deleteObject(chair)
    end
    entry.chairs = {}

    if entry.entity then
        ox_target:removeLocalEntity(entry.entity, 'sm_domino_pack')
        deleteObject(entry.entity)
        entry.entity = nil
    end

    deleteAll(entry.board)
    deleteAll(entry.stock)
    deleteAll(entry.pile)
    for seat = 1, 4 do
        deleteAll(entry.racks[seat].objects)
        entry.racks[seat].signature = nil
        local bot = entry.bots[seat]
        if bot then deleteObject(bot.ped) end
        entry.bots[seat] = nil
    end
    entry.stockSignature, entry.boardCount = nil, nil
end

---@param entry table
local function spawnTable(entry)
    if entry.entity or entry.loading then return end
    entry.loading = true

    local loaded = loadModel(TABLE_MODEL) and loadModel(CHAIR_MODEL)
    if loaded then applyBoardTexture() end
    entry.loading = false
    if not loaded or not entry.inRange or entry.removed then return end

    local coords = entry.coords
    local obj = CreateObjectNoOffset(TABLE_MODEL, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, entry.heading)
    FreezeEntityPosition(obj, true)
    entry.entity = obj

    local minDim = GetModelDimensions(CHAIR_MODEL)
    for seat = 1, 4 do
        local x, y = seatLocal(seat, 0.0, -CHAIR_DISTANCE, 0.0)
        local pos = GetOffsetFromEntityInWorldCoords(obj, x, y, -minDim.z)
        local chair = CreateObjectNoOffset(CHAIR_MODEL, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(chair, (entry.heading + (seat - 1) * 90.0 + CHAIR_OFFSET) % 360.0)
        FreezeEntityPosition(chair, true)
        entry.chairs[seat] = chair

        local id = entry.id
        interact:addLocalEntity(chair, {
            {
                name = 'sm_domino_sit',
                label = 'Sit down to play',
                icon = 'fa-solid fa-chair',
                distance = INTERACT_DISTANCE,
                onSelect = function() sit(id, seat) end,
            },
        })
    end

    if entry.owner == QBPlayerData.citizenid then
        local id = entry.id
        ox_target:addLocalEntity(obj, {
            {
                name = 'sm_domino_pack',
                label = 'Pack up table',
                icon = 'fa-solid fa-box',
                distance = INTERACT_DISTANCE + 0.6,
                canInteract = function() return not seated and not placing end,
                onSelect = function() pack(id) end,
            },
        })
    end

    SetModelAsNoLongerNeeded(TABLE_MODEL)
    SetModelAsNoLongerNeeded(CHAIR_MODEL)

    local snap = lib.callback.await('sm_domino:watch', false, entry.id)
    if snap and entry.entity then
        entry.snap = snap
        requestRender(entry)
    end
end

---@param data table
local function registerTable(data)
    local entry = {
        id = data.id,
        coords = vector3(data.x, data.y, data.z),
        heading = data.h,
        owner = data.owner,
        chairs = {},
        board = {},
        stock = {},
        pile = {},
        pileData = {},
        bots = {},
        racks = { { objects = {} }, { objects = {} }, { objects = {} }, { objects = {} } },
    }

    entry.point = lib.points.new({
        coords = entry.coords,
        distance = STREAM_DISTANCE,
        onEnter = function()
            entry.inRange = true
            CreateThread(function() spawnTable(entry) end)
        end,
        onExit = function()
            entry.inRange = false
            if seated and seated.id == entry.id then return end
            despawnTable(entry)
            entry.snap = nil
            CreateThread(function() lib.callback.await('sm_domino:unwatch', false, entry.id) end)
        end,
    })

    tables[entry.id] = entry
end

---@param id number
local function unregisterTable(id)
    local entry = tables[id]
    if not entry then return end
    tables[id] = nil
    entry.removed = true
    entry.point:remove()
    despawnTable(entry)
end

---@param list table?
local function syncRegistry(list)
    local wanted = {}
    if list then
        for i = 1, #list do wanted[list[i].id] = list[i] end
    end

    for id in pairs(tables) do
        if not wanted[id] then unregisterTable(id) end
    end

    for id, data in pairs(wanted) do
        if not tables[id] then registerTable(data) end
    end
end

CreateThread(function()
    while true do
        Wait(10000)
        for _, entry in pairs(tables) do
            if entry.entity and entry.inRange and not (seated and seated.id == entry.id) then
                local snap = lib.callback.await('sm_domino:watch', false, entry.id)
                if snap and entry.entity and (not entry.snap or snap.seq >= entry.snap.seq) then
                    entry.snap = snap
                    requestRender(entry)
                end
            end
        end
    end
end)

AddStateBagChangeHandler(STATE_KEY, 'global', function(_, _, value)
    syncRegistry(value)
end)

CreateThread(function()
    for _ = 1, 300 do
        if QBPlayerData.citizenid then break end
        Wait(1000)
    end
    syncRegistry(GlobalState[STATE_KEY])
end)

RegisterNetEvent('sm_domino:client:state', function(snap)
    if source == '' then return end
    local entry = tables[snap.id]
    if not entry or not entry.entity then return end
    if entry.snap and entry.snap.seq > snap.seq then return end

    entry.snap = snap
    requestRender(entry)
    if seated and seated.id == snap.id then pushState() end
end)

RegisterNetEvent('sm_domino:client:hand', function(id, tiles)
    if source == '' then return end
    myHandId, myHand = id, tiles

    local entry = tables[id]
    if entry and entry.entity then requestRender(entry) end
    if seated and seated.id == id then pushState() end
end)

RegisterNetEvent('sm_domino:client:kicked', function(id, reason)
    if source == '' then return end
    if not seated or seated.id ~= id then return end
    standUp(true)
    notifyFail(reason, 'You left the table.')
end)

RegisterNetEvent('sm_domino:client:place', function(slot)
    if source == '' then return end
    if placing or seated then return end
    if cache.vehicle then return notify(REASONS.vehicle) end
    if not loadModel(TABLE_MODEL) then return notify('Could not load the table model.') end
    applyBoardTexture()

    placing = true
    local ped = cache.ped
    local origin = GetEntityCoords(ped)
    local ghost = CreateObjectNoOffset(TABLE_MODEL, origin.x, origin.y, origin.z, false, false, false)
    SetEntityCollision(ghost, false, false)
    SetEntityAlpha(ghost, 170, false)

    local heading = GetEntityHeading(ped)
    local start = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.8, 0.0)
    local px, py = start.x, start.y
    local result

    infoui:show({ id = INFO_ID, title = 'Domino table', icon = 'fa-solid fa-dice-six', description = PLACE_HINT })

    while placing do
        DisableAllControlActions(0)
        for i = 1, #PLACE_CONTROLS do
            EnableControlAction(0, PLACE_CONTROLS[i], true)
        end

        if IsDisabledControlPressed(0, CONTROL_WHEEL_UP) then heading = heading + 5.0 end
        if IsDisabledControlPressed(0, CONTROL_WHEEL_DOWN) then heading = heading - 5.0 end

        local step = GetFrameTime() * MOVE_SPEED
        local yaw = rad(GetGameplayCamRot(2).z)
        local fx, fy = -sin(yaw), cos(yaw)
        local forward, right = 0.0, 0.0
        if IsDisabledControlPressed(0, CONTROL_UP) then forward = forward + step end
        if IsDisabledControlPressed(0, CONTROL_DOWN) then forward = forward - step end
        if IsDisabledControlPressed(0, CONTROL_RIGHT) then right = right + step end
        if IsDisabledControlPressed(0, CONTROL_LEFT) then right = right - step end
        px = px + fx * forward + fy * right
        py = py + fy * forward - fx * right

        local pedPos = GetEntityCoords(ped)
        local dx, dy = px - pedPos.x, py - pedPos.y
        local reach = (dx * dx + dy * dy) ^ 0.5
        if reach > PLACE_REACH then
            local scale = PLACE_REACH / reach
            px, py = pedPos.x + dx * scale, pedPos.y + dy * scale
        end

        SetEntityCoords(ghost, px, py, pedPos.z + 1.0, false, false, false, false)
        PlaceObjectOnGroundProperly(ghost)
        SetEntityHeading(ghost, heading)

        local valid = #(pedPos - GetEntityCoords(ghost)) <= PLACE_DISTANCE

        if IsDisabledControlJustPressed(0, CONTROL_ENTER) then
            if valid then
                result = GetEntityCoords(ghost)
                break
            end
            notify(REASONS.far)
        elseif IsDisabledControlJustPressed(0, CONTROL_BACK) or IsDisabledControlJustPressed(0, CONTROL_ESC) then
            break
        end

        Wait(0)
    end

    DeleteEntity(ghost)
    SetModelAsNoLongerNeeded(TABLE_MODEL)
    infoui:remove(INFO_ID)

    if result and lib.progressBar({
        duration = 3500,
        label = 'Setting up the table...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = 'anim@heists@money_grab@briefcase', clip = 'put_down_case' },
    }) then
        local ok, reason = lib.callback.await('sm_domino:place', false, slot, { x = result.x, y = result.y, z = result.z }, heading % 360.0)
        if ok then
            notify('Table set up. Grab a chair to play.', 'success')
        else
            notifyFail(reason, 'Could not set up the table.')
        end
    end

    placing = false
end)

---@param value any
---@return number?
local function toInt(value)
    return type(value) == 'number' and tointeger(value) or nil
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        frameReady = true
        cb({})
        if seated then pushState() end
    end)

    interface.callback('focus', function(data, cb)
        cb({})
        setFocus(type(data) == 'table' and data.on == true)
    end)

    interface.callback('host', function(data, cb)
        if not seated or type(data) ~= 'table' or type(data.action) ~= 'string' then return cb({ ok = false }) end
        local value = data.value
        if type(value) == 'number' then value = toInt(value) end
        local ok, reason = lib.callback.await('sm_domino:host', false, data.action, value)
        if not ok and reason then notifyFail(reason, 'Action failed.') end
        cb({ ok = ok == true })
    end)

    interface.callback('view', function(_, cb)
        if not seated then return cb({ view = 'seat' }) end
        seated.view = seated.view == 'seat' and 'top' or 'seat'
        updateCamera()
        cb({ view = seated.view })
    end)

    interface.callback('continue', function(_, cb)
        if not seated then return cb({ ok = false }) end
        cb({ ok = lib.callback.await('sm_domino:ready', false) == true })
    end)

    interface.callback('stand', function(_, cb)
        cb({})
        CreateThread(function() standUp() end)
    end)
end

AddEventHandler('sm_domino:client:forceClose', function()
    if seated then
        CreateThread(function() standUp() end)
    end
    if placing then placing = false end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    if seated then
        local ped = cache.ped
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
        destroyCamera()
        playerState.invBusy = false
    end
    infoui:remove(INFO_ID)
    RemoveReplaceTexture(config.tableModel, config.boardTexture)
    for _, entry in pairs(tables) do
        despawnTable(entry)
    end
end)
