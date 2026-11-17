RegisterCommand(Gacha.OpenCommand, function()
    openDonateUI('gacha')
end, false)

local openSpam = 0
RegisterNUICallback('gachaOpenCase', function(data, cb)
    if openSpam >= GetGameTimer() then cb(false) return end
    openSpam = GetGameTimer() + 800

    lib.callback('sm_donate:gachaOpenCase', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('gachaOpenCaseWithItem', function(data, cb)
    lib.callback('sm_donate:gachaOpenCaseWithItem', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('gachaCollect', function(data, cb)
    lib.callback('sm_donate:gachaCollectItem', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('gachaSell', function(data, cb)
    lib.callback('sm_donate:gachaSellItem', false, function(result)
        cb(result)
    end, data)
end)

RegisterNetEvent('sm_donate:gachaNotify', function(data)
    SendNUIMessage({ action = 'gachaServerNotif', data = data })
end)

RegisterNetEvent('sm_donate:gachaUseCasinoKupon', function()
    openDonateUI('gacha')
    SetTimeout(600, function()
        SendNUIMessage({ action = 'gachaCasinoKupon' })
    end)
end)

local kompOpening = false

RegisterNUICallback('kompensasiOpen', function(data, cb)
    lib.callback('sm_donate:kompensasiOpen', false, function(result)
        cb(result)
    end)
end)

RegisterNUICallback('kompensasiCollect', function(data, cb)
    lib.callback('sm_donate:kompensasiCollect', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('kompensasiClose', function(data, cb)
    kompOpening = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNetEvent('sm_donate:openKompensasi', function()
    if kompOpening then return end
    if uiOpen then
        lib.notify({ description = 'Tutup menu donate dulu sebelum membuka box.', type = 'error' })
        return
    end
    kompOpening = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openKompensasi' })
end)

local mdkOpening = false

RegisterNUICallback('merdekaOpen', function(data, cb)
    lib.callback('sm_donate:merdekaOpen', false, function(result)
        cb(result)
    end)
end)

RegisterNUICallback('merdekaCollect', function(data, cb)
    lib.callback('sm_donate:merdekaCollect', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('merdekaClose', function(data, cb)
    mdkOpening = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNetEvent('sm_donate:openMerdeka', function()
    if mdkOpening then return end
    if uiOpen then
        lib.notify({ description = 'Tutup menu donate dulu sebelum membuka box.', type = 'error' })
        return
    end
    mdkOpening = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openMerdeka' })
end)
