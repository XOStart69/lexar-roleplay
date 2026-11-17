local reporting = false

---@param ped integer
---@return integer|false killerServerId
---@return string killerKind
local function resolveKiller(ped)
    local killerEntity = GetPedSourceOfDeath(ped)
    if not killerEntity or killerEntity == 0 or not DoesEntityExist(killerEntity) then
        return false, 'none'
    end

    local killerPed = killerEntity

    if IsEntityAVehicle(killerEntity) then
        local driver = GetPedInVehicleSeat(killerEntity, -1)
        if not driver or driver == 0 or not DoesEntityExist(driver) then
            return false, 'vehicle'
        end
        killerPed = driver
    elseif not IsEntityAPed(killerEntity) then
        return false, 'object'
    end

    if killerPed == ped then
        return false, 'self'
    end

    if not IsPedAPlayer(killerPed) then
        return false, 'npc'
    end

    local killerPlayer = NetworkGetPlayerIndexFromPed(killerPed)
    if killerPlayer == -1 then
        return false, 'player'
    end

    local sid = GetPlayerServerId(killerPlayer)
    if not sid or sid == 0 then
        return false, 'player'
    end

    return sid, 'player'
end

local function reportDeath()
    local ped = cache.ped
    local killer, kind = resolveKiller(ped)
    TriggerTokenEvent('sm_guard:death', killer, GetPedCauseOfDeath(ped) or 0, kind)
    reporting = false
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' or reporting then return end

    local ped = cache.ped
    if args[1] ~= ped then return end
    if not IsEntityDead(ped) and not IsPedFatallyInjured(ped) then return end

    reporting = true
    SetTimeout(50, reportDeath)
end)
