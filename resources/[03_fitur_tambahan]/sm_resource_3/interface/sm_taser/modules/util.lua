local GetAnimDuration = GetAnimDuration
local TaskPlayAnim = TaskPlayAnim
local IsEntityPlayingAnim = IsEntityPlayingAnim
local StopAnimTask = StopAnimTask
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetPedBoneIndex = GetPedBoneIndex
local DoesEntityExist = DoesEntityExist
local pcall = pcall

local HAND_BONE = 57005
local MUZZLE_FX = (localmodule 'config').muzzleFx

local util = {}
local animCache = {}

---@param list { dict: string, clip: string }[]
---@return { dict: string, clip: string }|false
function util.findAnim(list)
    local cached = animCache[list]
    if cached ~= nil then return cached end

    local found = false

    for i = 1, #list do
        local anim = list[i]

        if pcall(lib.requestAnimDict, anim.dict, 2000) and GetAnimDuration(anim.dict, anim.clip) > 0.0 then
            found = anim
            break
        end
    end

    animCache[list] = found

    return found
end

---@param ped number
---@param list { dict: string, clip: string }[]
---@param flag integer
---@return { dict: string, clip: string }|false
function util.playAnim(ped, list, flag)
    local anim = util.findAnim(list)

    if anim then
        TaskPlayAnim(ped, anim.dict, anim.clip, 4.0, -4.0, -1, flag, 0.0, false, false, false)
    end

    return anim
end

---@param ped number
---@param anim { dict: string, clip: string }|false|nil
function util.stopAnim(ped, anim)
    if anim and IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
        StopAnimTask(ped, anim.dict, anim.clip, 2.0)
    end
end

---@param ped number
---@return vector3
function util.muzzle(ped)
    local weapon = GetCurrentPedWeaponEntityIndex(ped)

    if weapon ~= 0 and DoesEntityExist(weapon) then
        local bone = GetEntityBoneIndexByName(weapon, 'gun_muzzle')

        if bone ~= -1 then
            return GetWorldPositionOfEntityBone(weapon, bone)
        end
    end

    return GetWorldPositionOfEntityBone(ped, GetPedBoneIndex(ped, HAND_BONE))
end

---@param coords vector3
function util.muzzleFlash(coords)
    local fx = MUZZLE_FX

    if not fx or not HasNamedPtfxAssetLoaded(fx.asset) then
        if fx then RequestNamedPtfxAsset(fx.asset) end
        return
    end

    UseParticleFxAssetNextCall(fx.asset)
    StartParticleFxNonLoopedAtCoord(fx.name, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, fx.scale, false, false, false)
end

return util
