local config = localmodule 'config.shared'

local masks = config.masks

local GetEntityModel = GetEntityModel
local GetPedDrawableVariation = GetPedDrawableVariation
local GetGameTimer = GetGameTimer

local MASK_CACHE_TTL = 1000

local override = false
local maskCached = false
local maskCheckedAt = 0

local protection = {}

function protection.setOverride(value)
    override = value
end

local function isWearingScriptedMask()
    local now = GetGameTimer()

    if now - maskCheckedAt < MASK_CACHE_TTL then
        return maskCached
    end

    maskCheckedAt = now

    local ok, wearing = pcall(function()
        return exports['sm_resource']:isWearingGasMask()
    end)

    maskCached = ok and wearing == true

    return maskCached
end

function protection.isImmune(grenade)
    if override or playerState.illegalGasMask or isWearingScriptedMask() then return true end

    local byModel = masks[grenade]
    local components = byModel and byModel[GetEntityModel(cache.ped)]
    if not components then return false end

    for slot, drawables in pairs(components) do
        local current = GetPedDrawableVariation(cache.ped, slot)

        for i = 1, #drawables do
            if drawables[i] == current then return true end
        end
    end

    return false
end

return protection
