local T = Config.Server.tables

HousingApartment = {}
HousingApartment.__index = HousingApartment

---@param row table
---@return table
function HousingApartment:new(row)
    local self = setmetatable({}, HousingApartment)
    self.id = row.id
    self.home = row.home
    self.apartment = tostring(row.id)
    self.name = row.name
    self.price = tonumber(row.price) or 0
    self.owner = row.owner
    self.locked = row.locked == 1 or row.locked == true

    local function decode(value)
        if type(value) == 'table' then return value end
        if type(value) == 'string' and value ~= '' then
            local ok, parsed = pcall(json.decode, value)
            if ok and type(parsed) == 'table' then return parsed end
        end
        return {}
    end

    self.storages = decode(row.storages)
    self.wardrobes = decode(row.wardrobes)
    self.furniture = decode(row.furniture)
    return self
end

---@param aptId number
---@return table?
function HousingApartment:GetById(aptId)
    return nil
end

function HousingApartment:Save()
    MySQL.update(('UPDATE `%s` SET `owner` = ?, `locked` = ?, `storages` = ?, `wardrobes` = ?, `furniture` = ? WHERE `id` = ?'):format(T.apartments), {
        self.owner, self.locked and 1 or 0, json.encode(self.storages),
        json.encode(self.wardrobes), json.encode(self.furniture), self.id,
    })
end