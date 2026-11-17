local Wait = Wait
local IsControlPressed = IsControlPressed
local IsPedSprinting = IsPedSprinting
local IsPedJumping = IsPedJumping
local IsPedClimbing = IsPedClimbing
local IsPedSwimming = IsPedSwimming
local GetPlayerSprintStaminaRemaining = GetPlayerSprintStaminaRemaining
local RestorePlayerStamina = RestorePlayerStamina

local SPRINT_CONTROL = 21

local lastUsed = 0

---@param ped number
---@return boolean
local function isActuallySprinting(ped)
    return IsPedSprinting(ped) or IsPedJumping(ped) or IsPedClimbing(ped) or IsPedSwimming(ped)
end

CreateThread(function()
    while true do
        local sleep = 500
        local playerId = cache.playerId
        local used = GetPlayerSprintStaminaRemaining(playerId)

        if not cache.vehicle and IsControlPressed(0, SPRINT_CONTROL) then
            sleep = 100

            if used > lastUsed and not isActuallySprinting(cache.ped) then
                RestorePlayerStamina(playerId, (used - lastUsed) / 100)
                used = lastUsed
            end
        end

        lastUsed = used
        Wait(sleep)
    end
end)
