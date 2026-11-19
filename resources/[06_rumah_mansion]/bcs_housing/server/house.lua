local T = Config.Server.tables

---@param home table
---@param aptId string|number|nil
---@return table?
local function resolveTarget(home, aptId)
    if home:IsApartment() and aptId and aptId ~= 'nil' then
        return home:GetApartment(aptId)
    end
    return home
end

---@param src number
---@param home table
---@param aptId string|number|nil
---@param permission string
---@return boolean
local function canManageHome(src, home, aptId, permission)
    if Housing:IsAdmin(src) then return true end

    local identifier = Housing:GetIdentifier(src)
    if not identifier then return false end

    if home:IsOwner(identifier, aptId) then
        return home:HasOwnerPermission(identifier, permission)
    end

    return Housing:CanManage(src, home, permission)
end

lib.callback.register('Housing:server:GetData', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return {} end

    local identifier = Housing:GetIdentifier(source)
    if not home:HasAccess(identifier, nil, aptId) and not Housing:IsAdmin(source) and not Housing:IsPolice(source) then
        return {}
    end

    return home:GetData(aptId)
end)

lib.callback.register('Housing:server:isAdmin', function(source)
    return Housing:IsAdmin(source)
end)

lib.callback.register('Housing:server:GetNames', function(source, apartment)
    local names = {}
    for _, home in pairs(Housing.homes) do
        if not apartment or home:IsApartment() then
            names[#names + 1] = { name = home.name, identifier = home.identifier }
        end
    end
    return names
end)

lib.callback.register('Housing:server:GetOwnerName', function(source, identifier)
    if not identifier then return '' end

    local src = Housing:SourceByIdentifier(identifier)
    if src then return Housing:Name(src) end

    local row = MySQL.scalar.await('SELECT `charinfo` FROM `players` WHERE `citizenid` = ?', { identifier })
    if not row then return '' end

    local ok, info = pcall(json.decode, row)
    if not ok or type(info) ~= 'table' then return '' end
    return ('%s %s'):format(info.firstname or '', info.lastname or '')
end)

lib.callback.register('Housing:server:GetApartmentOwner', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return nil end
    local apt = home:GetApartment(aptId)
    return apt and apt.owner or nil
end)

RegisterNetEvent('Housing:server:UpdateStorage', function(target, storage, move)
    local src = source
    local homeId = type(target) == 'table' and target.homeId or target
    local aptId = type(target) == 'table' and target.aptId or nil

    local home = Housing:GetHome(homeId)
    if not home or type(storage) ~= 'table' then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'storage', aptId) and not Housing:IsAdmin(src) then return end

    local list = home:IsApartment() and aptId and (home:GetApartment(aptId) or {}).storages or home.storages
    if not list then return end

    if move then
        for i = 1, #list do
            if tostring(list[i].id) == tostring(storage.id) then
                list[i] = storage
                break
            end
        end
    else
        list[#list + 1] = storage
    end

    if home:IsApartment() and aptId then
        local apt = home:GetApartment(aptId)
        if apt then apt:Save() end
    else
        MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `aptId` IS NULL'):format(T.storages), { homeId })
        for i = 1, #home.storages do
            local entry = home.storages[i]
            MySQL.insert(('INSERT INTO `%s` (`home`, `storageId`, `coords`, `area`, `weight`, `slots`, `type`) VALUES (?, ?, ?, ?, ?, ?, ?)'):format(T.storages), {
                homeId, entry.id, json.encode(entry.coords or {}), entry.area, entry.weight, entry.slots, entry.type,
            })
        end
    end

    TriggerClientEvent('Housing:client:RefreshStorage', -1, homeId, storage, aptId, move)
end)

RegisterNetEvent('Housing:server:UpdateShell', function(homeId, data)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' then return end
    if not canManageHome(src, home, nil, 'configuration') then return end

    home.data.placement = data.shell
    home.data.interior = data.heading
    home:Save()

    Housing:BroadcastHome(home)
end)

RegisterNetEvent('Housing:server:SaveHomePermission', function(homeId, permission)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(permission) ~= 'table' then return end
    if not Housing:IsOwner(Housing:GetIdentifier(src)) and not Housing:IsAdmin(src) then return end

    home.permission = permission
    home:Save()
end)

RegisterNetEvent('Housing:server:SaveEditHome', function(homeId, data)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' then return end
    if not canManageHome(src, home, nil, 'configuration') then return end

    if data.price then home:SetProperty('price', tonumber(data.price) or 0) end
    if data.payment then home:SetProperty('payment', tonumber(data.payment) or 0) end
    if data.expiry then home.data.expiry = data.expiry end

    home:Save()
    Housing:BroadcastHome(home)
end)

RegisterNetEvent('Housing:server:SaveHomeConfiguration', function(homeId, configuration, silent, field)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(configuration) ~= 'table' then return end
    if not canManageHome(src, home, nil, 'configuration') then return end

    if field then
        home.configuration[field] = configuration
    else
        home.configuration = configuration
    end

    home:Save()
    Housing:BroadcastHome(home)
    if not silent then
        Housing:Notify(src, 'Konfigurasi rumah disimpan', 'success')
    end
end)

lib.callback.register('Housing:server:RenameHouse', function(source, homeId, name)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not name or name == '' then return false end
    if not canManageHome(src, home, nil, 'rename') then return false end

    home:SetProperty('name', name)
    Housing:BroadcastHome(home)
    TriggerClientEvent('Housing:client:RenameHouse', -1, homeId, name)
    return true
end)

RegisterNetEvent('Housing:server:UpdateEntrance', function(homeId, coords)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(coords) ~= 'table' then return end
    if not canManageHome(src, home, nil, 'configuration') then return end

    home:SetProperty('entry', coords)
    Housing:BroadcastHome(home)
end)

RegisterNetEvent('Housing:server:UpdateThumbnail', function(homeId, thumbnail)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end
    if not canManageHome(src, home, nil, 'configuration') then return end

    home:SetProperty('thumbnail', thumbnail)
    TriggerClientEvent('Housing:client:UpdateThumbnail', -1, homeId, thumbnail)
end)

RegisterNetEvent('Housing:server:CreateHome', function(data)
    local src = source
    local home, err = Housing:CreateHome(src, data)
    if not home then
        Housing:Notify(src, err or 'Gagal membuat rumah', 'error')
        return
    end

    Housing:Notify(src, ('Rumah %s dibuat'):format(home.name), 'success')
    TriggerClientEvent('Housing:client:LoadHome', src, Minify(home:Snapshot()))
end)

RegisterNetEvent('Housing:server:DeleteHome', function(data)
    local src = source
    local homeId = type(data) == 'table' and data.identifier or data
    local home = Housing:GetHome(homeId)
    if not home then return end
    if not Housing:IsAdmin(src) and not Housing:CanManage(src, home, 'deletehome') then return end

    Housing:DeleteHome(home, src)
end)

RegisterNetEvent('Housing:server:DeleteApartment', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end
    if not Housing:IsAdmin(src) and not Housing:CanManage(src, home, 'deletehome') then return end

    local apt = home:GetApartment(aptId)
    if not apt then return end

    table.remove(home.apartments, aptId)
    MySQL.query(('DELETE FROM `%s` WHERE `id` = ?'):format(T.apartments), { apt.id })

    TriggerClientEvent('Housing:client:RemoveApartment', -1, homeId, aptId)
end)

---@param src number
---@param home table
---@param aptId string|number|nil
---@param price number
---@return boolean
local function chargeBuyer(src, home, aptId, price)
    if price <= 0 then return true end
    if not Housing:HasMoney(src, Config.Server.defaultAccount, price) then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return false
    end

    if not Housing:RemoveMoney(src, Config.Server.defaultAccount, price, 'housing-buy') then return false end

    if home.realestate and JobConfig.jobs[home.realestate] and home.realestateFee > 0 then
        local fee = math.floor(price * (home.realestateFee / 100))
        if fee > 0 then
            exports['qb-banking']:AddMoney(home.realestate, fee, 'housing-fee')
        end
    end

    if Config.Server.tax.enable then
        local tax = math.floor(price * Config.Server.tax.percentage)
        if tax > 0 then
            exports['qb-banking']:AddMoney(Config.Server.tax.society, tax, 'housing-tax')
        end
    end

    return true
end

RegisterNetEvent('Housing:server:BuyHome', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if not identifier then return end
    if home.owner then
        Housing:Notify(src, 'Rumah sudah dimiliki', 'error')
        return
    end
    if home.configuration.disableBuy then
        Housing:Notify(src, 'Rumah ini tidak dijual', 'error')
        return
    end

    local limit = Config.Server.maxHomesPerPlayer
    if limit > 0 and Housing:GetOwnedCount(identifier) >= limit then
        Housing:Notify(src, ('Batas rumah tercapai (%d)'):format(limit), 'error')
        return
    end

    if not chargeBuyer(src, home, nil, home.price) then return end

    Housing:SetOwner(home, identifier, nil, Housing:Name(src))
    Housing:BroadcastHome(home)
    Housing:Notify(src, ('Kamu membeli %s'):format(home.name), 'success')
    Housing:Log('buy', ('%s membeli %s'):format(identifier, home.name), home, Housing:Name(src))
end)

RegisterNetEvent('Housing:server:BuyApartment', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not home:IsApartment() then return end

    local identifier = Housing:GetIdentifier(src)
    if not identifier then return end

    local apt
    for i = 1, #home.apartments do
        if not home.apartments[i].owner then
            apt = home.apartments[i]
            break
        end
    end

    if not apt then
        Housing:Notify(src, 'Tidak ada unit kosong', 'error')
        return
    end

    if not chargeBuyer(src, home, apt.apartment, apt.price) then return end

    Housing:SetOwner(home, identifier, apt.apartment, Housing:Name(src))
    Housing:BroadcastHome(home)
    Housing:Notify(src, ('Kamu membeli unit %s'):format(apt.name), 'success')
end)

RegisterNetEvent('Housing:server:ChoosePlan', function(homeId, downpayment, plan)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(plan) ~= 'table' then return end

    local identifier = Housing:GetIdentifier(src)
    if not identifier or home.owner then return end

    downpayment = tonumber(downpayment) or 0
    if not chargeBuyer(src, home, nil, downpayment) then return end

    local duration = tonumber(plan.duration) or Config.Server.mortgage.months
    local interest = tonumber(plan.interest) or 0
    local remaining = math.max(home.price - downpayment, 0)
    local payment = math.floor(remaining / math.max(duration, 1) * (1 + interest / 100))

    MySQL.insert(('INSERT INTO `%s` (`home`, `owner`, `downpayment`, `interest`, `duration`, `payment`, `lastPayment`, `remaining`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(T.mortgages), {
        homeId, identifier, downpayment, interest, duration, payment, os.time(), remaining,
    })

    home.payment = payment
    home:SetProperty('payment', payment)
    home.mortgages[#home.mortgages + 1] = {
        home = homeId, owner = identifier, downpayment = downpayment, interest = interest,
        duration = duration, payment = payment, lastPayment = os.time(), remaining = remaining,
    }

    Housing:SetOwner(home, identifier, nil, Housing:Name(src))
    Housing:BroadcastHome(home)
    Housing:Notify(src, ('Kamu membeli %s dengan cicilan'):format(home.name), 'success')
end)

RegisterNetEvent('Housing:server:SellHome', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if not identifier or not home:IsOwner(identifier, aptId) then return end
    if not home:HasOwnerPermission(identifier, 'sell') then
        Housing:Notify(src, 'Izin jual tidak aktif', 'error')
        return
    end

    local price = home:IsApartment() and (home:GetApartment(aptId) or {}).price or home.price
    local refund = math.floor((price or 0) * (JobConfig.sellHome.resellPercentage / 100))

    Housing:ClearOwner(home, aptId)
    if refund > 0 then
        Housing:AddMoney(src, Config.Server.defaultAccount, refund, 'housing-sell')
    end

    Housing:BroadcastHome(home)
    Housing:Notify(src, ('Rumah dijual, kamu menerima $%d'):format(refund), 'success')
    Housing:Log('sell', ('%s menjual %s'):format(identifier, home.name), home, Housing:Name(src))
end)

RegisterNetEvent('Housing:server:TransferOwner', function(homeId, targetSrc, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end

    local identifier = Housing:GetIdentifier(src)
    if not identifier or not home:IsOwner(identifier, aptId) then return end
    if not home:HasOwnerPermission(identifier, 'transfer') then
        Housing:Notify(src, 'Izin transfer tidak aktif', 'error')
        return
    end

    local target = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        Housing:Notify(src, 'Pemain target tidak ditemukan', 'error')
        return
    end

    local targetIdentifier = target.PlayerData.citizenid
    home.keys:RemoveHolder(identifier)
    Housing:SetOwner(home, targetIdentifier, aptId, Housing:Name(targetSrc))

    Housing:BroadcastHome(home)
    Housing:Notify(targetSrc, ('Kamu menerima %s'):format(home.name), 'success')
    Housing:Log('transfer', ('%s memindahkan %s ke %s'):format(identifier, home.name, targetIdentifier), home, Housing:Name(src))
end)

RegisterNetEvent('Housing:server:AddArea', function(homeId, area)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(area) ~= 'table' then return end
    if not canManageHome(src, home, nil, 'configuration') then return end

    home.area = area
    home:Save()
    Housing:BroadcastHome(home)
end)

RegisterNetEvent('Housing:server:SaveAreaPreset', function(name, area)
    if type(area) ~= 'table' or not name then return end

    MySQL.insert(('INSERT INTO `%s` (`name`, `points`, `height`) VALUES (?, ?, ?)'):format(T.presets), {
        name, json.encode(area.points or {}), area.height or 0,
    })
end)

RegisterNetEvent('Housing:server:AddStarterApartment', function(homeId)
    local src = source
    if not Housing:IsAdmin(src) then return end

    Housing.starter[homeId] = true
    MySQL.insert(('INSERT IGNORE INTO `%s` (`home`) VALUES (?)'):format(T.starter), { homeId })
    TriggerClientEvent('Housing:client:RefreshStarterApartment', -1, Housing.starter)
end)

RegisterNetEvent('Housing:server:RemoveStarterApartment', function(homeId)
    local src = source
    if not Housing:IsAdmin(src) then return end

    Housing.starter[homeId] = nil
    MySQL.query(('DELETE FROM `%s` WHERE `home` = ?'):format(T.starter), { homeId })
    TriggerClientEvent('Housing:client:RefreshStarterApartment', -1, Housing.starter)
end)

RegisterNetEvent('Housing:server:SetHouseDisabled', function(homeId, disabled)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not Housing:IsAdmin(src) then return end

    home:SetProperty('disabled', disabled and true or false)
    TriggerClientEvent('Housing:client:SetHouseDisabled', -1, homeId, home.disabled)
end)