---@param key string
---@param default number
---@return number
local function getMeta(key, default)
    local meta = QBPlayerData.metadata
    if not meta then return default end
    local val = meta[key]
    return (type(val) == 'number') and math.max(0, math.min(100, val)) or default
end

local oxygen  = 100
local stamina = 100

local function statusTick()
    if not playerState.isLoggedIn then
        return 2000
    end

    local health = math.max(0, GetEntityHealth(cache.ped) - 100)
    local armor = math.max(0, math.min(100, GetPedArmour(cache.ped)))

    local hunger = getMeta('hunger', 100)
    local thirst = getMeta('thirst', 100)
    local stress = getMeta('stress', 0)
    local gymLevel = getMeta('gym', 0)

    if IsEntityInWater(cache.ped) and IsPedSwimmingUnderWater(cache.ped) then
        stamina = 100
        oxygen = GetPlayerUnderwaterTimeRemaining(cache.playerId) * 10
    else
        oxygen = 100
        stamina = 100 - GetPlayerSprintStaminaRemaining(cache.playerId)
    end

    interface.send({
        action = 'updateStatus',
        data = {
            health = health,
            armor = armor,
            hunger = hunger,
            thirst = thirst,
            stress = stress,
            stamina = stamina,
            swimStamina = oxygen,
            gymLevel = gymLevel,
            custom = {},
        },
    })

    return 800
end

CreateThread(function()
    while true do
        Wait(statusTick())
    end
end)
