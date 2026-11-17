local config = localmodule 'config.shared'
local timerModule = require 'modules.timers.shared'

local ankletProp = nil
local trackerBlip = nil
local ankletTimer = nil
local ankletActive = false
local propHidden = false
local trackingCooldown = 0

local function removeProp()
    if not (ankletProp and DoesEntityExist(ankletProp)) then
        ankletProp = nil
        return
    end
    pcall(DeleteEntity, ankletProp)
    ankletProp = nil
end

local function spawnProp()
    removeProp()

    local model = config.prop
    lib.requestModel(model, 8000)

    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.0)
    ankletProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)

    if not DoesEntityExist(ankletProp) then
        SetModelAsNoLongerNeeded(model)
        ankletProp = nil
        return false
    end

    if not NetworkGetEntityIsNetworked(ankletProp) then
        NetworkRegisterEntityAsNetworked(ankletProp)
    end

    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(ankletProp, true, false)
    SetEntityCollision(ankletProp, false, false)
    SetEntityCompletelyDisableCollision(ankletProp, false, false)

    local off = config.propOffset
    AttachEntityToEntity(
        ankletProp, cache.ped, GetPedBoneIndex(cache.ped, config.bone),
        off.x, off.y, off.z, off.rx, off.ry, off.rz,
        true, true, false, true, 1, true
    )

    return true
end

local function stopTimer()
    if ankletTimer then
        ankletTimer:stop()
        ankletTimer = nil
    end
    ankletActive = false
    infoUI.remove('anklet_monitor')
end

local function cleanup()
    propHidden = false
    -- removeProp()
    stopTimer()
end

local function startTimer(remaining)
    stopTimer()

    if not remaining or remaining <= 0 then return end

    ankletActive = true

    ankletTimer = timerModule:new('detik', remaining, function()
        ankletTimer = nil
        ankletActive = false
        propHidden = false
        -- removeProp()
        infoUI.remove('anklet_monitor')
        TriggerTokenEvent('sm_anklet:expired')
        lib.notify({ description = 'Anklet monitor telah berakhir', type = 'inform' })
    end)

    CreateThread(function()
        while ankletActive do
            infoUI.show({
                id = 'anklet_monitor',
                icon = 'fas fa-link',
                title = 'Anklet Monitor',
                description = {
                    ['Sisa Waktu'] = ankletTimer:getTimeLeftFormat()
                }
            })
            Wait(500)
        end
        infoUI.remove('anklet_monitor')
    end)
end

local function removeTracker()
    if trackerBlip and DoesBlipExist(trackerBlip) then
        RemoveBlip(trackerBlip)
    end
    trackerBlip = nil
end

local function openAnkletMenu()
    local options = {
        {
            title = 'Pasang Anklet',
            icon = 'fas fa-link',
            onSelect = function()
                local closest = lib.callback.await('sm_anklet:getClosest', false)
                if not closest then
                    return lib.notify({ description = 'Tidak ada player terdekat', type = 'error' })
                end

                local input = lib.inputDialog('Pasang Anklet - ' .. closest.name, {
                    { type = 'number', label = 'Durasi (menit)', default = config.defaultMinutes, min = 1, max = config.maxMinutes },
                })

                if not input then return end
                TriggerTokenEvent('sm_anklet:install', closest.src, math.floor(input[1]))
            end,
        },
        {
            title = 'Lepas Anklet',
            icon = 'fas fa-unlink',
            onSelect = function()
                local closest = lib.callback.await('sm_anklet:getClosest', false)
                if not closest then
                    return lib.notify({ description = 'Tidak ada player terdekat', type = 'error' })
                end
                TriggerTokenEvent('sm_anklet:removeAnklet', closest.src)
            end,
        },
        {
            title = 'Daftar Anklet Aktif',
            icon = 'fas fa-list',
            onSelect = function()
                local list = lib.callback.await('sm_anklet:getActiveList', false)
                if not list or #list == 0 then
                    return lib.notify({ description = 'Tidak ada anklet aktif', type = 'inform' })
                end

                local items = {}
                for i = 1, #list do
                    local v = list[i]
                    local m = math.floor(v.remaining / 60)
                    local s = v.remaining % 60
                    items[#items + 1] = {
                        title = v.name .. ' (ID: ' .. v.src .. ')',
                        description = ('Sisa: %dm %ds | Officer: %s'):format(m, s, v.officer),
                        icon = 'fas fa-satellite-dish',
                        onSelect = function()
                            local now = GetGameTimer()
                            if now < trackingCooldown then
                                local secs = math.ceil((trackingCooldown - now) / 1000)
                                return lib.notify({ description = ('Tracking cooldown %ds'):format(secs), type = 'error' })
                            end
                            trackingCooldown = now + (config.tracking.cooldown * 1000)
                            TriggerTokenEvent('sm_anklet:requestTrack', v.src)
                            lib.notify({ description = 'Tracking dimulai...', type = 'success' })
                        end,
                    }
                end

                lib.registerContext({ id = 'anklet_list', title = 'Anklet Aktif', menu = 'anklet_menu', options = items })
                lib.showContext('anklet_list')
            end,
        },
    }

    lib.registerContext({ id = 'anklet_menu', title = 'Anklet Monitor', options = options })
    lib.showContext('anklet_menu')
end

RegisterNetEvent('sm_anklet:apply', function(remaining)
    if source == '' then return end
    -- spawnProp()
    startTimer(remaining)
end)

RegisterNetEvent('sm_anklet:remove', function()
    if source == '' then return end
    cleanup()
end)

RegisterNetEvent('sm_anklet:trackerUpdate', function(coords, name)
    if GetInvokingResource() then return end
    removeTracker()
    trackerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(trackerBlip, 1)
    SetBlipDisplay(trackerBlip, 4)
    SetBlipScale(trackerBlip, 0.85)
    SetBlipColour(trackerBlip, 1)
    SetBlipAsShortRange(trackerBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('%s (Anklet)'):format(name or 'Unknown'))
    EndTextCommandSetBlipName(trackerBlip)
end)

RegisterNetEvent('sm_anklet:trackerRemove', function()
    if GetInvokingResource() then return end
    removeTracker()
    lib.notify({ description = 'Tracking selesai', type = 'inform' })
end)

lib.onCache('ped', function()
    -- Wait(500)
    -- if ankletActive and not propHidden then
    --     spawnProp()
    -- end
end)

lib.onCache('vehicle', function(vehicle)
    -- if not ankletData then return end
    -- propHidden = vehicle ~= false and vehicle ~= nil
    -- if propHidden then
    --     removeProp()
    -- else
    --     spawnProp()
    -- end
end)

RegisterNetEvent('sm_anklet:openMenu', function()
    if source == '' then return end
    openAnkletMenu()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(5000)
    local remaining = lib.callback.await('sm_anklet:getMyAnklet', false)
    if remaining then
        -- spawnProp()
        startTimer(remaining)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    cleanup()
end)

AddEventHandler('onResourceStop', function(resource)
    if cache.resource ~= resource then return end
    removeProp()
    removeTracker()
    stopTimer()
end)