local config = localmodule 'config.client'

local function painkillerLoop()
    lib.print.warn('[Deprecated] sudah tidak terpakai')
end

exports('PainKillerLoop', painkillerLoop)

RegisterNetEvent('ambulance:client:useBandage', function(itemType)
    if source == '' then return end

    local success = lib.progressBar({
        duration = 4000,
        label = 'Menggunakan perban...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true
        },
        anim = {
            dict = config.anim.bandage.dict,
            clip = config.anim.bandage.clip,
            flag = 48
        },
        prop = config.anim.bandage.prop
    })

    if success then
        TriggerTokenEvent('ambulance:removeItem', itemType or 'bandage')
    end
end)

RegisterNetEvent('ambulance:client:applyHeal', function(healAmount)
    if source == '' then return end
    if type(healAmount) ~= 'number' then return end

    SetEntityHealth(cache.ped, math.min(GetEntityHealth(cache.ped) + healAmount, GetEntityMaxHealth(cache.ped)))
end)

RegisterNetEvent('ambulance:client:useIfaks', function()
    if source == '' then return end

    local success = lib.progressBar({
        duration = 3000,
        label = 'Menggunakan IFAK...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true
        },
        anim = {
            dict = config.anim.bandage.dict,
            clip = config.anim.bandage.clip,
            flag = 48
        },
        prop = config.anim.bandage.prop
    })

    if success then
        TriggerTokenEvent('ambulance:removeItem', 'ifaks')
    end
end)
