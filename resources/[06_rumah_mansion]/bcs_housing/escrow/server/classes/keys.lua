local T = Config.Server.tables

HousingKeys = {}
HousingKeys.__index = HousingKeys

---@param homeId string
---@param list table?
---@param holders table?
---@return table
function HousingKeys:new(homeId, list, holders)
    local self = setmetatable({}, HousingKeys)
    self.homeId = homeId
    self.list = list or {}
    self.holders = holders or {}
    return self
end

---@param holder table
---@return table
local function defaultPermissions(holder)
    local perms = holder.permissions or {}
    for _, name in ipairs(Config.Server.permissions) do
        if perms[name] == nil then
            perms[name] = name == 'doorlock'
                or name == 'garage'
                or name == 'wardrobe'
                or name == 'storage'
        end
    end
    holder.permissions = perms
    return holder
end

---@param identifier string
---@return table?
function HousingKeys:GetHolder(identifier)
    for i = 1, #self.holders do
        if self.holders[i].identifier == identifier then
            return self.holders[i], i
        end
    end
end

---@param identifier string
---@param permission? string
---@return boolean
function HousingKeys:HasKey(identifier, permission)
    local holder = self:GetHolder(identifier)
    if not holder then return false end
    if not permission then return true end
    return holder.permissions ~= nil and holder.permissions[permission] == true
end

---@param identifier string
---@param name string
---@return boolean
function HousingKeys:AddHolder(identifier, name)
    if self:GetHolder(identifier) then return false end

    local holder = defaultPermissions({ identifier = identifier, name = name or identifier })
    self.holders[#self.holders + 1] = holder

    MySQL.insert(('INSERT INTO `%s` (`home`, `holder`, `name`, `permissions`) VALUES (?, ?, ?, ?)'):format(T.keys),
        { self.homeId, identifier, holder.name, json.encode(holder.permissions) })

    return true
end

---@param identifier string
---@return boolean
function HousingKeys:RemoveHolder(identifier)
    local _, index = self:GetHolder(identifier)
    if not index then return false end

    table.remove(self.holders, index)
    MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `holder` = ?'):format(T.keys), { self.homeId, identifier })
    return true
end

---@param name string
---@param permissions table
---@return table?
function HousingKeys:CreateKey(name, permissions)
    for i = 1, #self.list do
        if self.list[i].name == name then return nil end
    end

    local key = defaultPermissions({ name = name, permissions = permissions or {} })
    self.list[#self.list + 1] = key

    local id = MySQL.insert(('INSERT INTO `%s` (`home`, `name`, `permissions`, `isList`) VALUES (?, ?, ?, 1)'):format(T.keys),
        { self.homeId, name, json.encode(key.permissions) })

    key.id = id
    return key
end

---@param name string
---@return boolean
function HousingKeys:DeleteKey(name)
    for i = 1, #self.list do
        if self.list[i].name == name then
            table.remove(self.list, i)
            MySQL.query(('DELETE FROM `%s` WHERE `home` = ? AND `name` = ? AND `isList` = 1'):format(T.keys),
                { self.homeId, name })
            return true
        end
    end
    return false
end

---@param name string
---@param permissions table
---@return boolean
function HousingKeys:UpdateKey(name, permissions)
    for i = 1, #self.list do
        if self.list[i].name == name then
            self.list[i].permissions = permissions
            MySQL.update(('UPDATE `%s` SET `permissions` = ? WHERE `home` = ? AND `name` = ? AND `isList` = 1'):format(T.keys),
                { json.encode(permissions), self.homeId, name })
            return true
        end
    end
    return false
end

function HousingKeys:Clear()
    self.list = {}
    self.holders = {}
    MySQL.query(('DELETE FROM `%s` WHERE `home` = ?'):format(T.keys), { self.homeId })
end

---@return table
function HousingKeys:Snapshot()
    return { list = self.list, holders = self.holders }
end