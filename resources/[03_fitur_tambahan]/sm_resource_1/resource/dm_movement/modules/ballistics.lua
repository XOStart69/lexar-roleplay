local config = localmodule 'config.shared'
local Util = localmodule 'modules.util'

local Ballistics = {
    blocked = false,
    contact = nil
}

local mathMax = math.max

local nextEvaluate = 0

---@param ped number
---@return vector3
local function getMuzzleCoords(ped)
    local weaponEntity = GetCurrentPedWeaponEntityIndex(ped)

    if weaponEntity and weaponEntity ~= 0 and DoesEntityExist(weaponEntity) then
        local boneIndex = GetEntityBoneIndexByName(weaponEntity, 'gun_muzzle')

        if boneIndex ~= -1 then
            return GetWorldPositionOfEntityBone(weaponEntity, boneIndex)
        end

        return GetOffsetFromEntityInWorldCoords(weaponEntity, 0.0, 0.45, 0.0)
    end

    return GetPedBoneCoords(ped, 28422, 0.0, 0.0, 0.0) + Util.Forward(GetEntityHeading(ped)) * 0.35
end

---@param ped number
---@return boolean blocked
---@return vector3? contact
function Ballistics.Evaluate(ped)
    local ballistics = config.ballistics

    if not ballistics.enabled or not IsPedArmed(ped, 4) then
        return false
    end

    local camCoord = GetFinalRenderedCamCoord()
    local camRot = GetFinalRenderedCamRot(2)
    local camEnd = camCoord + Util.Direction(camRot) * ballistics.maxRange

    local hit, hitCoord = Util.Ray(camCoord, camEnd, ped, ballistics.probeFlags)
    local targetCoord = (hit and hitCoord) or camEnd

    local muzzleCoord = getMuzzleCoords(ped)
    local muzzleHit, muzzleHitCoord = Util.Ray(muzzleCoord, targetCoord, ped, ballistics.probeFlags)

    if not muzzleHit then
        return false
    end

    return #(muzzleHitCoord - muzzleCoord) <= ballistics.coverRange, muzzleHitCoord
end

---@param ped number
---@return boolean
function Ballistics.Enforce(ped)
    local now = GetGameTimer()

    if now >= nextEvaluate then
        nextEvaluate = now + config.ballistics.interval

        local isBlocked, contactCoord = Ballistics.Evaluate(ped)

        Ballistics.blocked = isBlocked
        Ballistics.contact = contactCoord
    end

    if not Ballistics.blocked then
        return false
    end

    DisableControlAction(0, 24, true)
    DisableControlAction(0, 257, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)

    return true
end

function Ballistics.Indicator()
    local ballistics = config.ballistics

    if not ballistics.indicator or not Ballistics.blocked then
        return
    end

    local contact = Ballistics.contact

    if not contact then
        return
    end

    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(contact.x, contact.y, contact.z)

    if not onScreen then
        return
    end

    local distance = #(GetFinalRenderedCamCoord() - contact)
    local scale = Util.Clamp((ballistics.indicatorSize * 4.0) / mathMax(1.0, distance), 0.18, ballistics.indicatorSize)

    SetTextFont(0)
    SetTextScale(0.0, scale)
    SetTextColour(235, 60, 60, 235)
    SetTextDropShadow()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentSubstringPlayerName('x')
    DrawText(screenX, screenY - scale * 0.028)
end

function Ballistics.Clear()
    Ballistics.blocked = false
    Ballistics.contact = nil
    nextEvaluate = 0
end

return Ballistics
