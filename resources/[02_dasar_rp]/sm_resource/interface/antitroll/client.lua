if not interface.init() then return end

local config = require 'interface.antitroll.config'
local ready = false
local state = false

local function isWeaponWhitelisted(weaponHash)
    if not config.WhitelistedWeapons then return false end
    for _, name in ipairs(config.WhitelistedWeapons) do
        if GetHashKey(name) == weaponHash then return true end
    end
    return false
end

local function startProtectionLoop()
    CreateThread(function()
        while ready do
            if config.DisablePunching then
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)
            end

            if config.DisableShooting and cache.weapon then
                local current = GetSelectedPedWeapon(cache.ped)
                if not isWeaponWhitelisted(current) then
                    TriggerEvent('ox_inventory:disarm', true)
                end
            end

            Wait(0)
        end
    end)
end

local gymZone = lib.zones.poly({
    name = 'zonagym',
    debug = false,
    points = {
        vec3(-1213.0, -1559.0, 4.0),
        vec3(-1204.0, -1553.0, 4.0),
        vec3(-1183.0, -1581.0, 4.0),
        vec3(-1196.0, -1590.0, 4.0),
        vec3(-1215.0, -1560.0, 4.0),
    },
    thickness = 4.0,
})

local function isPlayerInGymZone()
    return gymZone:contains(GetEntityCoords(cache.ped))
end

RegisterNetEvent('antitroll_client:check', function(time)
    if source ~= 65535 then return end
    if not time or time <= 0 or ready then return end

    ready = true
    startProtectionLoop()

    interface.send({
        action = 'setTimer',
        data = { time = time, saveInterval = config.TimeToSave },
    })
end)

RegisterNetEvent('antitroll_client:pause', function()
    if source ~= 65535 then return end
    ready = false
    interface.send({ action = 'stopTimer' })
end)

RegisterNetEvent('antitroll_client:updateTimer', function(time)
    if source ~= 65535 then return end
    if not time or time <= 0 then return end
    interface.send({
        action = 'setTimer',
        data = { time = time, saveInterval = config.TimeToSave },
    })
end)

RegisterNetEvent('antitroll_client:voucherResult', function(success, message, newTime)
    if source ~= 65535 then return end

    lib.notify({
        title = 'Voucher Pereda Keram',
        description = message,
        type = success and 'success' or 'error',
    })
end)

interface.callback('timeFinish', function(_, cb)
    ready = false
    TriggerTokenEvent('antitroll_server:check')
    cb('ok')
end)

exports('toggleTrollUI', function(status)
    if state == status then return end
    state = status
    interface.send({
        action = 'toggleUI',
        data = { state = status },
    })
end)

exports('voucher_peredakeram', function(_, slot)
    if not isPlayerInGymZone() then
        return lib.notify({
            title = 'Voucher Pereda Keram',
            description = 'Anda harus berada di dalam zona Gym untuk menggunakan voucher ini!',
            type = 'error',
        })
    end

    lib.progressBar({
        duration = 10000,
        label = 'Menggunakan Voucher Pereda Keram...',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'timetable@amanda@ig_4',
            clip = 'ig_4_idle',
            flag = 1,
        },
    })

    TriggerTokenEvent('antitroll_server:useVoucher', slot.slot)
end)