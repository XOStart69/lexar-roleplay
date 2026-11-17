local config = localmodule 'config.shared'

local MALE = config.illegalMask.male
local FEMALE = config.illegalMask.female
local FEMALE_MODEL = `mp_f_freemode_01`

local GetEntityModel = GetEntityModel
local GetPedDrawableVariation = GetPedDrawableVariation
local GetPedTextureVariation = GetPedTextureVariation
local SetPedComponentVariation = SetPedComponentVariation

local saved = nil

local function wearMask()
    local ped = cache.ped

    if not saved then
        saved = { GetPedDrawableVariation(ped, 1), GetPedTextureVariation(ped, 1) }
    end

    SetPedComponentVariation(ped, 1, GetEntityModel(ped) == FEMALE_MODEL and FEMALE or MALE, 0, 2)
end

local function removeMask()
    if not saved then return end

    SetPedComponentVariation(cache.ped, 1, saved[1], saved[2], 2)
    saved = nil
end

AddStateBagChangeHandler('illegalGasMask', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value then
        wearMask()
    else
        removeMask()
    end
end)
