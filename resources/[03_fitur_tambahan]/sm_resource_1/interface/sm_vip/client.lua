local Config = localmodule 'config'

local npcEntity
local adminMenuOpen = false
local frameMounted = false
local frameReady = false
local pendingSender

interface.init(false)

local function openAdminSurface(sender)
    pendingSender = sender
    if not frameMounted then
        frameReady = false
        frameMounted = true
        interface.show()
    elseif frameReady then
        pendingSender = nil
        sender()
    end
end

local function closeAdminSurface()
    pendingSender = nil
    if not frameMounted then return end
    interface.hide()
    frameMounted = false
    frameReady = false
end

interface.callback('vipReady', function(_, cb)
    cb('ok')
    frameReady = true

    local sender = pendingSender
    pendingSender = nil
    if sender then sender() end
end)

local function openVehicleClaimMenu(vipData)
    lib.callback('sm_vip:server:getVehicleClaimStatus', false, function(claimStatus)
        local vehicles = Config.VipVehicles[vipData.vip_type].vehicles
        local options = {}
        local claimed = claimStatus.hasClaimed

        for i = 1, #vehicles do
            local vehicle = vehicles[i]
            options[#options + 1] = {
                title = vehicle.label,
                description = claimed and (vehicle.description .. ' (Sudah Di-Claim)') or vehicle.description,
                icon = 'fas fa-car-side',
                iconColor = claimed and 'gray' or 'blue',
                disabled = claimed,
                metadata = {
                    { label = 'Model', value = vehicle.model },
                    { label = 'Status', value = claimed and 'Claimed' or 'Available' }
                }
            }
        end

        if claimed then
            options[#options + 1] = {
                title = 'Kendaraan Sudah Di-Claim',
                description = 'Anda sudah mengklaim kendaraan untuk periode VIP ini',
                icon = 'fas fa-info-circle',
                iconColor = 'orange',
                disabled = true
            }
        else
            options[#options + 1] = {
                title = 'Claim Semua Kendaraan',
                description = ('Claim %d kendaraan sekaligus'):format(#vehicles),
                icon = 'fas fa-check-circle',
                iconColor = 'green',
                onSelect = function()
                    TriggerTokenEvent('sm_vip:server:claimVehicle')
                    lib.hideContext()
                end
            }
        end

        lib.registerContext({
            id = 'sm_vip_vehicle_claim',
            title = ('Daftar Kendaraan %s'):format(Config.VipTypes[vipData.vip_type].label),
            menu = 'sm_vip_status',
            options = options
        })
        lib.showContext('sm_vip_vehicle_claim')
    end)
end

local function openTVRemoteClaimMenu(vipData)
    lib.callback('sm_vip:server:getTVRemoteClaimStatus', false, function(claimStatus)
        local item = Config.TVRemote[vipData.vip_type].item
        local claimed = claimStatus.hasClaimed
        local options = {
            {
                title = ('%s x%d'):format(item.label, item.amount),
                description = item.description,
                icon = 'fas fa-tv',
                iconColor = claimed and 'gray' or 'purple',
                disabled = claimed,
                metadata = {
                    { label = 'Item', value = item.name },
                    { label = 'Status', value = claimed and 'Sudah Di-Claim' or 'Tersedia' }
                }
            }
        }

        if claimed then
            options[#options + 1] = {
                title = 'Sudah Di-Claim',
                description = 'Anda sudah mengklaim TV Remote untuk periode VIP ini',
                icon = 'fas fa-info-circle',
                iconColor = 'orange',
                disabled = true
            }
        else
            options[#options + 1] = {
                title = 'Claim TV Remote',
                description = 'Claim remote TV untuk periode VIP ini',
                icon = 'fas fa-check-circle',
                iconColor = 'green',
                onSelect = function()
                    TriggerTokenEvent('sm_vip:server:claimTVRemote')
                    lib.hideContext()
                end
            }
        end

        lib.registerContext({
            id = 'sm_vip_tvremote_claim',
            title = ('TV Remote %s'):format(Config.VipTypes[vipData.vip_type].label),
            menu = 'sm_vip_status',
            options = options
        })
        lib.showContext('sm_vip_tvremote_claim')
    end)
end

local function openDailyItemMenu(vipData)
    lib.callback('sm_vip:server:getDailyItemStatus', false, function(itemStatus)
        local items = Config.DailyItems[vipData.vip_type].items
        local options = {}
        local canClaim = itemStatus.canClaim

        for i = 1, #items do
            local item = items[i]
            options[#options + 1] = {
                title = ('%s x%d'):format(item.label, item.amount),
                description = item.description,
                icon = 'fas fa-box',
                iconColor = canClaim and 'green' or 'gray',
                disabled = not canClaim,
                metadata = {
                    { label = 'Item', value = item.name },
                    { label = 'Jumlah', value = item.amount }
                }
            }
        end

        if canClaim then
            options[#options + 1] = {
                title = 'Claim Semua Item',
                description = ('Claim %d jenis item sekaligus'):format(#items),
                icon = 'fas fa-check-circle',
                iconColor = 'green',
                onSelect = function()
                    TriggerTokenEvent('sm_vip:server:claimDailyItem')
                    lib.hideContext()
                end
            }
        else
            local cooldownText = itemStatus.timeLeft or 'Menghitung...'
            options[#options + 1] = {
                title = 'Sedang Cooldown',
                description = ('Silakan tunggu %s'):format(cooldownText),
                icon = 'fas fa-clock',
                iconColor = 'orange',
                disabled = true,
                metadata = {
                    { label = 'Cooldown', value = cooldownText }
                }
            }
        end

        lib.registerContext({
            id = 'sm_vip_daily_item',
            title = ('Daily Item %s'):format(Config.VipTypes[vipData.vip_type].label),
            menu = 'sm_vip_status',
            options = options
        })
        lib.showContext('sm_vip_daily_item')
    end)
end

local function checkVipStatus()
    lib.callback('sm_vip:server:getPlayerVipStatus', false, function(vipData)
        if not vipData then
            lib.registerContext({
                id = 'sm_vip_status',
                title = 'VIP Status',
                options = {
                    {
                        title = 'No VIP Status',
                        description = 'Anda belum memiliki status VIP',
                        icon = 'fas fa-times-circle',
                        iconColor = 'red'
                    }
                }
            })
            lib.showContext('sm_vip_status')
            return
        end

        local vipType = vipData.vip_type
        local typeData = Config.VipTypes[vipType]

        -- Tipe lama yang sudah dihapus dari config (mis. 'vip') masih mungkin ada
        -- di DB; tampilkan apa adanya tanpa opsi claim daripada error.
        if not typeData then
            lib.registerContext({
                id = 'sm_vip_status',
                title = 'VIP Status',
                options = {
                    {
                        title = ('Tipe "%s" sudah tidak berlaku'):format(tostring(vipType):upper()),
                        description = 'Hubungi admin untuk memperbarui status VIP Anda',
                        icon = 'fas fa-triangle-exclamation',
                        iconColor = 'orange'
                    }
                }
            })
            lib.showContext('sm_vip_status')
            return
        end

        local options = {
            {
                title = ('%s Active'):format(typeData.label),
                description = ('Sisa waktu: %s'):format(vipData.timeLeft or 'Unknown'),
                icon = 'fas fa-crown',
                iconColor = vipType == 'vvip' and 'gold' or 'silver'
            }
        }

        local vehicleTier = Config.VipVehicles[vipType]
        local tvTier = Config.TVRemote[vipType]
        local dailyTier = Config.DailyItems[vipType]

        if Config.VipVehicles.enabled and vehicleTier and vehicleTier.enabled then
            options[#options + 1] = {
                title = 'Claim Kendaraan VIP',
                description = 'Lihat daftar kendaraan yang tersedia',
                icon = 'fas fa-car',
                iconColor = 'blue',
                onSelect = function()
                    openVehicleClaimMenu(vipData)
                end
            }
        end

        if Config.TVRemote.enabled and tvTier and tvTier.enabled then
            options[#options + 1] = {
                title = 'Claim TV Remote',
                description = 'Claim remote TV (1x per periode VIP)',
                icon = 'fas fa-tv',
                iconColor = 'purple',
                onSelect = function()
                    openTVRemoteClaimMenu(vipData)
                end
            }
        end

        if Config.DailyItems.enabled and dailyTier and dailyTier.enabled then
            options[#options + 1] = {
                title = 'Claim Daily Item',
                description = 'Lihat daftar item harian yang tersedia',
                icon = 'fas fa-gift',
                iconColor = 'green',
                onSelect = function()
                    openDailyItemMenu(vipData)
                end
            }
        end

        lib.registerContext({
            id = 'sm_vip_status',
            title = 'VIP Status',
            options = options
        })
        lib.showContext('sm_vip_status')
    end)
end

local function spawnVipNPC()
    if npcEntity and DoesEntityExist(npcEntity) then return end

    local npc = Config.VipNPC
    local coords = npc.coords

    if not lib.requestModel(npc.model, 10000) then
        lib.print.error(('sm_vip: gagal load model NPC "%s"'):format(npc.model))
        return
    end

    npcEntity = CreatePed(4, npc.model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)

    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    FreezeEntityPosition(npcEntity, true)
    SetModelAsNoLongerNeeded(npc.model)

    if npc.scenario then
        TaskStartScenarioInPlace(npcEntity, npc.scenario, 0, true)
    end

    ox_target:addLocalEntity(npcEntity, {
        {
            name = 'sm_vip_check',
            icon = 'fas fa-crown',
            label = 'Check VIP Status',
            onSelect = checkVipStatus
        }
    })
end

RegisterNetEvent('sm_vip:client:openAdminMenu', function()
    if adminMenuOpen then return end
    adminMenuOpen = true

    openAdminSurface(function()
        interface.send({ action = 'openVipManager' })
    end)
    interface.focus(true, true)
end)

local function closeAdminMenu()
    if not adminMenuOpen then return end
    adminMenuOpen = false
    interface.focus(false, false)
    closeAdminSurface()
end

interface.callback('closeVipManager', function(_, cb)
    cb('ok')
    closeAdminMenu()
end)

interface.callback('getVipPlayers', function(_, cb)
    lib.callback('sm_vip:server:getVipPlayers', false, cb)
end)

interface.callback('getVipHistory', function(_, cb)
    lib.callback('sm_vip:server:getVipHistory', false, cb)
end)

interface.callback('searchPlayer', function(data, cb)
    lib.callback('sm_vip:server:searchPlayer', false, cb, data.query)
end)

interface.callback('addVip', function(data, cb)
    lib.callback('sm_vip:server:addVip', false, cb, data)
end)

interface.callback('editVip', function(data, cb)
    lib.callback('sm_vip:server:editVip', false, cb, data)
end)

interface.callback('deleteVip', function(data, cb)
    lib.callback('sm_vip:server:deleteVip', false, cb, data.ids)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    spawnVipNPC()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource ~= resourceName then return end

    if adminMenuOpen then SetNuiFocus(false, false) end

    if npcEntity and DoesEntityExist(npcEntity) then
        ox_target:removeLocalEntity(npcEntity, 'sm_vip_check')
        DeleteEntity(npcEntity)
    end
end)

CreateThread(spawnVipNPC)
