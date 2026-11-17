local damage = localmodule 'data.damage'

local SetWeaponDamageModifier = SetWeaponDamageModifier
local DisableControlAction = DisableControlAction
local GetPedStealthMovement = GetPedStealthMovement
local SetPedStealthMovement = SetPedStealthMovement
local GetGameTimer = GetGameTimer
local Wait = Wait

local STEALTH_CHECK_MS = 500
local INPUT_DUCK = 36

CreateThread(function()
    for hash, modifier in pairs(damage) do
        SetWeaponDamageModifier(hash, modifier)
    end
end)

CreateThread(function()
    local nextStealthCheck = 0

    while true do
        DisableControlAction(0, INPUT_DUCK, true)

        local now = GetGameTimer()
        if now >= nextStealthCheck then
            nextStealthCheck = now + STEALTH_CHECK_MS
            local ped = cache.ped
            if GetPedStealthMovement(ped) then
                SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
            end
        end

        Wait(0)
    end
end)
