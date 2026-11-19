local T = Config.Server.tables

---@param src number
---@return table?
function Housing:Player(src)
    return QBCore.Functions.GetPlayer(src)
end

---@param src number
---@return string?
function Housing:Name(src)
    local player = self:Player(src)
    if not player then return nil end
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

---@param identifier string
---@return number?
function Housing:SourceByIdentifier(identifier)
    for _, src in ipairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(src)
        if player and player.PlayerData.citizenid == identifier then
            return src
        end
    end
end

---@param src number
---@return boolean
function Housing:IsPolice(src)
    local player = self:Player(src)
    if not player then return false end

    local job = player.PlayerData.job
    local minGrade = Config.robbery.policeName[job.name]
    if not minGrade then return false end
    return job.grade.level >= minGrade
end

---@param src number
---@param account string
---@param amount number
---@return boolean
function Housing:HasMoney(src, account, amount)
    local player = self:Player(src)
    if not player then return false end
    return (player.PlayerData.money[account] or 0) >= amount
end

---@param src number
---@param account string
---@param amount number
---@param reason string
---@return boolean
function Housing:RemoveMoney(src, account, amount, reason)
    local player = self:Player(src)
    if not player then return false end
    return player.Functions.RemoveMoney(account, amount, reason) == true
end

---@param src number
---@param account string
---@param amount number
---@param reason string
function Housing:AddMoney(src, account, amount, reason)
    local player = self:Player(src)
    if not player then return end
    player.Functions.AddMoney(account, amount, reason)
end

---@param src number
---@param item string
---@param count number
---@return boolean
function Housing:HasItem(src, item, count)
    local player = self:Player(src)
    if not player then return false end
    local entry = player.Functions.GetItemByName(item)
    return entry ~= nil and entry.amount >= (count or 1)
end

---@param src number
---@param item string
---@param count number
---@return boolean
function Housing:RemoveItem(src, item, count)
    local player = self:Player(src)
    if not player then return false end
    return player.Functions.RemoveItem(item, count or 1) == true
end

---@param src number
---@param item string
---@param count number
function Housing:AddItem(src, item, count)
    local player = self:Player(src)
    if not player then return end
    player.Functions.AddItem(item, count or 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
end

---@param src number
---@param message string
---@param notifyType? string
function Housing:Notify(src, message, notifyType)
    TriggerClientEvent('Housing:notify', src, 'Perumahan', message, notifyType or 'info', 5000)
end

---@param home table
---@param message string
---@param notifyType? string
---@param aptId string|number|nil
function Housing:Alert(home, message, notifyType, aptId)
    local seen = {}
    local function send(identifier)
        if not identifier or seen[identifier] then return end
        seen[identifier] = true
        local src = Housing:SourceByIdentifier(identifier)
        if src then Housing:Notify(src, message, notifyType) end
    end

    send(home:GetOwner(home.owner or '', aptId))
    for _, holder in ipairs(home.keys.holders) do
        send(holder.identifier)
    end
end

---@param home table
function Housing:SyncKeys(home)
    TriggerClientEvent('Housing:client:SyncKeys', -1, home.identifier, nil, home.keys:Snapshot())
end

---@param home table
---@param identifier string
---@param aptId string|number|nil
---@param name string?
---@return boolean
function Housing:SetOwner(home, identifier, aptId, name)
    if not home then return false end

    if home:IsApartment() and aptId then
        local apt = home:GetApartment(aptId)
        if not apt then return false end
        apt.owner = identifier
        apt:Save()
    else
        home.owner = identifier
        home.bought_at = os.time()
        MySQL.update(('UPDATE `%s` SET `owner` = ?, `bought_at` = ? WHERE `identifier` = ?'):format(T.homes),
            { identifier, home.bought_at, home.identifier })
    end

    home.keys:AddHolder(identifier, name)
    self:SyncKeys(home)
    TriggerClientEvent('Housing:client:UpdateOwner', -1, home.identifier, identifier, aptId)
    return true
end

---@param home table
---@param aptId string|number|nil
function Housing:ClearOwner(home, aptId)
    if not home then return end

    if home:IsApartment() and aptId then
        local apt = home:GetApartment(aptId)
        if apt then
            home.keys:RemoveHolder(apt.owner)
            apt.owner = nil
            apt:Save()
        end
    else
        if home.owner then home.keys:RemoveHolder(home.owner) end
        home:ClearOwner()
    end

    self:SyncKeys(home)
    TriggerClientEvent('Housing:client:UpdateOwner', -1, home.identifier, nil, aptId)
end

---@param src number
---@param data table
---@return table?, string?
function Housing:CreateHome(src, data)
    if type(data) ~= 'table' then return nil, 'data tidak valid' end
    if not data.name or data.name == '' then return nil, 'nama rumah kosong' end

    local complex = data.complex or 'Individual'
    if not Config.Server.allowedComplex[complex] then return nil, 'complex tidak dikenal' end

    local homeType = data.type or 'shell'
    if not Config.Server.allowedType[homeType] then return nil, 'tipe tidak dikenal' end

    local identifier = data.identifier
    if not identifier or identifier == '' then
        identifier = ('%s_%s'):format(
            data.name:lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', ''),
            math.random(1000, 9999)
        )
    end
    if Housing.homes[identifier] then return nil, 'identifier sudah dipakai' end

    local configuration = data.configuration or {
        maxStorage = Config.configuration.DefaultMaxStorage,
        maxGarages = Config.configuration.DefaultMaxGarages,
        limitWardrobes = Config.configuration.LimitWardrobes,
        limitKeys = Config.configuration.LimitKeys,
        upgrades = Config.configuration.Upgrades,
        garage = Config.configuration.Garage,
        cctv = Config.configuration.CCTV,
        rename = Config.configuration.Rename,
        bill = Config.configuration.Bill,
        blip = Config.configuration.Blip,
        disableCatalogue = Config.configuration.DisableCatalogue,
        rentTimer = Config.configuration.RentTimer,
        autoRemove = Config.configuration.AutoRemove,
        rentable = false,
        disableBuy = false,
    }

    local permission = data.permission or table.clone(Config.configuration.DefaultOwnerPermission)
    local entry = data.entry or { x = 0, y = 0, z = 0, w = 0 }

    local row = {
        identifier = identifier,
        name = data.name,
        price = data.price or 0,
        payment = data.payment or 0,
        type = homeType,
        complex = complex,
        realestate = data.realestate,
        entry = json.encode(entry),
        area = data.area and json.encode(data.area) or nil,
        data = json.encode(data.properties and data.properties.data or data.data or {}),
        configuration = json.encode(configuration),
        permission = json.encode(permission),
        thumbnail = data.thumbnail,
        interior = data.interior,
        placement = data.placement and json.encode(data.placement) or nil,
        created_at = os.time(),
        realestateFee = data.realestateFee or 0,
    }

    MySQL.insert(('INSERT INTO `%s` (`identifier`, `name`, `price`, `payment`, `type`, `complex`, `realestate`, `entry`, `area`, `data`, `configuration`, `permission`, `thumbnail`, `interior`, `placement`, `created_at`, `realestateFee`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(T.homes), {
        row.identifier, row.name, row.price, row.payment, row.type, row.complex, row.realestate,
        row.entry, row.area, row.data, row.configuration, row.permission, row.thumbnail,
        row.interior, row.placement, row.created_at, row.realestateFee,
    })

    local home = HousingHome:new(row)
    Housing.homes[identifier] = home
    Housing:BroadcastHome(home)
    Housing:Log('create', ('%s membuat rumah %s (%s)'):format(src, home.name, identifier), home, self:Name(src))

    return home
end

---@param home table
---@param src number?
function Housing:DeleteHome(home, src)
    if not home then return end

    home:Delete()
    Housing.homes[home.identifier] = nil
    Housing.starter[home.identifier] = nil

    TriggerClientEvent('Housing:client:DeleteHome', -1, home.identifier)
    Housing:Log('delete', ('%s menghapus rumah %s'):format(src or '-', home.name), home.identifier, src and self:Name(src))
end

---@param src number
---@param home table
---@param aptId string|number|nil
---@return boolean
function Housing:CanInteractHome(src, home, aptId)
    if not home then return false end
    local identifier = self:GetIdentifier(src)
    if not identifier then return false end

    return home:HasAccess(identifier, nil, aptId) or self:IsPolice(src) or self:IsAdmin(src)
end

---@param identifier string
---@return table?
function Housing:GetStarterApartment(identifier)
    if not Config.Server.starterApartment.enabled then return nil end
    for id, owned in pairs(Housing.starter) do
        local home = Housing:GetHome(id)
        if home and home.owner == identifier then return home end
    end
end