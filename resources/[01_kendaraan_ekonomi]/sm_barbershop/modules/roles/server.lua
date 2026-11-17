local config = Config
local limits = config.limits

local Roles = {}

---@type table<string, BarberRole[]>
local byShop = {}

---@type table<string, boolean>
local known = {}

for i = 1, #config.permissions do
    known[config.permissions[i].key] = true
end

---@param list any
---@return table<string, boolean>?
local function permissionSet(list)
    if type(list) ~= 'table' then return end

    local set = {}

    for i = 1, #list do
        local key = list[i]

        if type(key) ~= 'string' or not known[key] then return end

        set[key] = true
    end

    return set
end

---@param set table<string, boolean>
---@return string[]
local function permissionList(set)
    local list = {}

    for i = 1, #config.permissions do
        local key = config.permissions[i].key

        if set[key] then
            list[#list + 1] = key
        end
    end

    return list
end

---@param raw any
---@return table<string, boolean>
local function decode(raw)
    local ok, decoded = pcall(json.decode, type(raw) == 'string' and raw or 'null')

    return ok and permissionSet(decoded) or {}
end

---@param shopId string
---@return BarberRole[]
local function listOf(shopId)
    local list = byShop[shopId]

    if not list then
        list = {}
        byShop[shopId] = list
    end

    return list
end

function Roles.init()
    local rows = Storage.loadRoles()

    for i = 1, #rows do
        local row = rows[i]
        local list = listOf(row.shop_id)

        list[#list + 1] = {
            id = row.id,
            key = row.role_key or ('r%d'):format(row.id),
            label = row.label,
            permissions = decode(row.permissions),
        }
    end

    for i = 1, #config.shops do
        local list = listOf(config.shops[i].id)

        if #list == 0 then
            for j = 1, #config.roles do
                local default = config.roles[j]
                local permissions = permissionSet(default.permissions) or {}
                local id = Storage.addRole(config.shops[i].id, default.key, default.label, json.encode(permissionList(permissions)))

                if id then
                    list[#list + 1] = { id = id, key = default.key, label = default.label, permissions = permissions }
                end
            end
        end
    end
end

---@param shopId string
---@return BarberRole[]
function Roles.list(shopId)
    return listOf(shopId)
end

---@param shopId string
---@param key any
---@return BarberRole?
function Roles.get(shopId, key)
    if type(key) ~= 'string' then return end

    local list = listOf(shopId)

    for i = 1, #list do
        if list[i].key == key then return list[i] end
    end
end

---@param shopId string
---@param key string?
---@return table<string, boolean>
function Roles.permissions(shopId, key)
    local role = Roles.get(shopId, key)

    return role and role.permissions or {}
end

---@param role BarberRole
---@return string[]
function Roles.permissionList(role)
    return permissionList(role.permissions)
end

---@param shopId string
---@param key string?
---@param label any
---@param permissions any
---@return BarberRole?
---@return string?
function Roles.save(shopId, key, label, permissions)
    local name = Text.name(label, limits.minRoleName, limits.maxRoleName)

    if not name then
        return nil, ('Nama role harus %d-%d karakter, hanya huruf, angka, spasi, dan . \' & -'):format(limits.minRoleName, limits.maxRoleName)
    end

    local set = permissionSet(permissions)

    if not set then return nil, 'Izin tidak valid.' end

    local list = listOf(shopId)

    for i = 1, #list do
        if list[i].key ~= key and list[i].label:lower() == name:lower() then
            return nil, 'Nama role sudah dipakai.'
        end
    end

    local encoded = json.encode(permissionList(set))

    if key then
        local role = Roles.get(shopId, key)

        if not role then return nil, 'Role tidak ditemukan.' end

        role.label = name
        role.permissions = set
        Storage.saveRole(role.id, name, encoded)

        return role
    end

    if #list >= limits.maxRoles then return nil, ('Maksimal %d role.'):format(limits.maxRoles) end

    local id = Storage.addRole(shopId, nil, name, encoded)

    if not id then return nil, 'Role gagal disimpan.' end

    ---@type BarberRole
    local role = { id = id, key = ('r%d'):format(id), label = name, permissions = set }

    list[#list + 1] = role

    return role
end

---@param shopId string
---@param key string
---@return boolean
function Roles.remove(shopId, key)
    local list = listOf(shopId)

    for i = 1, #list do
        if list[i].key == key then
            Storage.removeRole(list[i].id)
            table.remove(list, i)

            return true
        end
    end

    return false
end

return Roles
