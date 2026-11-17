local config = localmodule 'config'
local util = localmodule 'modules.util'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetFrameCount = GetFrameCount
local DrawLine = DrawLine
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetEntityHeightAboveGround = GetEntityHeightAboveGround
local GetPedBoneCoords = GetPedBoneCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetSelectedPedWeapon = GetSelectedPedWeapon
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local msqrt = math.sqrt
local mmin = math.min
local mmax = math.max
local next = next
local pairs = pairs

local WEAPON_HASH = joaat(config.weapon)
local WIRE = config.wire
local SEGMENTS = WIRE.segments
local SLACK = WIRE.slack
local MAX_SAG = WIRE.maxSag
local DRAW_DISTANCE = WIRE.drawDistance
local WIRE_LENGTH = config.wireLength
local R, G, B, A = WIRE.color[1], WIRE.color[2], WIRE.color[3], WIRE.color[4]

local wire = {}
local probes = {}
local shooters = {}
local drawing = false

---@param sx number
---@param sy number
---@param sz number
---@param ex number
---@param ey number
---@param ez number
---@param length number
---@param startFloor number
---@param endFloor number
local function drawWire(sx, sy, sz, ex, ey, ez, length, startFloor, endFloor)
    local dx, dy, dz = ex - sx, ey - sy, ez - sz
    local distance = msqrt(dx * dx + dy * dy + dz * dz)
    local sag = mmin(msqrt(0.375 * distance * mmax(length - distance, 0.0)), MAX_SAG) * 4.0
    local px, py, pz = sx, sy, sz

    for i = 1, SEGMENTS do
        local t = i / SEGMENTS
        local x = sx + dx * t
        local y = sy + dy * t
        local z = sz + dz * t - sag * t * (1.0 - t)

        if i < SEGMENTS then
            local floor = startFloor + (endFloor - startFloor) * t + 0.02

            if z < floor then
                z = floor
            end
        end

        DrawLine(px, py, pz, x, y, z, R, G, B, A)
        px, py, pz = x, y, z
    end
end

---@param entity number
---@return number
local function floorOf(entity)
    return GetEntityCoords(entity).z - GetEntityHeightAboveGround(entity)
end

---@param serverId number
---@param frame integer
---@return table?
local function shooterState(serverId, frame)
    local state = shooters[serverId]

    if not state then
        state = { frame = -1 }
        shooters[serverId] = state
    end

    if state.frame == frame then
        return state.valid and state or nil
    end

    state.frame = frame
    state.valid = false

    local player = GetPlayerFromServerId(serverId)
    if player == -1 then return end

    local ped = GetPlayerPed(player)
    if ped == 0 or GetSelectedPedWeapon(ped) ~= WEAPON_HASH then return end

    state.valid = true
    state.muzzle = util.muzzle(ped)
    state.floor = floorOf(ped)

    return state
end

local function drawLoop()
    while next(probes) do
        local now = GetGameTimer()
        local frame = GetFrameCount()
        local cam = GetFinalRenderedCamCoord()

        for id, probe in pairs(probes) do
            local remove = now >= probe.expiresAt
            local shooter = not remove and shooterState(probe.shooter, frame)

            if not shooter then
                remove = true
            end

            local px, py, pz, floor

            if not remove and probe.target then
                local entity = NetworkDoesNetworkIdExist(probe.target) and NetworkGetEntityFromNetworkId(probe.target) or 0

                if entity == 0 or not DoesEntityExist(entity) then
                    remove = true
                else
                    local bone = GetPedBoneCoords(entity, probe.bone, 0.0, 0.0, 0.0)
                    px, py, pz = bone.x, bone.y, bone.z
                    floor = floorOf(entity)
                end
            elseif not remove then
                local point = probe.point
                px, py, pz = point.x, point.y, point.z
                floor = pz
            end

            if not remove then
                local muzzle = shooter.muzzle
                local dx, dy, dz = px - muzzle.x, py - muzzle.y, pz - muzzle.z
                local distance = msqrt(dx * dx + dy * dy + dz * dz)

                if distance > WIRE_LENGTH then
                    remove = true
                elseif #(muzzle - cam) <= DRAW_DISTANCE then
                    probe.length = mmin(mmax(probe.length or distance * (1.0 + SLACK), distance), WIRE_LENGTH)
                    drawWire(muzzle.x, muzzle.y, muzzle.z, px, py, pz, probe.length, shooter.floor, floor)
                end
            end

            if remove then
                probes[id] = nil
            end
        end

        Wait(0)
    end

    for serverId in pairs(shooters) do
        shooters[serverId] = nil
    end

    drawing = false
end

---@param shooter number
---@param list table[]
function wire.add(shooter, list)
    local now = GetGameTimer()

    for i = 1, #list do
        local probe = list[i]

        probes[probe.id] = {
            shooter = shooter,
            target = probe.target,
            bone = probe.bone,
            point = probe.point,
            expiresAt = now + (probe.ttl or 0),
        }
    end

    if not drawing and next(probes) then
        drawing = true
        CreateThread(drawLoop)
    end
end

function wire.clear()
    for id in pairs(probes) do
        probes[id] = nil
    end
end

return wire
