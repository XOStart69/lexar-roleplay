local config = localmodule 'config.shared'
local anims = localmodule 'modules.anims'

local Wait = Wait
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResultEx = GetShapeTestResultEx
local PlaySoundFromCoord = PlaySoundFromCoord
local ApplyImpulseToCloth = ApplyImpulseToCloth
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords

local gravity = config.gravity
local drag = config.drag
local rollingResistance = config.rollingResistance
local energyLoss = config.groundBounceEnergyLoss
local elasticity = config.ballElasticity
local stopThreshold = config.stopHorizontalBounceThreshold

local hitDelay = anims.hitDelay
local distOffset = anims.distOffset
local hitSides = anims.sides
local hitDistances = anims.distances

local SHAPETEST_FLAGS = 19
local NET_MATERIAL = 122789469
local CLAY_MATERIAL = 125958708
local FIXED_STEP = 1 / 60
local ZERO = vec3(0.0, 0.0, 0.0)

local NET_CLEARANCE = 1.05

local physics = {
    NET_MATERIAL = NET_MATERIAL,
}

---@param height number
---@param horizontal number
---@param vertical number
---@param toNet number
---@param gz number
---@return number distance
---@return number netHeight
local function flight(height, horizontal, vertical, toNet, gz)
    local x, z, ux, uz = 0.0, height, horizontal, vertical
    local netHeight

    for _ = 1, 360 do
        uz += gz * FIXED_STEP
        ux -= ux * drag * FIXED_STEP
        uz -= uz * drag * FIXED_STEP

        local nx, nz = x + ux * FIXED_STEP, z + uz * FIXED_STEP

        if not netHeight and x < toNet and nx >= toNet then
            netHeight = z + (nz - z) * (toNet - x) / (nx - x)
        end

        x, z = nx, nz

        if z <= 0.0 then break end
    end

    return x, netHeight or z
end

---@param height number
---@param toNet number
---@param total number
---@param speed number
---@param spin string
---@return number horizontal
---@return number vertical
function physics.solveShot(height, toNet, total, speed, spin)
    local gz = (gravity[spin] or gravity.normal).z
    local vertical = 0.0

    for _ = 1, 8 do
        local lo, hi = -10.0, 15.0

        for _ = 1, 24 do
            local mid = (lo + hi) / 2
            if flight(height, speed, mid, toNet, gz) < total then
                lo = mid
            else
                hi = mid
            end
        end

        vertical = (lo + hi) / 2

        local _, netHeight = flight(height, speed, vertical, toNet, gz)
        if netHeight >= NET_CLEARANCE then break end

        speed *= 0.88
    end

    return speed, vertical
end

---@param coords vector3
---@param velocity vector3
local function playNetEffect(coords, velocity, speed, isNet)
    if isNet then
        PlaySoundFromCoord(-1, 'TENNIS_NET_BALL_MEDIUM_MASTER', coords.x, coords.y, coords.z, 0, false, 0, true)
    end

    if speed <= 0 then return end

    local impulse = (velocity / speed) * 0.5
    for i = -6, 6 do
        local clothPos = coords - impulse * i / 20
        ApplyImpulseToCloth(clothPos.x, clothPos.y, clothPos.z, impulse.x, impulse.y, impulse.z, 2.0)
    end
end

---@param dt number
---@param spin string
---@param pos vector3
---@param vel vector3
---@param groundZ number
---@param collide boolean
---@param playSound boolean?
---@return vector3 pos
---@return vector3 vel
---@return vector3? hitCoords
---@return number? material
function physics.step(dt, spin, pos, vel, groundZ, collide, playSound)
    local speed = #vel

    if speed < 0.04 then
        return pos, ZERO
    end

    local nearGround = pos.z - groundZ < 0.01

    if nearGround then
        vel = vel - (vel * rollingResistance) * dt
    else
        vel = vel + gravity[spin] * dt
        vel = vel - (vel * drag) * dt
    end

    local nextPos = pos + vel * dt

    if not collide then
        return nextPos, vel
    end

    local handle = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, nextPos.x, nextPos.y, nextPos.z, SHAPETEST_FLAGS, 0, 0)
    local _, hit, hitCoords, normal, material = GetShapeTestResultEx(handle)

    if hit ~= 1 then
        return nextPos, vel
    end

    local isNet = material == NET_MATERIAL
    if isNet then
        if playSound then
            playNetEffect(pos, vel, speed, true)
        end
        return nextPos, vel
    end

    speed = #vel

    if playSound then
        if material == CLAY_MATERIAL then
            playNetEffect(pos, vel, speed, false)
        elseif speed > 1.5 then
            PlaySoundFromCoord(-1, 'TENNIS_CLS_BALL_MASTER', pos.x, pos.y, pos.z, 0, false, 0, true)
        end
    end

    if speed <= 0 then
        return pos, ZERO, hitCoords, material
    end

    local reflected = vel - (2 * vel) * (normal * normal) * elasticity
    local reflectedSpeed = #reflected
    local bounce = reflectedSpeed > 0 and (reflected / reflectedSpeed) * speed * energyLoss or ZERO
    local hitFraction = #(pos - hitCoords) / speed * dt

    if nearGround and bounce.z <= stopThreshold then
        local bounceSpeed = #bounce
        local zFactor = bounceSpeed > 0 and bounce.z / bounceSpeed or 0.0
        bounce = vec3(bounce.x + zFactor / 2, bounce.y + zFactor / 2, 0.0)
        pos = vec3(pos.x, pos.y, groundZ)
    end

    pos = pos + (vel * dt) * hitFraction + (bounce * dt) * (1.0 - hitFraction)

    return pos, bounce, hitCoords, material
end

---@param spin string
---@param pos vector3
---@param vel vector3
---@param groundZ number
---@return vector3?
function physics.firstGroundHit(spin, pos, vel, groundZ)
    local budget = 10

    for _ = 1, 240 do
        budget -= 1
        if budget <= 0 then
            Wait(0)
            budget = 10
        end

        local hitCoords
        pos, vel, hitCoords = physics.step(FIXED_STEP, spin, pos, vel, groundZ, true)

        if hitCoords then
            if hitCoords.z - groundZ < 0.05 then
                return hitCoords
            end
            spin = 'normal'
        end

        if #vel == 0.0 then
            return nil
        end
    end

    return nil
end

local predicted = {}

---@param ped number
---@param spin string
---@param pos vector3
---@param vel vector3
---@param groundZ number
---@return string? side
---@return string? distance
---@return vector3? pos
function physics.predictHit(ped, spin, pos, vel, groundZ)
    local maxDelay = hitDelay.dive
    local elapsed = 0.0
    local stepMs = FIXED_STEP * 1000
    local distCount = #hitDistances

    for i = 1, distCount do
        predicted[hitDistances[i]] = false
    end

    while elapsed < maxDelay do
        local hitCoords
        pos, vel, hitCoords = physics.step(FIXED_STEP, spin, pos, vel, groundZ, true)
        if hitCoords then
            spin = 'normal'
        end

        elapsed += stepMs

        for i = 1, distCount do
            local key = hitDistances[i]
            if not predicted[key] and elapsed >= hitDelay[key] then
                predicted[key] = pos
            end
        end
    end

    local bestDist, bestPos, bestSide, bestDistance

    for s = 1, #hitSides do
        local side = hitSides[s]
        local offsets = distOffset[side]

        for d = 1, distCount do
            local key = hitDistances[d]
            local target = predicted[key]
            local offset = offsets[key]
            local coords = GetOffsetFromEntityInWorldCoords(ped, offset.x, offset.y, 0.0)
            local distance = #(coords - target)

            if (not bestDist or bestDist > distance) and (key ~= 'dive' or distance < 3.0) then
                bestDist = distance
                bestPos = target
                bestSide = side
                bestDistance = key
            end
        end
    end

    return bestSide, bestDistance, bestPos
end

return physics
