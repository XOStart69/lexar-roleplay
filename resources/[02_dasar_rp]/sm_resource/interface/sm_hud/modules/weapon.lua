local IsPedShooting = IsPedShooting
local playerState = LocalPlayer.state

local shootCount = 0
local function shootingThread()
    CreateThread(function ()
        while cache.weapon do
            if IsPedShooting(cache.ped) and not playerState.pvpMatch then
                shootCount += 1
                if shootCount >= 5 then
                    shootCount = 0
                    TriggerTokenEvent('sm_hud:server:addStress', 1)
                end
            end
            Wait(0)
        end
    end)
end

local function weaponThread()
    CreateThread(function ()
        while cache.weapon do
            Wait(250)

            local pedWeapon = cache.weapon
            local ammoName = SM_HUD.weaponAmmo[pedWeapon]
            local bool, ammoInClip = GetAmmoInClip(cache.ped, pedWeapon)
            local ammoReserve = ammoName and ox_inventory:GetItemCount(ammoName) or 0

            interface.send({
                action = 'updateAmmo',
                data = {
                    hasWeapon = true,
                    ammoInClip = ammoInClip,
                    ammoReserve = ammoReserve,
                    weaponHash = pedWeapon,
                },
            })
        end

        interface.send({
            action = 'updateAmmo',
            data = {
                hasWeapon = false,
            },
        })
    end)
end

lib.onCache('weapon', function (weapon)
    if not weapon then
        return
    end

    local ammoName = SM_HUD.weaponAmmo[weapon]

    if not ammoName then
        return
    end

    if not IsWeaponValid(weapon) or weapon == joaat('WEAPON_UNARMED') then
        return
    end

    weaponThread()
    shootingThread()
end)

-- RegisterCommand('stress', function(_, args)
--     local level = args?[1] or 0
--     TriggerTokenEvent('sm_hud:server:addStress', tonumber(level))
-- end, false)