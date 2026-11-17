local doknpc = localmodule 'config.shared'.dokter_npc
local npcModule = require 'modules.pedHandle.client'

local function progress(label)
    return lib.progressBar({
        duration = 15000,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        }
    })
end

CreateThread(function ()
    for k, v in pairs(doknpc) do
        local revive = v.options?.revive?.enable or false
        local heal = v.options?.heal?.enable or false

        npcModule:new({
            model = v.model,
            coords = v.coords,
            renderDistance = 50.0
        })

        local options = {}

        if revive then
            options[#options+1] = {
                label = 'Revive',
                icon = 'fa-solid fa-heart-pulse',
                distance = 1.5,
                onSelect = function ()
                    if not progress('Kamu sedang di obati...') then
                        return lib.notify({ description = 'Pengobatan dibatalkan', type = 'error' })
                    end
                    TriggerTokenEvent('ambulance:dokter_npc', {k, 'revive'})
                end,
                canInteract = function (_, distance)
                    return QBPlayerData.metadata.isdead
                end
            }
        end

        if heal then
            options[#options+1] = {
                label = 'Heal',
                icon = 'fa-solid fa-hand-holding-medical',
                distance = 1.5,
                onSelect = function ()
                    if not progress('Kamu sedang di obati...') then
                        return lib.notify({ description = 'Pengobatan dibatalkan', type = 'error' })
                    end
                    TriggerTokenEvent('ambulance:dokter_npc', {k, 'heal'})
                end,
                canInteract = function (_, distance)
                    return not QBPlayerData.metadata.isdead
                end
            }
        end

        if #options > 0 then
            exports.rhd_interact:addCoords({
                coords = v.coords,
                options = options
            })
        end
    end
end)