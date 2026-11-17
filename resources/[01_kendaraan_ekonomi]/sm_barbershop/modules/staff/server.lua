local config = Config

local Staff = {
    ---@type table<string, table<string, BarberEmployee>>
    employees = {},
    ---@type table<number, string>
    duty = {},
    ---@type table<string, table<number, string>>
    dutyByShop = {},
}

function Staff.init()
    local rows = Storage.loadEmployees()

    for i = 1, #rows do
        local row = rows[i]
        local shop = Staff.employees[row.shop_id]

        if not shop then
            shop = {}
            Staff.employees[row.shop_id] = shop
        end

        shop[row.citizenid] = {
            citizenId = row.citizenid,
            name = row.name,
            role = row.role,
            hiredAt = row.hired_at,
        }
    end
end

---@param source number
---@return table?
function Staff.getPlayer(source)
    return Core:GetPlayer(source)
end

---@param player table?
---@return string?
function Staff.citizenIdOf(player)
    return player and player.PlayerData and player.PlayerData.citizenid
end

---@param source number
---@return string?
function Staff.citizenId(source)
    return Staff.citizenIdOf(Staff.getPlayer(source))
end

---@param player table?
---@param fallback string?
---@return string
function Staff.nameOf(player, fallback)
    local charinfo = player and player.PlayerData and player.PlayerData.charinfo

    if charinfo and (charinfo.firstname or charinfo.lastname) then
        local full = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')

        return (full:gsub('^%s+', ''):gsub('%s+$', ''))
    end

    return fallback or 'Tidak diketahui'
end

---@param shopId string
---@param citizenId string?
---@return BarberEmployee?
function Staff.employee(shopId, citizenId)
    local shop = Staff.employees[shopId]

    return shop and citizenId and shop[citizenId] or nil
end

---@param shopId string
---@param citizenId string?
---@return string? role
function Staff.role(shopId, citizenId)
    if not citizenId then return end

    local shop = Shops.get(shopId)

    if shop and shop.ownerCitizenId == citizenId then
        return 'owner'
    end

    local employee = Staff.employee(shopId, citizenId)

    return employee and employee.role or nil
end

---@param source number
---@param shopId string
---@return string? role
function Staff.roleOf(source, shopId)
    return Staff.role(shopId, Staff.citizenId(source))
end

---@param shopId string
---@param role string?
---@return table<string, boolean>
function Staff.permissions(shopId, role)
    local owner = role == 'owner'
    local granted = not owner and Roles.permissions(shopId, role) or {}
    local set = { roles = owner }

    for i = 1, #config.permissions do
        local key = config.permissions[i].key

        set[key] = owner or granted[key] == true
    end

    return set
end

---@param source number
---@param shopId string
---@param action string
---@return boolean
function Staff.can(source, shopId, action)
    return Staff.permissions(shopId, Staff.roleOf(source, shopId))[action] == true
end

---@param shopId string
---@param actorRole string?
---@param targetRole string?
---@return boolean
function Staff.outranks(shopId, actorRole, targetRole)
    if not actorRole or not targetRole or targetRole == 'owner' then return false end
    if actorRole == 'owner' then return true end

    local actor = Staff.permissions(shopId, actorRole)
    local target = Staff.permissions(shopId, targetRole)
    local wider = false

    for key, granted in pairs(actor) do
        if target[key] and not granted then return false end

        if granted and not target[key] then
            wider = true
        end
    end

    return wider
end

---@param shopId string
---@param role string
---@return integer
function Staff.countRole(shopId, role)
    local total = 0

    for _, employee in pairs(Staff.employees[shopId] or {}) do
        if employee.role == role then
            total += 1
        end
    end

    return total
end

---@param citizenId string
---@return table<string, string>
function Staff.shopsOf(citizenId)
    local shops = {}

    for i = 1, #Shops.list do
        local role = Staff.role(Shops.list[i].id, citizenId)

        if role then
            shops[Shops.list[i].id] = role
        end
    end

    return shops
end

---@param source number
function Staff.syncPlayer(source)
    local citizenId = Staff.citizenId(source)

    if not citizenId then return end

    local shops = Staff.shopsOf(citizenId)

    Player(source).state:set('barberShops', next(shops) and shops or false, true)
end

---@param citizenId string
function Staff.syncCitizen(citizenId)
    local player = Core:GetPlayerByCitizenId(citizenId)

    if player then
        Staff.syncPlayer(player.PlayerData.source)
    end
end

---@param shopId string
---@return number[]
function Staff.onlineMembers(shopId)
    local sources = {}

    for _, player in pairs(Core:GetQBPlayers()) do
        if Staff.role(shopId, Staff.citizenIdOf(player)) then
            sources[#sources + 1] = player.PlayerData.source
        end
    end

    return sources
end

---@param shopId string
---@param event string
---@param ... any
function Staff.emit(shopId, event, ...)
    lib.latent.client(event, Staff.onlineMembers(shopId), ...)
end

---@param shopId string
---@param citizenId string
---@param name string
---@param role string
function Staff.hire(shopId, citizenId, name, role)
    local shop = Staff.employees[shopId]

    if not shop then
        shop = {}
        Staff.employees[shopId] = shop
    end

    shop[citizenId] = {
        citizenId = citizenId,
        name = name,
        role = role,
        hiredAt = os.date('%Y-%m-%d') --[[@as string]],
    }

    Storage.addEmployee(shopId, citizenId, name, role)
    Staff.syncCitizen(citizenId)
end

---@param shopId string
---@param citizenId string
---@param role string
function Staff.setRole(shopId, citizenId, role)
    local employee = Staff.employee(shopId, citizenId)

    if not employee then return end

    employee.role = role
    Storage.setEmployeeRole(shopId, citizenId, role)
    Staff.syncCitizen(citizenId)
end

---@param shopId string
---@param citizenId string
function Staff.fire(shopId, citizenId)
    local shop = Staff.employees[shopId]

    if not shop or not shop[citizenId] then return end

    shop[citizenId] = nil
    Storage.removeEmployee(shopId, citizenId)

    local player = Core:GetPlayerByCitizenId(citizenId)

    if player then
        Staff.clearDuty(player.PlayerData.source)
        Staff.syncPlayer(player.PlayerData.source)
    end
end

---@param shopId string
---@return number
function Staff.count(shopId)
    local total = 0

    for _ in pairs(Staff.employees[shopId] or {}) do
        total += 1
    end

    return total
end

---@param shopId string
---@return BarberEmployeeListing[]
function Staff.list(shopId)
    local onDuty = {}

    for _, citizenId in pairs(Staff.dutyByShop[shopId] or {}) do
        onDuty[citizenId] = true
    end

    local stats = Storage.getEmployeeStats(shopId, config.limits.topEmployeeDays)
    local statsById = {}

    for i = 1, #stats do
        statsById[stats[i].citizenId] = stats[i]
    end

    local list = {}

    for citizenId, employee in pairs(Staff.employees[shopId] or {}) do
        local stat = statsById[citizenId]

        list[#list + 1] = {
            citizenId = citizenId,
            name = employee.name,
            role = employee.role,
            hiredAt = employee.hiredAt,
            onDuty = onDuty[citizenId] == true,
            services = stat and stat.services or 0,
            revenue = stat and stat.revenue or 0,
        }
    end

    local weight = {}

    for _, role in ipairs(Roles.list(shopId)) do
        weight[role.key] = #Roles.permissionList(role)
    end

    table.sort(list, function(a, b)
        local left, right = weight[a.role] or 0, weight[b.role] or 0

        if left ~= right then
            return left > right
        end

        return a.name < b.name
    end)

    return list
end

---@param source number
---@param shopId string
---@return boolean
function Staff.isOnDuty(source, shopId)
    return Staff.duty[source] == shopId
end

---@param source number
function Staff.clearDuty(source)
    local shopId = Staff.duty[source]

    if not shopId then return end

    Staff.duty[source] = nil

    local shop = Staff.dutyByShop[shopId]

    if shop then
        shop[source] = nil
    end

    Player(source).state:set('barberDuty', false, true)

    local record = Shops.get(shopId)

    if record then
        Shops.sync(record)
    end
end

---@param source number
---@param shopId string
---@return boolean onDuty
function Staff.toggleDuty(source, shopId)
    if Staff.isOnDuty(source, shopId) then
        Staff.clearDuty(source)

        return false
    end

    local citizenId = Staff.citizenId(source)

    if not citizenId then
        return false
    end

    Staff.clearDuty(source)
    Staff.duty[source] = shopId

    local shop = Staff.dutyByShop[shopId]

    if not shop then
        shop = {}
        Staff.dutyByShop[shopId] = shop
    end

    shop[source] = citizenId
    Player(source).state:set('barberDuty', shopId, true)

    local record = Shops.get(shopId)

    if record then
        Shops.sync(record)
    end

    return true
end

---@param shopId string
function Staff.enforceDuty(shopId)
    for source in pairs(Staff.dutyByShop[shopId] or {}) do
        if not Staff.can(source, shopId, 'duty') then
            Staff.clearDuty(source)
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'warning',
                description = 'Shift Anda diakhiri karena role Anda tidak lagi punya izin shift.',
                duration = 4500,
            })
        end
    end
end

---@param shopId string
---@return number
function Staff.dutyCount(shopId)
    local total = 0

    for _ in pairs(Staff.dutyByShop[shopId] or {}) do
        total += 1
    end

    return total
end

AddEventHandler('playerDropped', function()
    Staff.clearDuty(source)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    Staff.syncPlayer(player.PlayerData.source)
end)

return Staff
