local T = Config.Server.tables

HousingHome = {}
HousingHome.__index = HousingHome

---@param value any
---@param default table
---@return table
local function asTable(value, default)
    if type(value) == 'table' then return value end
    if type(value) == 'string' and value ~= '' then
        local ok, parsed = pcall(json.decode, value)
        if ok and type(parsed) == 'table' then return parsed end
    end
    return default
end

---@param value any
---@return number|nil
local function asNumber(value)
    if type(value) == 'number' then return value end
    if type(value) == 'string' then return tonumber(value) end
end

---@param value any
---@param default table
---@return table
local function ensureArray(value, default)
    local tbl = asTable(value, default)
    if #tbl == 0 and next(tbl) ~= nil then
        local list = {}
        for _, entry in pairs(tbl) do
            list[#list + 1] = entry
        end
        return list
    end
    return tbl
end

---@param row table
---@return table
function HousingHome:new(row)
    local self = setmetatable({}, HousingHome)

    self.identifier = row.identifier
    self.name = row.name or ''
    self.price = asNumber(row.price) or 0
    self.payment = asNumber(row.payment) or 0
    self.type = row.type or 'shell'
    self.complex = row.complex or 'Individual'
    self.owner = row.owner
    self.realestate = row.realestate
    self.entry = asTable(row.entry, {})
    self.area = asTable(row.area, nil)
    self.data = asTable(row.data, {})
    self.configuration = asTable(row.configuration, {})
    self.permission = asTable(row.permission, {})
    self.thumbnail = row.thumbnail
    self.interior = row.interior
    self.placement = asTable(row.placement, nil)
    self.disabled = row.disabled == 1 or row.disabled == true
    self.locked = row.locked == 1 or row.locked == true
    self.created_at = asNumber(row.created_at) or 0
    self.bought_at = asNumber(row.bought_at) or 0
    self.lastLogin = asNumber(row.lastLogin) or 0
    self.realestateFee = asNumber(row.realestateFee) or 0

    self.doors = {}
    self.garages = {}
    self.teleports = {}
    self.storages = {}
    self.wardrobes = {}
    self.furniture = {}
    self.apartments = {}
    self.rent = nil
    self.mortgages = {}

    self.inside = {}
    self.keys = HousingKeys:new(self.identifier)

    return self
end

---@return boolean
function HousingHome:IsApartment()
    return self.complex == 'Apartment'
end

---@param aptId string|number|nil
---@return table?
function HousingHome:GetApartment(aptId)
    if not aptId or aptId == 'nil' then return nil end
    aptId = tonumber(aptId) or aptId
    for i = 1, #self.apartments do
        if tonumber(self.apartments[i].apartment) == tonumber(aptId) then
            return self.apartments[i]
        end
    end
end

---@param identifier string
---@param aptId string|number|nil
---@return string?
function HousingHome:GetOwner(identifier, aptId)
    if self:IsApartment() then
        local apt = self:GetApartment(aptId)
        if apt then return apt.owner end
        if not aptId then
            for i = 1, #self.apartments do
                if self.apartments[i].owner == identifier then return identifier end
            end
        end
        return nil
    end
    return self.owner
end

---@param identifier string
---@param aptId string|number|nil
---@return boolean
function HousingHome:IsOwner(identifier, aptId)
    if not identifier then return false end
    if self:IsApartment() then
        if aptId and aptId ~= 'nil' then
            local apt = self:GetApartment(aptId)
            return apt ~= nil and apt.owner == identifier
        end
        for i = 1, #self.apartments do
            if self.apartments[i].owner == identifier then return true end
        end
        return false
    end
    return self.owner == identifier
end

---@param identifier string
---@param permission string?
---@param aptId string|number|nil
---@return boolean
function HousingHome:IsKeyOwner(identifier, permission, aptId)
    if not identifier then return false end
    if self:IsOwner(identifier, aptId) then return true end
    return self.keys:HasKey(identifier, permission)
end

---@param identifier string
---@param permission string?
---@param aptId string|number|nil
---@return boolean
function HousingHome:IsTenant(identifier, permission, aptId)
    if not identifier then return false end
    if not self.rent or not self.rent.isRented then return false end
    if self.rent.tenant ~= identifier then return false end
    if aptId and self.rent.aptId and tonumber(self.rent.aptId) ~= tonumber(aptId) then return false end
    if not permission then return true end
    return self.rent.permission ~= nil and self.rent.permission[permission] == true
end

---@param identifier string
---@param permission string
---@param aptId string|number|nil
---@return boolean
function HousingHome:HasAccess(identifier, permission, aptId)
    return self:IsKeyOwner(identifier, permission, aptId) or self:IsTenant(identifier, permission, aptId)
end

---@param identifier string
---@param permission string
---@return boolean
function HousingHome:HasOwnerPermission(identifier, permission)
    if not self:IsOwner(identifier) then return false end
    if self.permission[permission] == nil then return false end
    return self.permission[permission] == true
end

---@param identifier string
---@param aptId string|number|nil
---@return boolean
function HousingHome:CanEnter(identifier, aptId)
    if self.disabled then return false end
    if not self.locked then return true end
    if not identifier then return false end
    return self:IsKeyOwner(identifier, 'doorlock', aptId)
        or self:IsTenant(identifier, 'doorlock', aptId)
end

---@param locked boolean
function HousingHome:SetLocked(locked)
    self.locked = locked and true or false
    MySQL.update(('UPDATE `%s` SET `locked` = ? WHERE `identifier` = ?'):format(T.homes),
        { self.locked and 1 or 0, self.identifier })
    TriggerClientEvent('Housing:client:LockHome', -1, self.identifier, nil, self.locked)
end

---@param src number
---@param aptId string|number|nil
function HousingHome:AddInside(src, aptId)
    self.inside[src] = { aptId = aptId, at = os.time() }
end

---@param src number
function HousingHome:RemoveInside(src)
    self.inside[src] = nil
end

---@param aptId string|number|nil
---@return number[]
function HousingHome:GetInside(aptId)
    local list = {}
    for src, data in pairs(self.inside) do
        if not aptId or (data.aptId and tonumber(data.aptId) == tonumber(aptId)) then
            list[#list + 1] = src
        end
    end
    return list
end

---@param aptId string|number|nil
---@return table
function HousingHome:GetData(aptId)
    if self:IsApartment() and aptId and aptId ~= 'nil' then
        local apt = self:GetApartment(aptId)
        if apt then
            return {
                storages = apt.storages or {},
                wardrobes = apt.wardrobes or {},
                furniture = apt.furniture or {},
                doors = self.doors,
            }
        end
    end

    return {
        storages = self.storages,
        wardrobes = self.wardrobes,
        furniture = self.furniture,
        doors = self.doors,
    }
end

---@param aptId string|number|nil
---@return table
function HousingHome:Snapshot(aptId)
    local properties = {
        name = self.name,
        price = self.price,
        payment = self.payment,
        type = self.type,
        complex = self.complex,
        entry = self.entry,
        area = self.area,
        data = self.data,
        owner = self:GetOwner(self.owner or '', aptId),
        realestate = self.realestate,
        status = self.owner and 'owned' or nil,
        rent = self.rent,
    }

    if self:IsApartment() then
        properties.owner = nil
        local apt = self:GetApartment(aptId)
        if apt then
            properties.owner = apt.owner
        end
    end

    return {
        identifier = self.identifier,
        properties = properties,
        configuration = self.configuration,
        permission = self.permission,
        thumbnail = self.thumbnail,
        disabled = self.disabled,
        doors = self.doors,
        garages = self.garages,
        teleports = self.teleports,
        apartments = self.apartments,
        keys = self.keys:Snapshot(),
        mortgages = self.mortgages,
        created_at = self.created_at,
        bought_at = self.bought_at,
    }
end

---@param key string
---@param value any
function HousingHome:SetProperty(key, value)
    local column = ({ entry = 'entry', area = 'area', data = 'data', configuration = 'configuration',
        permission = 'permission', thumbnail = 'thumbnail', disabled = 'disabled', owner = 'owner',
        realestate = 'realestate', price = 'price', payment = 'payment', name = 'name' })[key]
    if not column then return end

    if key == 'disabled' then
        self.disabled = value and true or false
        value = self.disabled and 1 or 0
    elseif key == 'owner' or key == 'realestate' or key == 'thumbnail' then
        self[key] = value
    elseif key == 'price' or key == 'payment' or key == 'name' then
        self[key] = value
    else
        self[key] = value
        value = json.encode(value)
    end

    MySQL.update(('UPDATE `%s` SET `%s` = ? WHERE `identifier` = ?'):format(T.homes, column),
        { value, self.identifier })
end

function HousingHome:ClearOwner()
    self.owner = nil
    self.bought_at = 0
    self.rent = nil
    MySQL.update(('UPDATE `%s` SET `owner` = NULL, `bought_at` = 0 WHERE `identifier` = ?'):format(T.homes),
        { self.identifier })
    self.keys:Clear()
end

function HousingHome:Save()
    MySQL.update(('UPDATE `%s` SET `entry` = ?, `area` = ?, `data` = ?, `configuration` = ?, `permission` = ?, `placement` = ? WHERE `identifier` = ?'):format(T.homes), {
        json.encode(self.entry), self.area and json.encode(self.area) or nil, json.encode(self.data),
        json.encode(self.configuration), json.encode(self.permission),
        self.placement and json.encode(self.placement) or nil, self.identifier,
    })
end

function HousingHome:Delete()
    for _, table in ipairs({ T.doors, T.garages, T.teleports, T.storages, T.wardrobes,
        T.furniture, T.keys, T.apartments, T.mortgages, T.bills }) do
        MySQL.query(('DELETE FROM `%s` WHERE `home` = ?'):format(table), { self.identifier })
    end
    MySQL.query(('DELETE FROM `%s` WHERE `identifier` = ?'):format(T.homes), { self.identifier })
end