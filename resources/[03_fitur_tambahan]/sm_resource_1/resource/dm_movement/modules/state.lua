local config = localmodule 'config.shared'
local Util = localmodule 'modules.util'

local State = {
    enabled = true,
    ped = 0,
    traversing = false,
    needsGround = false,
    lastTraversal = -10000,
    nextGroundScan = 0,
    ground = nil,
    rootHeight = 1.0,
    token = 0,
    Lean = nil
}

function State.Available(ped)
    if not State.enabled or not DoesEntityExist(ped) or IsEntityDead(ped) then
        return false
    end

    if not IsPedOnFoot(ped) or IsPedInAnyVehicle(ped, true) then
        return false
    end

    if IsPedRagdoll(ped) or IsPedSwimming(ped) or IsPedGettingUp(ped) or IsPedCuffed(ped) or IsPedBeingStunned(ped, 0) then
        return false
    end

    return true
end

function State.Aiming()
    if IsPlayerFreeAiming(PlayerId()) then
        return true
    end

    local Lean = State.Lean

    if Lean and Lean.CameraActive() and IsControlPressed(0, 25) then
        return true
    end

    return false
end

function State.UpdateGround(ped)
    if State.traversing then
        return
    end

    if IsEntityInAir(ped) or IsPedJumping(ped) or IsPedFalling(ped) then
        return
    end

    if IsPedClimbing(ped) or IsPedVaulting(ped) then
        return
    end

    local now = GetGameTimer()

    if not State.needsGround and now < State.nextGroundScan then
        return
    end

    State.nextGroundScan = now + config.traversal.groundInterval

    local coords = GetEntityCoords(ped)
    local hit, hitCoords = Util.Ray(coords + vec3(0.0, 0.0, 0.5), coords - vec3(0.0, 0.0, 1.5), ped)

    if hit then
        State.ground = hitCoords
        State.rootHeight = Util.Clamp(coords.z - hitCoords.z, 0.0, 1.15)
        State.needsGround = false
    end
end

function State.CanTraverse(ped)
    if not config.traversal.enabled then
        return false
    end

    return State.Available(ped) and not State.traversing
end

---@param ped number
---@param available? boolean
---@return boolean
function State.CanLean(ped, available)
    local lean = config.lean

    if available == nil then
        available = State.Available(ped)
    end

    if not lean.enabled or not available or IsPauseMenuActive() then
        return false
    end

    if State.traversing or IsPedClimbing(ped) or IsPedVaulting(ped) then
        return false
    end

    if IsEntityInAir(ped) or IsPedJumping(ped) or IsPedFalling(ped) then
        return false
    end

    if IsPedReloading(ped) or not IsPedArmed(ped, 4) then
        return false
    end

    if not lean.allowWhileSprinting and IsPedSprinting(ped) then
        return false
    end

    if lean.requireAiming and not State.Aiming() then
        return false
    end

    return true
end

return State
