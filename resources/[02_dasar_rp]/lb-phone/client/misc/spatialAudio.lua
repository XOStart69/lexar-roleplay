local function rotateVector(pos, rot)
    local radX = math.rad(rot.x)
    local radY = math.rad(rot.y)
    local radZ = math.rad(rot.z)
    local cosX = math.cos(radX)
    local sinX = math.sin(radX)
    local cosY = math.cos(radY)
    local sinY = math.sin(radY)
    local cosZ = math.cos(radZ)
    local sinZ = math.sin(radZ)

    local x1 = pos.x * cosZ - pos.y * sinZ
    local y1 = pos.x * sinZ + pos.y * cosZ
    local z1 = pos.z

    local y2 = y1 * cosX - z1 * sinX
    local z2 = y1 * sinX + z1 * cosX

    local x3 = x1 * cosY + z2 * sinY
    local z3 = -x1 * sinY + z2 * cosY

    return vector3(x3, y2, z3)
end

function CalculateSpatialAudio(listenerPos, listenerRot, sourcePos, maxDistance, volume)
    volume = math.clamp(volume or 1.0, 0.0, 1.0)

    local direction = sourcePos - listenerPos
    local distance = #direction

    if maxDistance <= distance then
        return {
            frontLeft = 0.0,
            frontRight = 0.0,
            rearLeft = 0.0,
            rearRight = 0.0
        }
    end

    local rotated = rotateVector(direction, vector3(-listenerRot.x, -listenerRot.y, -listenerRot.z))
    local localDir = norm(vector2(rotated.x, rotated.y))

    local right = (localDir.x + 1.0) * 0.5
    local front = (localDir.y + 1.0) * 0.5
    local left = 1.0 - right
    local rear = 1.0 - front

    local channels = {
        frontLeft = front * left,
        frontRight = front * right,
        rearLeft = rear * left,
        rearRight = rear * right
    }

    local magnitude = channels.frontLeft ^ 2 + channels.frontRight ^ 2 + channels.rearLeft ^ 2 + channels.rearRight ^ 2

    if magnitude > 0 then
        local scale = 1.0 / math.sqrt(magnitude)
        channels.frontLeft = channels.frontLeft * scale
        channels.frontRight = channels.frontRight * scale
        channels.rearLeft = channels.rearLeft * scale
        channels.rearRight = channels.rearRight * scale
    end

    local falloff = math.clamp((1.0 - distance / maxDistance) ^ 2, 0.0, 1.0) * volume

    return {
        frontLeft = channels.frontLeft * falloff,
        frontRight = channels.frontRight * falloff,
        rearLeft = channels.rearLeft * falloff,
        rearRight = channels.rearRight * falloff
    }
end
