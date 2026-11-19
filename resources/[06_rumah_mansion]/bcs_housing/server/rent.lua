local T = Config.Server.tables

---@param src number
---@param home table
---@return boolean
local function isOwner(src, home)
    return home:IsOwner(Housing:GetIdentifier(src))
end

RegisterNetEvent('Housing:server:UpdateRentOptions', function(homeId, data)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or type(data) ~= 'table' or not isOwner(src, home) then return end

    home.data.rentOptions = {
        price = tonumber(data.price) or Config.configuration.DefaultRentOptions.price,
        duration = tonumber(data.duration) or Config.configuration.DefaultRentOptions.duration,
        durationType = data.durationType == 'week' and 'week' or 'day',
    }
    home:Save()
end)

RegisterNetEvent('Housing:server:SetRented', function(homeId, checked)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not isOwner(src, home) then return end

    home.configuration.rentable = checked == true
    home:Save()
    Housing:BroadcastHome(home)
end)

RegisterNetEvent('Housing:server:RentHouse', function(homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not home.configuration.rentable then return end

    local identifier = Housing:GetIdentifier(src)
    if not identifier then return end
    if home.rent and home.rent.isRented then
        Housing:Notify(src, 'Rumah sedang disewa', 'error')
        return
    end

    local options = home.data.rentOptions or Config.configuration.DefaultRentOptions
    local dueAt = os.time() + ((options.durationType == 'week' and options.duration * 7 or options.duration) * 86400)

    home.rent = {
        isRented = true,
        tenant = identifier,
        price = options.price,
        duration = options.duration,
        durationType = options.durationType,
        rentedAt = os.time(),
        dueAt = dueAt,
        overdue = 0,
        autoRemove = home.configuration.autoRemove or Config.configuration.AutoRemove,
        permission = { doorlock = true, garage = true, wardrobe = true, storage = true, furniture = true },
    }

    home:Save()
    Housing:BroadcastHome(home)
    Housing:Notify(src, ('Kamu menyewa %s'):format(home.name), 'success')
    Housing:Log('rent', ('%s menyewa %s'):format(identifier, home.name), home, Housing:Name(src))
end)

lib.callback.register('Housing:server:TenantPayRent', function(source, homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not home.rent or not home.rent.isRented then return false end

    local identifier = Housing:GetIdentifier(src)
    if home.rent.tenant ~= identifier then return false end

    local price = home.rent.price or 0
    if not Housing:RemoveMoney(src, Config.Server.rent.account, price, 'housing-rent') then
        Housing:Notify(src, 'Uang tidak cukup', 'error')
        return false
    end

    local ownerIdentifier = home:GetOwner(home.owner or '')
    local ownerSrc = ownerIdentifier and Housing:SourceByIdentifier(ownerIdentifier)
    if ownerSrc and price > 0 then
        Housing:AddMoney(ownerSrc, Config.Server.rent.account, price, 'housing-rent-income')
    end

    home.rent.dueAt = os.time() + ((home.rent.durationType == 'week' and home.rent.duration * 7 or home.rent.duration) * 86400)
    home.rent.overdue = 0
    home:Save()

    Housing:Notify(src, 'Sewa dibayar', 'success')
    return true
end)

lib.callback.register('Housing:server:EvictTenant', function(source, homeId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not isOwner(src, home) then return false end
    if not home.rent or not home.rent.isRented then return false end

    local tenantIdentifier = home.rent.tenant
    home.rent.isRented = false
    home.rent.tenant = nil
    home.rent.overdue = 0
    home:Save()

    local tenantSrc = tenantIdentifier and Housing:SourceByIdentifier(tenantIdentifier)
    if tenantSrc then Housing:Notify(tenantSrc, ('Sewa %s dihentikan'):format(home.name), 'error') end

    Housing:BroadcastHome(home)
    Housing:Log('evict', ('%s mengusir %s dari %s'):format(Housing:Name(src) or src, tenantIdentifier or '-', home.name), home, Housing:Name(src))
    return true
end)

lib.callback.register('Housing:server:CheckRent', function(source, homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home or not home.rent then return 0 end
    return home.rent.dueAt or 0
end)

lib.callback.register('Housing:server:GetRentData', function(source, homeId)
    local home = Housing:GetHome(homeId)
    if not home then return nil end
    return home.rent
end)