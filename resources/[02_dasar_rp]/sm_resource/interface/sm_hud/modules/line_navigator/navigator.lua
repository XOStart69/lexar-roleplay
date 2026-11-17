---@class NavigatorSettings
---@field enabled boolean
---@field showOnFoot boolean
---@field missionRoute boolean
---@field priority 'waypoint'|'mission'
---@field preset string
---@field color string
---@field missionColor string
---@field turnHighlight boolean
---@field turnColor string
---@field animated boolean
---@field width number
---@field spacing number
---@field lift number
---@field distance number
---@field marker boolean
---@field autoClear boolean
---@field panel boolean

---@class RoutePoint
---@field pos vector3
---@field abs number
---@field junction boolean
---@field zone boolean
---@field grounded boolean
---@field relaxedX? number
---@field relaxedY? number
---@field len? number
---@field source? RoutePoint
---@field dirX? number
---@field dirY? number
---@field dirZ? number

---@class RouteTurn
---@field startAt number
---@field endAt number
---@field maneuver 'left'|'right'|'sharpLeft'|'sharpRight'|'uturn'

---@class RouteColor
---@field r integer
---@field g integer
---@field b integer
---@field a integer

---@class NavigatorRoute
---@field raw RoutePoint[]
---@field points RoutePoint[]
---@field turns RouteTurn[]
---@field complete boolean
---@field builtAt integer
---@field slot? integer
---@field destination? vector3
---@field remaining? number

local TEXTURE_DICT = 'mrhunter_navline_chevron'
local DEFAULT_PRESET = '501'
local PRESETS = {
    ['101'] = true,
    ['201'] = true,
    ['301'] = true,
    ['401'] = true,
    ['501'] = true,
    ['601'] = true,
    ['701'] = true,
    ['801'] = true,
    ['901'] = true,
}
local MARKER_ROT_X = 177.0
local MAX_CHEVRONS = 40
local LOD_TIERS = { 30.0, 70.0, 150.0 }
local LOD_BLEND = 15.0
local TANGENT_REACH = 2
local MAX_PITCH = 0.53
local SLOT_WAYPOINT = 0
local SLOT_MISSION = 1
local WAYPOINT_SPRITE = 8
local JUNCTION_FLAG = 128
local IGNORED_CLASSES = { [14] = true, [15] = true, [16] = true }
local LOOKAHEAD = 300.0
local REBUILD_INTERVAL = 1500
local KEEP_BEHIND = 60.0
local GROUND_PROBE = 2.0
local GROUND_TOLERANCE = 2.5
local REGROUND_RANGE = 200.0
local REGROUND_LIMIT = 24
local STICKY_CHECK = 150.0
local STICKY_SKIP = 40.0
local RELAX_RADIUS = 4.0
local RELAX_ITERATIONS = 120
local RELAX_RATE = 0.1
local RELAX_SETTLE = 60.0
local STICKY_TOLERANCE = 3.0
local SMOOTH_STEP = 2.0
local FLOW_SPEED = 5.0
local NEAR_FADE = 12.0
local FAR_FADE = 25.0
local CORNER_STEP = 15.0
local MAX_SUBDIVISIONS = 8
local TURN_ANGLE = 30.0
local SHARP_ANGLE = 120.0
local UTURN_ANGLE = 160.0
local TURN_HIGHLIGHT = 40.0
local OFF_ROUTE = 15.0
local ARRIVE_RADIUS = 20.0
local ARRIVE_NOTICE = 60.0
local GROUND_RANGE = 150.0
local GROUND_FOOTPRINT = 0.7
local GROUND_CACHE_LIMIT = 6000
local GROUND_SNAP_DELTA = 1.0
local PROGRESS_BEHIND = 10.0
local PROGRESS_AHEAD = 40.0

---@type NavigatorRoute
local route = {
    raw = {},
    points = {},
    turns = {},
    complete = false,
    builtAt = 0,
}

local travel = 0.0
local progressIndex = 1
local travelLength = 0.0
local activeTraveler = nil
local remainingValue = nil
local remainingText = nil
local divergence = 0
local averageSpeed = 0.0
local missionBlip = 0
local lastMissionScan = 0
local textureReady = false
local lastPayload = nil
local colors = {}
local groundCache = {}
local groundCount = 0

---@param hex string
---@return RouteColor
local function parseColor(hex)
    local key = tostring(hex)
    local color = colors[key]
    if color then return color end

    local r, g, b, a = key:match('^#(%x%x)(%x%x)(%x%x)(%x%x)$')
    if not r then
        r, g, b = key:match('^#(%x%x)(%x%x)(%x%x)$')
        a = 'ff'
    end

    color = r and { r = tonumber(r, 16), g = tonumber(g, 16), b = tonumber(b, 16), a = tonumber(a, 16) }
        or { r = 255, g = 255, b = 255, a = 255 }
    colors[key] = color
    return color
end

local function dist2D(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

---@return vector3?
local function direction2D(from, to)
    local dx, dy = to.x - from.x, to.y - from.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001 then return nil end
    return vector3(dx / length, dy / length, 0.0)
end

local function knot(a, b)
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    return math.max(math.sqrt(math.sqrt(dx * dx + dy * dy + dz * dz)), 0.0001)
end

local function catmullRom(p0, p1, p2, p3, t)
    local t1 = knot(p0, p1)
    local t2 = t1 + knot(p1, p2)
    local t3 = t2 + knot(p2, p3)
    local u = t1 + (t2 - t1) * t
    local a1 = p0 * ((t1 - u) / t1) + p1 * (u / t1)
    local a2 = p1 * ((t2 - u) / (t2 - t1)) + p2 * ((u - t1) / (t2 - t1))
    local a3 = p2 * ((t3 - u) / (t3 - t2)) + p3 * ((u - t2) / (t3 - t2))
    local b1 = a1 * ((t2 - u) / t2) + a2 * (u / t2)
    local b2 = a2 * ((t3 - u) / (t3 - t1)) + a3 * ((u - t1) / (t3 - t1))
    return b1 * ((t2 - u) / (t2 - t1)) + b2 * ((u - t1) / (t2 - t1))
end

local function bendAngle(a, b, c)
    local dirIn, dirOut = direction2D(a, b), direction2D(b, c)
    if not dirIn or not dirOut then return 0.0 end
    return math.deg(math.acos(math.max(-1.0, math.min(1.0, dirIn.x * dirOut.x + dirIn.y * dirOut.y))))
end

local function formatDistance(meters)
    if meters >= 1000.0 then
        return (('%.1f km'):format(meters / 1000.0):gsub('%.', ','))
    end
    return ('%d m'):format(math.floor(meters / 10.0 + 0.5) * 10)
end

---@param cfg NavigatorSettings
---@return integer?
local function travelerOf(cfg)
    local vehicle = cache.vehicle
    if vehicle then
        return not IGNORED_CLASSES[GetVehicleClass(vehicle)] and vehicle or nil
    end
    return cfg.showOnFoot and cache.ped or nil
end

local function hasRoute(slot)
    return (GetPosAlongGpsTypeRoute(true, 0.0, slot))
end

---@return vector3?
local function waypointDestination()
    local blip = GetFirstBlipInfoId(WAYPOINT_SPRITE)
    return DoesBlipExist(blip) and GetBlipInfoIdCoord(blip) or nil
end

---@return vector3?
local function missionDestination()
    if missionBlip ~= 0 and DoesBlipExist(missionBlip) and DoesBlipHaveGpsRoute(missionBlip) then
        return GetBlipInfoIdCoord(missionBlip)
    end

    local now = GetGameTimer()
    if now - lastMissionScan < 2000 then return nil end

    lastMissionScan = now
    missionBlip = 0

    for sprite = 1, 1024 do
        if sprite ~= WAYPOINT_SPRITE then
            local blip = GetFirstBlipInfoId(sprite)
            while blip ~= 0 do
                if DoesBlipHaveGpsRoute(blip) then
                    missionBlip = blip
                    return GetBlipInfoIdCoord(blip)
                end
                blip = GetNextBlipInfoId(sprite)
            end
        end
    end
end

---@param cfg NavigatorSettings
---@return integer?
---@return vector3?
local function selectRoute(cfg)
    local waypoint = hasRoute(SLOT_WAYPOINT)
    local mission = cfg.missionRoute and hasRoute(SLOT_MISSION)

    if mission and (cfg.priority == 'mission' or not waypoint) then
        return SLOT_MISSION, missionDestination()
    end

    if waypoint then
        return SLOT_WAYPOINT, waypointDestination()
    end
end

local function sameDestination(a, b)
    if not a or not b then return a == b end
    return dist2D(a, b) <= 1.0
end

---@param points RoutePoint[]
---@param at number
---@param index integer
---@param key? 'abs'|'len'
---@return number
---@return number
---@return number
---@return integer
---@return number
local function pointAt(points, at, index, key)
    key = key or 'abs'
    local count = #points
    while index < count - 1 and points[index + 1][key] < at do
        index = index + 1
    end

    local from, to = points[index], points[index + 1]
    local span = to[key] - from[key]
    local t = span > 0.0 and math.max(0.0, math.min(1.0, (at - from[key]) / span)) or 0.0
    local a, b = from.pos, to.pos
    return a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, index, t
end

---@param point RoutePoint
local function groundPoint(point)
    local pos = point.pos
    local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + GROUND_PROBE, false)

    if found and math.abs(groundZ - pos.z) <= GROUND_TOLERANCE then
        point.pos = vector3(pos.x, pos.y, groundZ)
        point.grounded = true
    end
end

---@param point RoutePoint
local function prepare(point)
    local valid, _, flags = GetVehicleNodeProperties(point.pos.x, point.pos.y, point.pos.z)
    point.junction = valid and (flags & JUNCTION_FLAG) ~= 0
    groundPoint(point)
end

---@param slot integer
---@param step number
---@param lookahead number
---@param checkTo? number
---@param appendFrom? number
---@return RoutePoint[]
---@return boolean
local function sampleCandidate(slot, step, lookahead, checkTo, appendFrom)
    local points = {}
    local distance = math.ceil((travel + (checkTo and STICKY_SKIP or 0.0)) / step) * step - travel

    while distance <= lookahead do
        if checkTo and distance > checkTo and distance < appendFrom then
            distance = math.ceil((travel + appendFrom) / step) * step - travel
            if distance > lookahead then break end
        end

        local ok, pos = GetPosAlongGpsTypeRoute(true, distance, slot)
        if not ok then
            return points, true
        end

        local last = points[#points]
        if not last or dist2D(last.pos, pos) > 0.5 then
            points[#points + 1] = { pos = pos, abs = travel + distance, junction = false, zone = false, grounded = false }
        end

        distance = distance + step
    end

    return points, false
end

---@param raw RoutePoint[]
---@param pos vector3
---@param index integer
---@return number
local function crossTrack(raw, pos, index)
    local best = math.huge

    for i = math.max(1, index - 2), math.min(#raw - 1, index + 2) do
        local a, b = raw[i].pos, raw[i + 1].pos
        local abx, aby = b.x - a.x, b.y - a.y
        local length2 = abx * abx + aby * aby
        local t = length2 > 0.0 and math.max(0.0, math.min(1.0, ((pos.x - a.x) * abx + (pos.y - a.y) * aby) / length2)) or 0.0
        local dx, dy = pos.x - (a.x + abx * t), pos.y - (a.y + aby * t)
        best = math.min(best, dx * dx + dy * dy)
    end

    return math.sqrt(best)
end

---@param raw RoutePoint[]
---@param candidate RoutePoint[]
---@return number
local function deviation(raw, candidate)
    local worst = 0.0
    local index = 1
    local first, last = raw[1].abs, raw[#raw].abs

    for i = 1, #candidate do
        local point = candidate[i]
        if point.abs > last or point.abs > travel + STICKY_CHECK then break end

        if point.abs >= first and point.abs >= travel + STICKY_SKIP then
            local _, _, _, nextIndex = pointAt(raw, point.abs, index)
            worst = math.max(worst, crossTrack(raw, point.pos, nextIndex))
            index = nextIndex
        end
    end

    return worst
end

---@param points RoutePoint[]
---@param from integer
local function relax(points, from)
    local count = #points
    from = math.max(3, from)
    if count - 2 < from then return end

    local ox, oy, x, y, nx, ny = {}, {}, {}, {}, {}, {}
    for i = 1, count do
        local pos = points[i].pos
        ox[i], oy[i], x[i], y[i] = pos.x, pos.y, pos.x, pos.y
    end

    for _ = 1, RELAX_ITERATIONS do
        for i = from, count - 2 do
            local fx = x[i - 2] - 4.0 * x[i - 1] + 6.0 * x[i] - 4.0 * x[i + 1] + x[i + 2]
            local fy = y[i - 2] - 4.0 * y[i - 1] + 6.0 * y[i] - 4.0 * y[i + 1] + y[i + 2]
            local px, py = x[i] - RELAX_RATE * fx, y[i] - RELAX_RATE * fy
            local dx, dy = px - ox[i], py - oy[i]
            local shift = math.sqrt(dx * dx + dy * dy)

            if shift > RELAX_RADIUS then
                px, py = ox[i] + dx / shift * RELAX_RADIUS, oy[i] + dy / shift * RELAX_RADIUS
            end

            nx[i], ny[i] = px, py
        end

        for i = from, count - 2 do
            x[i], y[i] = nx[i], ny[i]
        end
    end

    for i = from, count - 2 do
        points[i].pos = vector3(x[i], y[i], points[i].pos.z)
    end
end

---@param points RoutePoint[]
local function markZones(points)
    for i = 1, #points do
        local before, after = points[i - 1], points[i + 1]
        points[i].zone = points[i].junction or (before and before.junction) or (after and after.junction) or false
    end
end

---@param points RoutePoint[]
---@return RouteTurn[]
local function detectTurns(points)
    local turns = {}
    local i = 1

    while i <= #points do
        if points[i].zone then
            local zoneStart = i
            while i <= #points and points[i].zone do i = i + 1 end

            local zoneEnd = i - 1
            local before, after = points[zoneStart - 2], points[zoneEnd + 2]
            local entry = before and direction2D(before.pos, points[zoneStart].pos)
            local exit = after and direction2D(points[zoneEnd].pos, after.pos)

            if entry and exit then
                local angle = math.deg(math.atan(entry.x * exit.y - entry.y * exit.x, entry.x * exit.x + entry.y * exit.y))
                local size = math.abs(angle)

                if size >= TURN_ANGLE then
                    local side = angle > 0.0 and 'Left' or 'Right'
                    turns[#turns + 1] = {
                        startAt = points[zoneStart].abs,
                        endAt = points[zoneEnd].abs,
                        maneuver = size >= UTURN_ANGLE and 'uturn' or size >= SHARP_ANGLE and 'sharp' .. side or side:lower(),
                    }
                end
            end
        else
            i = i + 1
        end
    end

    return turns
end

---@param points RoutePoint[]
---@return RoutePoint[]
local function subdivide(points)
    local count = #points
    if count < 3 then return points end

    local result = {}
    for i = 1, count - 1 do
        local p0, p1 = points[math.max(1, i - 1)], points[i]
        local p2, p3 = points[i + 1], points[math.min(count, i + 2)]
        local bend = math.max(bendAngle(p0.pos, p1.pos, p2.pos), bendAngle(p1.pos, p2.pos, p3.pos))
        local parts = math.min(MAX_SUBDIVISIONS, math.max(1, math.ceil(bend / CORNER_STEP), math.ceil(dist2D(p1.pos, p2.pos) / SMOOTH_STEP)))

        result[#result + 1] = p1
        for k = 1, parts - 1 do
            local t = k / parts
            result[#result + 1] = {
                pos = catmullRom(p0.pos, p1.pos, p2.pos, p3.pos, t),
                abs = p1.abs + (p2.abs - p1.abs) * t,
                junction = false,
                zone = p1.zone and p2.zone,
                grounded = true,
            }
        end
    end

    result[#result + 1] = points[count]
    return result
end

local function groundSample(x, y, z)
    local key = math.floor(x * 2.0 + 0.5) * 100000 + math.floor(y * 2.0 + 0.5)
    local cached = groundCache[key]
    if cached then return cached end

    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + GROUND_PROBE, false)
    if not found or math.abs(groundZ - z) > GROUND_SNAP_DELTA then
        groundZ = z
    end

    groundCount = groundCount + 1
    if groundCount > GROUND_CACHE_LIMIT then
        groundCache, groundCount = {}, 1
    end

    groundCache[key] = groundZ
    return groundZ
end

---@param points RoutePoint[]
local function groundPoints(points)
    local count = #points

    for i = 1, count do
        local point = points[i]

        if point.abs >= travel - PROGRESS_BEHIND and point.abs <= travel + GROUND_RANGE then
            local pos = point.pos
            local a, b = points[math.max(1, i - 1)].pos, points[math.min(count, i + 1)].pos
            local dx, dy = b.x - a.x, b.y - a.y
            local length = math.sqrt(dx * dx + dy * dy)

            if length > 0.01 then
                local rx, ry = dy / length * GROUND_FOOTPRINT, -dx / length * GROUND_FOOTPRINT
                local z = math.max(groundSample(pos.x, pos.y, pos.z), groundSample(pos.x + rx, pos.y + ry, pos.z), groundSample(pos.x - rx, pos.y - ry, pos.z))
                point.pos = vector3(pos.x, pos.y, z)
            end
        end
    end
end

---@param points RoutePoint[]
local function measure(points)
    local length

    for i = 1, #points do
        local point = points[i]
        if length then
            length = length + dist2D(points[i - 1].pos, point.pos)
        end

        local source = point.source
        if source then
            if source.len then
                length = source.len
            elseif not length then
                length = source.abs
            end

            if source.relaxedX and not source.len then
                source.len = length
            end
        end

        point.len = length
    end
end

---@param points RoutePoint[]
local function tangents(points)
    local count = #points
    local lastX, lastY, lastZ = 0.0, 1.0, 0.0

    for i = 1, count do
        local a = points[math.max(1, i - TANGENT_REACH)].pos
        local b = points[math.min(count, i + TANGENT_REACH)].pos
        local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
        local flat = math.sqrt(dx * dx + dy * dy)

        if flat > 0.01 then
            dz = math.max(-flat * MAX_PITCH, math.min(flat * MAX_PITCH, dz))
            local length = math.sqrt(flat * flat + dz * dz)
            lastX, lastY, lastZ = dx / length, dy / length, dz / length
        end

        local point = points[i]
        point.dirX, point.dirY, point.dirZ = lastX, lastY, lastZ
    end
end

local function derive()
    local raw = route.raw
    local count = #raw
    local work, from = {}, count + 1

    for i = 1, count do
        local point = raw[i]
        local pos = point.pos

        if point.relaxedX then
            pos = vector3(point.relaxedX, point.relaxedY, pos.z)
        elseif from > count then
            from = i
        end

        work[i] = { pos = pos, abs = point.abs, junction = point.junction, zone = false, grounded = point.grounded, source = point }
    end

    relax(work, from)

    local settled = count > 0 and raw[count].abs - RELAX_SETTLE or 0.0
    for i = from, count do
        if raw[i].abs <= settled then
            raw[i].relaxedX, raw[i].relaxedY = work[i].pos.x, work[i].pos.y
        end
    end

    markZones(work)

    route.turns = detectTurns(work)
    route.points = subdivide(work)
    measure(route.points)
    groundPoints(route.points)
    tangents(route.points)
end

---@param points RoutePoint[]
---@param pos vector3
---@param first? integer
---@param toAbs? number
---@return number
---@return number
---@return integer
---@return number
local function routeProgress(points, pos, first, toAbs)
    local best, bestOffset, bestIndex, bestLength = 0.0, math.huge, 1, 0.0

    for i = first or 1, #points - 1 do
        if toAbs and points[i].abs > toAbs then break end

        local a, b = points[i].pos, points[i + 1].pos
        local abx, aby = b.x - a.x, b.y - a.y
        local length2 = abx * abx + aby * aby

        if length2 > 0.0 then
            local t = ((pos.x - a.x) * abx + (pos.y - a.y) * aby) / length2
            t = math.min(1.0, i == 1 and t or math.max(0.0, t))

            local dx, dy = pos.x - (a.x + abx * t), pos.y - (a.y + aby * t)
            local offset = dx * dx + dy * dy

            if offset < bestOffset then
                bestOffset = offset
                bestIndex = i
                best = points[i].abs + (points[i + 1].abs - points[i].abs) * t
                bestLength = points[i].len + (points[i + 1].len - points[i].len) * t
            end
        end
    end

    return best, math.sqrt(bestOffset), bestIndex, bestLength
end

---@param points RoutePoint[]
---@param pos vector3
---@return number
---@return number
local function trackProgress(points, pos)
    if #points < 2 then return 0.0, math.huge end

    local first = math.min(progressIndex, #points - 1)
    while first > 1 and points[first].abs > travel - PROGRESS_BEHIND do
        first = first - 1
    end

    local progress, offset, index, length = routeProgress(points, pos, first, travel + PROGRESS_AHEAD)
    if offset > OFF_ROUTE then
        progress, offset, index, length = routeProgress(points, pos)
    end

    progressIndex = index
    travelLength = length
    return progress, offset
end

---@param cfg NavigatorSettings
---@param slot integer
---@param destination vector3?
---@param speed number
---@param sameRoute boolean
---@param offRoute boolean
local function rebuild(cfg, slot, destination, speed, sameRoute, offRoute)
    if not textureReady then
        RequestStreamedTextureDict(TEXTURE_DICT, false)
        textureReady = HasStreamedTextureDictLoaded(TEXTURE_DICT)
    end

    if not sameRoute then
        travel = 0.0
        divergence = 0
        route.raw = {}
        route.points = {}
        route.turns = {}
    end

    route.slot = slot
    route.destination = destination
    route.builtAt = GetGameTimer()

    local step = speed >= 55.0 and 9.0 or speed >= 27.0 and 7.5 or 6.0
    local lookahead = math.max(LOOKAHEAD, cfg.distance + 60.0)
    local raw = route.raw
    local replace = #raw < 2 or offRoute
    local candidate, complete

    if replace then
        candidate, complete = sampleCandidate(slot, step, lookahead)
    else
        candidate, complete = sampleCandidate(slot, step, lookahead, STICKY_CHECK, raw[#raw].abs - travel - step)
    end

    if #candidate < 2 then return end

    if not replace then
        if deviation(raw, candidate) > STICKY_TOLERANCE then
            divergence = divergence + 1
            if divergence < 2 then return end
            replace = true
            candidate, complete = sampleCandidate(slot, step, lookahead)
            if #candidate < 2 then return end
        else
            divergence = 0
        end
    end

    if replace then
        divergence = 0
        for i = 1, #candidate do
            prepare(candidate[i])
        end
        route.raw = candidate
    else
        local kept = {}
        local tail = raw[#raw].abs
        local reground = REGROUND_LIMIT

        for i = 1, #raw do
            local point = raw[i]
            if point.abs >= travel - KEEP_BEHIND then
                if not point.grounded and reground > 0 and point.abs <= travel + REGROUND_RANGE then
                    groundPoint(point)
                    reground = reground - 1
                end
                kept[#kept + 1] = point
            end
        end

        for i = 1, #candidate do
            local point = candidate[i]
            if point.abs > tail + 0.5 then
                prepare(point)
                kept[#kept + 1] = point
            end
        end

        route.raw = kept
    end

    route.complete = complete
    derive()
end

local function clearRoute()
    route.slot = nil
    route.destination = nil
    route.raw = {}
    route.points = {}
    route.turns = {}
    route.remaining = nil
    travel = 0.0
    divergence = 0
    groundCache, groundCount = {}, 0
end

local function round10(value)
    return value and math.floor(value / 10.0 + 0.5) * 10
end

local function navigationPayload()
    local last = route.points[#route.points]
    local remaining = route.complete and last and last.abs - travel or GetGpsBlipRouteLength()

    if not remaining or remaining <= 0 then remaining = nil end
    route.remaining = remaining

    local turn
    for i = 1, #route.turns do
        if route.turns[i].endAt > travel then
            turn = route.turns[i]
            break
        end
    end

    local maneuver, distance = 'straight', nil
    if remaining and remaining <= ARRIVE_NOTICE and (not turn or turn.startAt - travel > remaining) then
        maneuver, distance = 'arrive', remaining
    elseif turn then
        maneuver, distance = turn.maneuver, math.max(0.0, turn.startAt - travel)
    end

    return {
        active = true,
        source = route.slot == SLOT_MISSION and 'mission' or 'waypoint',
        maneuver = maneuver,
        distance = round10(distance),
        remaining = round10(remaining),
        eta = remaining and averageSpeed > 2.0 and math.floor(remaining / averageSpeed / 5.0 + 0.5) * 5 or nil,
    }
end

local function sendNavigation(payload)
    local last = lastPayload
    if last and last.active == payload.active and last.source == payload.source and last.maneuver == payload.maneuver
        and last.distance == payload.distance and last.remaining == payload.remaining and last.eta == payload.eta then
        return
    end

    if interface.send({ action = 'updateNavigation', data = payload }) then
        lastPayload = payload
    end
end

---@param cfg NavigatorSettings
---@param color RouteColor
local function drawChevrons(cfg, color)
    local points = route.points
    local limit = math.min(travelLength + cfg.distance, points[#points].len)
    local preset = PRESETS[cfg.preset] and cfg.preset or DEFAULT_PRESET
    local size = cfg.width
    local pitch = size + cfg.spacing
    local flowTotal = cfg.animated and GetGameTimer() * 0.001 * FLOW_SPEED or 0.0
    local flow = flowTotal % pitch
    local shift = math.floor((flowTotal - flow) / pitch + 0.5)
    local highlight = cfg.turnHighlight and parseColor(cfg.turnColor)
    local lift = cfg.lift
    local turns = route.turns
    local turnIndex = 1
    local startIndex = math.min(progressIndex, #points - 1)
    while startIndex > 1 and points[startIndex].len > travelLength do
        startIndex = startIndex - 1
    end
    local index = startIndex
    local at = math.ceil((travelLength - flow) / pitch) * pitch + flow

    local drawn = 0
    local farFade = math.min(FAR_FADE, cfg.distance * 0.2)

    while at <= limit and drawn < MAX_CHEVRONS do
        local ahead = at - travelLength
        local fade = math.min(ahead / NEAR_FADE, (limit - at) / farFade, 1.0)

        if fade > 0.0 and ahead > LOD_TIERS[1] then
            local id = math.floor((at - flow) / pitch + 0.5) - shift
            local stride = 1

            for tier = 1, #LOD_TIERS do
                local start = LOD_TIERS[tier]
                if ahead <= start then break end

                stride = stride * 2
                if id % stride ~= 0 then
                    fade = math.min(fade, 1.0 - (ahead - start) / LOD_BLEND)
                end
            end
        end

        if fade > 0.0 then
            local mx, my, mz, t
            mx, my, mz, index, t = pointAt(points, at, index, 'len')

            local from, to = points[index], points[index + 1]
            local atAbs = from.abs + (to.abs - from.abs) * t

            if from.dirX then
                local red, green, blue, alpha = color.r, color.g, color.b, color.a

                if highlight then
                    while turns[turnIndex] and turns[turnIndex].endAt < atAbs do
                        turnIndex = turnIndex + 1
                    end

                    local turn = turns[turnIndex]
                    local blend = turn and math.max(0.0, math.min(1.0, 1.0 - (turn.startAt - atAbs) / TURN_HIGHLIGHT)) or 0.0

                    if blend > 0.0 then
                        red = red + (highlight.r - red) * blend
                        green = green + (highlight.g - green) * blend
                        blue = blue + (highlight.b - blue) * blend
                        alpha = alpha + (highlight.a - alpha) * blend
                    end
                end

                red, green, blue, alpha = math.floor(red), math.floor(green), math.floor(blue), math.floor(alpha * fade)
                drawn = drawn + 1
                DrawMarker(9, mx, my, mz + lift, from.dirX, from.dirY, from.dirZ, MARKER_ROT_X, 0.0, 0.0, size, size, size, red, green, blue, alpha, false, false, 2, false, TEXTURE_DICT, preset, false)
            end
        end

        at = at + pitch
    end
end

---@param cfg NavigatorSettings
---@param color RouteColor
local function drawPath(cfg, color)
    local points = route.points
    local limit = travel + cfg.distance

    for i = 1, #points - 1 do
        local from, to = points[i], points[i + 1]
        if from.abs >= limit then break end

        if to.abs > travel then
            DrawLine(from.pos.x, from.pos.y, from.pos.z + cfg.lift, to.pos.x, to.pos.y, to.pos.z + cfg.lift, color.r, color.g, color.b, color.a)
        end
    end
end

---@param cfg NavigatorSettings
---@param color RouteColor
---@param origin vector3
local function drawDestination(cfg, color, origin)
    local destination = route.destination
    if not cfg.marker or not destination or dist2D(origin, destination) <= ARRIVE_RADIUS then return end

    DrawMarker(1, destination.x, destination.y, -200.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1200.0, color.r, color.g, color.b, math.floor(color.a * 0.5), false, false, 2, false, nil, nil, false)

    if not route.remaining then return end

    local onScreen, x, y = GetScreenCoordFromWorldCoord(destination.x, destination.y, origin.z + 3.0)
    if not onScreen then return end

    SetTextFont(4)
    SetTextScale(0.0, 0.4)
    SetTextColour(255, 255, 255, 230)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    if route.remaining ~= remainingValue then
        remainingValue = route.remaining
        remainingText = formatDistance(route.remaining)
    end

    AddTextComponentSubstringPlayerName(remainingText)
    EndTextCommandDisplayText(x, y)
end

CreateThread(function()
    while true do
        local wait = 1000
        local cfg = SM_HUD.settings.navigator
        local traveler = cfg and cfg.enabled and playerState.isLoggedIn and travelerOf(cfg)
        local slot, destination

        if traveler then
            slot, destination = selectRoute(cfg)
        end

        activeTraveler = slot and traveler or nil

        if slot then
            wait = 250

            local origin = GetEntityCoords(traveler)
            local speed = GetEntitySpeed(traveler)
            local offset

            averageSpeed = averageSpeed + (speed - averageSpeed) * 0.25
            travel, offset = trackProgress(route.points, origin)

            local sameRoute = slot == route.slot and sameDestination(destination, route.destination)
            local offRoute = offset > OFF_ROUTE

            if not sameRoute or offRoute or GetGameTimer() - route.builtAt >= REBUILD_INTERVAL then
                rebuild(cfg, slot, destination, speed, sameRoute, offRoute)
                travel = trackProgress(route.points, origin)
            end

            if cfg.autoClear and route.slot == SLOT_WAYPOINT and route.destination and dist2D(origin, route.destination) <= ARRIVE_RADIUS then
                SetWaypointOff()
                clearRoute()
            end

            sendNavigation(route.slot and #route.points > 1 and navigationPayload() or { active = false })
        else
            if route.slot then clearRoute() end
            sendNavigation({ active = false })
        end

        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        local wait = 250
        local cfg = SM_HUD.settings.navigator

        if route.slot and #route.points > 1 and cfg and cfg.enabled and SM_HUD.visible and not SM_HUD.blackBarsActive and not IsPauseMenuActive() then
            local traveler = activeTraveler
            if traveler then
                wait = 0

                local origin = GetEntityCoords(traveler)
                local color = parseColor(route.slot == SLOT_MISSION and cfg.missionColor or cfg.color)

                travel = trackProgress(route.points, origin)

                if textureReady then
                    drawChevrons(cfg, color)
                else
                    drawPath(cfg, color)
                end

                drawDestination(cfg, color, origin)
            end
        end

        Wait(wait)
    end
end)

local function round2(value)
    return math.floor(value * 100.0 + 0.5) / 100.0
end

local recording = false

local function gpsSamples(fromPlayer, slot)
    local samples = {}
    for distance = 0, 150, 3 do
        local ok, pos = GetPosAlongGpsTypeRoute(fromPlayer, distance + 0.0, slot)
        if not ok then break end
        samples[#samples + 1] = { round2(pos.x), round2(pos.y) }
    end
    return samples
end

-- RegisterCommand('navdump', function()
--     if recording then return end
--     recording = true

--     CreateThread(function()
--         local frames = {}
--         print('navdump: merekam 15 detik')

--         for _ = 1, 30 do
--             local traveler = travelerOf(SM_HUD.settings.navigator or {}) or cache.ped
--             local origin = GetEntityCoords(traveler)
--             local slot = route.slot or SLOT_WAYPOINT
--             local drawn = {}

--             for i = 1, #route.points do
--                 local point = route.points[i]
--                 if point.abs >= travel - 5.0 and point.abs <= travel + 150.0 then
--                     drawn[#drawn + 1] = { round2(point.pos.x), round2(point.pos.y), round2(point.abs) }
--                 end
--             end

--             frames[#frames + 1] = {
--                 t = GetGameTimer(),
--                 player = { round2(origin.x), round2(origin.y), round2(GetEntityHeading(traveler)) },
--                 travel = round2(travel),
--                 gps = gpsSamples(true, slot),
--                 gpsStart = gpsSamples(false, slot),
--                 drawn = drawn,
--             }

--             Wait(500)
--         end

--         lib.setClipboard(json.encode(frames))
--         print(('navdump: %d frame disalin ke clipboard'):format(#frames))
--         recording = false
--     end)
-- end, false)
