local config = localmodule 'config.storerobbery'
local locations = lib.table.deepclone(config.locations)

local scene = require 'resource.illegal_activity.utils.scene'

CreateThread(function()
    for shopId, data in pairs(locations) do
        local register = data.register
        local computer = data.computer
        local safe = data.safe

        if register then
            ox_target:addSphereZone({
                coords = register.coords,
                radius = 1.0,
                options = {
                    {
                        icon = 'fas fa-cash-register',
                        label = 'Rob Cash Register',
                        onSelect = function()
                            local canRob = lib.callback.await('storerobbery:canExecute', 1500, {
                                'register', shopId,
                            })

                            if not canRob then return end

                            if not exports.sm_sidejob:startLockpick('lockpick', 3, 5) then
                                TriggerTokenEvent('storerobbery:resetBusy', 'register', shopId, true)
                                return
                            end

                            if not lib.callback.await('storerobbery:consumeLockpick', false, shopId) then
                                TriggerTokenEvent('storerobbery:resetBusy', 'register', shopId)
                                return
                            end

                            if not scene.grabFromCashRegister() then
                                TriggerTokenEvent('storerobbery:resetBusy', 'register', shopId)
                                return
                            end

                            local dispatch = safecall.fun(function()
                                return exports.tk_dispatch:getPlayerData()
                            end)

                            TriggerTokenEvent('storerobbery:onRegisterLooted', shopId, dispatch)
                        end,
                        distance = 1.5,
                    },
                },
            })
        end

        if computer then
            ox_target:addSphereZone({
                coords = computer.coords,
                radius = 1.0,
                options = {
                    {
                        icon = 'fas fa-computer',
                        label = 'Hack Computer',
                        onSelect = function()
                            local canRob = lib.callback.await('storerobbery:canExecute', 1500, {
                                'computer', shopId,
                            })

                            if not canRob then return end

                            if not terminal_hack then
                                lib.print.error('terminal_hack module tidak tersedia, minigame dibatalkan')
                                TriggerTokenEvent('storerobbery:resetBusy', 'computer', shopId)
                                return
                            end

                            local success = terminal_hack.start('easy')

                            if not success then
                                TriggerTokenEvent('storerobbery:resetBusy', 'computer', shopId, true)
                                return
                            end

                            local completed = lib.progressBar({
                                label = 'Bypassing system..',
                                duration = 30000,
                                position = 'bottom',
                                useWhileDead = false,
                                canCancel = false,
                                disable = { car = true, move = true, combat = true },
                                anim = {
                                    dict = 'anim@heists@prison_heiststation@cop_reactions',
                                    clip = 'cop_b_idle',
                                },
                            })

                            if not completed then
                                TriggerTokenEvent('storerobbery:resetBusy', 'computer', shopId)
                                return
                            end

                            TriggerTokenEvent('storerobbery:onComputerHacked', shopId)
                        end,
                        distance = 1.5,
                        canInteract = function()
                            local store = locations[shopId]
                            return store and store.robbed and not store.computer.looted
                        end,
                    },
                },
            })
        end

        if safe then
            ox_target:addSphereZone({
                coords = safe.coords,
                radius = 1.0,
                options = {
                    {
                        icon = 'fas fa-safe',
                        label = 'Hack Safe',
                        onSelect = function()
                            local canRob = lib.callback.await('storerobbery:canExecute', 1500, {
                                'safe', shopId,
                            })

                            if not canRob then return end

                            local input = lib.inputDialog('Brankas', {
                                {
                                    type = 'number',
                                    label = 'Masukkan PIN',
                                    description = 'Masukkan PIN untuk membuka brankas',
                                },
                            })

                            if not input then
                                TriggerTokenEvent('storerobbery:resetBusy', 'safe', shopId)
                                return
                            end

                            local valid = lib.callback.await('storerobbery:validateSafePin', 1500, {
                                shopId, input[1],
                            })

                            if not valid then
                                qb_ecore:Notify('PIN salah.', 'error')
                                TriggerTokenEvent('storerobbery:resetBusy', 'safe', shopId, true)
                                return
                            end

                            local completed = lib.progressBar({
                                label = 'Looting brangkas..',
                                duration = 30000,
                                position = 'bottom',
                                useWhileDead = false,
                                canCancel = false,
                                disable = { car = true, move = true, combat = true },
                                anim = {
                                    dict = 'mini@safe_cracking',
                                    clip = 'dial_turn_clock_slow',
                                },
                            })

                            if not completed then
                                TriggerTokenEvent('storerobbery:resetBusy', 'safe', shopId)
                                return
                            end

                            TriggerTokenEvent('storerobbery:onSafeHacked', shopId)
                        end,
                        distance = 1.5,
                        canInteract = function()
                            local store = locations[shopId]
                            return store and store.robbed and not store.safe.looted
                        end,
                    },
                },
            })
        end
    end
end)

RegisterNetEvent('storerobbery:onComputerHacked', function(code)
    if source == '' then return end

    lib.alertDialog({
        header = 'Kode Terbongkar',
        content = 'Anda berhasil meretas komputer dan menemukan kode berikut: ' .. code,
        centered = true,
        cancel = true,
    })
end)

RegisterNetEvent('storerobbery:sync', function(key, val)
    if source == '' then return end

    local _type = type(key)

    if _type == 'table' then
        locations = key
    elseif _type == 'string' and locations[key] then
        locations[key] = val
    end
end)