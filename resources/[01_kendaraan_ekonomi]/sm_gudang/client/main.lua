local function showStashInfo(stashType)
    local stashConfig = Config.StashTypes[stashType]

    lib.alertDialog({
        header = 'Info ' .. stashConfig.label,
        content = ('**Spesifikasi Gudang:**\n\n' ..
            '• Kapasitas: %d slot\n' ..
            '• Berat maksimal: %dkg\n' ..
            '• Harga per hari: $%s\n' ..
            '• Sewa minimum: %d hari\n' ..
            '• Sewa maksimum: %d hari\n' ..
            '• **Maksimal total sewa: %d hari**'):format(
            stashConfig.slots,
            stashConfig.weight / 1000,
            lib.math.groupdigits(stashConfig.pricePerDay),
            stashConfig.minDays,
            stashConfig.maxDays,
            stashConfig.maxTotalDays or stashConfig.maxDays
        ),
        centered = true
    })
end

local function showRentalDialog(stashType, isExtension)
    local stashConfig = Config.StashTypes[stashType]

    local input = lib.inputDialog(isExtension and 'Perpanjang Sewa Gudang' or 'Sewa Gudang Baru', {
        {
            type = 'slider',
            label = 'Jumlah Hari',
            description = ('Pilih berapa hari ingin menyewa (Harga: $%s/hari)\nMaksimal total sewa: %d hari'):format(
                lib.math.groupdigits(stashConfig.pricePerDay),
                stashConfig.maxTotalDays or stashConfig.maxDays
            ),
            icon = 'calendar',
            required = true,
            default = stashConfig.minDays,
            min = stashConfig.minDays,
            max = stashConfig.maxDays,
            step = 1
        }
    })

    if not input then return end

    local days = input[1]
    local totalPrice = stashConfig.pricePerDay * days

    local confirm = lib.alertDialog({
        header = 'Konfirmasi Sewa',
        content = ('**%s**\n\n' ..
            'Durasi: %d hari\n' ..
            'Harga per hari: $%s\n' ..
            'Total biaya: $%s\n' ..
            'Maksimal total sewa: %d hari\n\n' ..
            'Apakah Anda yakin ingin melanjutkan?'):format(
            stashConfig.label,
            days,
            lib.math.groupdigits(stashConfig.pricePerDay),
            lib.math.groupdigits(totalPrice),
            stashConfig.maxTotalDays or stashConfig.maxDays
        ),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Ya, Sewa',
            cancel = 'Batal'
        }
    })

    if confirm == 'confirm' then
        TriggerServerEvent('ni_stash:server:rentStash', stashType, days)
    end
end

local function showRentalMenu(stashType, status, remainingDays)
    local stashConfig = Config.StashTypes[stashType]
    local menuOptions = {}

    if status == 'active' then
        menuOptions[#menuOptions + 1] = {
            title = 'Buka Gudang',
            description = 'Akses gudang Anda (Sisa: ' .. remainingDays .. ' hari)',
            icon = 'warehouse',
            onSelect = function()
                TriggerServerEvent('ni_stash:server:openRentalStash', stashType)
            end
        }

        menuOptions[#menuOptions + 1] = {
            title = 'Perpanjang Sewa',
            description = 'Tambah waktu sewa gudang',
            icon = 'clock',
            onSelect = function()
                showRentalDialog(stashType, true)
            end
        }
    elseif status == 'expired' then
        menuOptions[#menuOptions + 1] = {
            title = 'Perpanjang Sewa (Kedaluwarsa)',
            description = 'Sewa gudang telah kedaluwarsa, perpanjang sekarang',
            icon = 'exclamation-triangle',
            onSelect = function()
                showRentalDialog(stashType, false)
            end
        }
    else
        menuOptions[#menuOptions + 1] = {
            title = 'Sewa Gudang',
            description = 'Mulai sewa gudang baru',
            icon = 'plus',
            onSelect = function()
                showRentalDialog(stashType, false)
            end
        }
    end

    menuOptions[#menuOptions + 1] = {
        title = 'Info Gudang',
        description = 'Lihat detail gudang',
        icon = 'info',
        onSelect = function()
            showStashInfo(stashType)
        end
    }

    lib.registerContext({
        id = 'rental_stash_menu',
        title = stashConfig.label,
        options = menuOptions
    })

    lib.showContext('rental_stash_menu')
end

local function showVipInfo(vipStatus)
    local content

    if vipStatus then
        content = ('**Status VIP Anda:**\n\n' ..
            '• Status: %s\n' ..
            '• Waktu tersisa: %s\n\n' ..
            '**Akses Gudang:**\n' ..
            '• Gudang VIP: %s\n' ..
            '• Gudang VVIP: %s'):format(
            vipStatus.vip_type:upper(),
            vipStatus.timeLeft or 'Tidak diketahui',
            vipStatus.vip_type == Config.StashTypes['vip_stash'].requiresVip and 'Tersedia' or 'Tidak Tersedia',
            vipStatus.vip_type == Config.StashTypes['vvip_stash'].requiresVip and 'Tersedia' or 'Tidak Tersedia'
        )
    else
        content = '**Status VIP Anda:**\n\n' ..
            'Anda tidak memiliki status VIP aktif\n\n' ..
            'Untuk mengakses gudang VIP eksklusif,\n' ..
            'silakan hubungi admin, atau kunjungi website kami.'
    end

    lib.alertDialog({
        header = 'Info Status VIP',
        content = content,
        centered = true
    })
end

local function showVipStashMenu(vipStatus)
    local vipType = vipStatus and vipStatus.vip_type
    local menuOptions = {}

    -- Syarat akses dibaca dari Config supaya nama tier tidak perlu di-hardcode
    -- di sini; server memakai pengecekan yang sama (requiresVip).
    local function addStashOption(stashType, title, icon, capacity)
        local required = Config.StashTypes[stashType].requiresVip
        local allowed = vipType == required

        local description

        if allowed then
            description = ('Akses gudang %s eksklusif (%s)'):format(required:upper(), capacity)
        elseif vipType then
            description = ('Khusus untuk %s (Anda %s)'):format(required:upper(), tostring(vipType):upper())
        else
            description = ('Memerlukan status %s, Kapasitas (%s)'):format(required:upper(), capacity)
        end

        menuOptions[#menuOptions + 1] = {
            title = title,
            description = description,
            icon = icon,
            disabled = not allowed,
            onSelect = function()
                TriggerServerEvent('ni_stash:server:openVipStash', stashType)
            end
        }
    end

    addStashOption('vip_stash', 'Gudang VIP', 'gem', '15 ton, 100 slot')
    addStashOption('vvip_stash', 'Gudang VVIP', 'crown', '15 ton, 200 slot')

    menuOptions[#menuOptions + 1] = {
        title = 'Info Status VIP',
        description = 'Lihat status VIP Anda',
        icon = 'info',
        onSelect = function()
            showVipInfo(vipStatus)
        end
    }

    lib.registerContext({
        id = 'vip_stash_menu',
        title = 'Gudang VIP Eksklusif',
        options = menuOptions
    })

    lib.showContext('vip_stash_menu')
end

local function createBlip(coords, label, sprite, scale, colour)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, colour)
    SetBlipAsShortRange(blip, true)
    SetBlipCategory(blip, 23)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
end

local function canInteract()
    return not IsPedInAnyVehicle(cache.ped, false)
end

CreateThread(function()
    AddTextEntry('BLIP_CAT_23', 'Gudang')

    for i = 1, #Config.RentalLocations do
        local location = Config.RentalLocations[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'rental_stash_' .. location.stashType,
                    icon = 'fa-warehouse',
                    label = location.label,
                    canInteract = canInteract,
                    onSelect = function()
                        TriggerServerEvent('ni_stash:server:getStashStatus', location.stashType)
                    end
                }
            }
        })

        createBlip(location.coords, location.label, 473, 0.8, 11)
    end

    for i = 1, #Config.VipStashLocations do
        local location = Config.VipStashLocations[i]

        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'vip_exclusive_stash_' .. i,
                    icon = 'fa-gem',
                    label = location.label,
                    canInteract = canInteract,
                    onSelect = function()
                        TriggerServerEvent('ni_stash:server:getVipStatus')
                    end
                }
            }
        })

        createBlip(location.coords, location.label, 478, 0.7, 46)
    end
end)

RegisterNetEvent('ni_stash:client:receiveStashStatus', function(status, remainingDays, stashType)
    showRentalMenu(stashType, status, remainingDays)
end)

RegisterNetEvent('ni_stash:client:openStash', function(stashId)
    exports.ox_inventory:openInventory('stash', stashId)
end)

RegisterNetEvent('ni_stash:client:showVipMenu', function(vipStatus)
    showVipStashMenu(vipStatus)
end)
