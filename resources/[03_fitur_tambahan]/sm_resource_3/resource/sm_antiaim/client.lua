local UNARMED = `WEAPON_UNARMED`
local GROUP_SNIPER = `GROUP_SNIPER`
local MAX_LOCKON = 500.0

---@param ped number
---@param weapon number|false?
local function applyLockon(ped, weapon)
    local playerId = cache.playerId

    if weapon and weapon ~= 0 and weapon ~= UNARMED then
        local farLockon = GetLockonDistanceOfCurrentPedWeapon(ped) > MAX_LOCKON

        if farLockon and GetWeapontypeGroup(weapon) ~= GROUP_SNIPER then
            SetPlayerLockon(playerId, false)
            SetPlayerLockonRangeOverride(playerId, -1.0)
            return
        end
    end

    SetPlayerLockon(playerId, true)
    SetPlayerLockonRangeOverride(playerId, 0.0)
end

---@param ped number
local function initialize(ped)
    if not ped then return end

    SetPlayerTargetingMode(3)
    SetPedConfigFlag(ped, 43, true)
    applyLockon(ped, cache.weapon)
end

initialize(cache.ped)

lib.onCache('ped', initialize)

lib.onCache('weapon', function(weapon)
    local ped = cache.ped
    if not ped then return end

    applyLockon(ped, weapon)
end)
