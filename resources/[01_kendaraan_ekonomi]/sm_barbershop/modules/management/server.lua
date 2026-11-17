local config = Config
local limits = config.limits

local DAY_LABELS = { 'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab' }

local function notify(source, notifyType, description)
    TriggerClientEvent('ox_lib:notify', source, {
        type = notifyType,
        description = description,
        duration = 4500,
    })
end

---@param message string
---@return BarberActionResult
local function fail(message)
    return { success = false, message = message }
end

local inventory = exports.ox_inventory

---@type table<string, BarberSupply>
local supplies = {}

for i = 1, #config.supplies do
    supplies[config.supplies[i].item] = config.supplies[i]
end

local catalog = { groups = config.priceGroups, items = {} }

for i = 1, #config.priceItems do
    local item = config.priceItems[i]

    catalog.items[i] = {
        key = item.key,
        group = item.group,
        label = item.label,
        includedWith = item.includedWith,
        defaultPrice = Pricing.defaultPrice(item.key),
    }
end

---@param shopId string
---@param actorRole string?
local function roleOptions(shopId, actorRole)
    local options = {}

    for _, role in ipairs(Roles.list(shopId)) do
        local permissions = role.permissions

        options[#options + 1] = {
            value = role.key,
            label = role.label,
            assignable = Staff.outranks(shopId, actorRole, role.key),
            manages = permissions.hire == true or permissions.fire == true or permissions.setRole == true,
        }
    end

    return options
end

---@param shopId string
local function roleSettings(shopId)
    local list = {}

    for _, role in ipairs(Roles.list(shopId)) do
        list[#list + 1] = {
            key = role.key,
            label = role.label,
            permissions = Roles.permissionList(role),
            members = Staff.countRole(shopId, role.key),
        }
    end

    return list
end

---@param shop BarberShop
local function reloadTablets(shop)
    Staff.emit(shop.id, 'sm_barbershop:management:reload', shop.id)
end

---@param shop BarberShop
---@param citizenId string
local function reloadCitizen(shop, citizenId)
    local player = Core:GetPlayerByCitizenId(citizenId)

    if player then
        TriggerClientEvent('sm_barbershop:management:reload', player.PlayerData.source, shop.id)
    end
end

---@param shopId string
local function buildDaily(shopId)
    local byDate = Storage.getDailyStats(shopId, 7)
    local series = {}
    local now = os.time()

    for offset = 6, 0, -1 do
        local ts = now - offset * 86400
        local entry = byDate[os.date('%Y-%m-%d', ts)]

        series[#series + 1] = {
            label = DAY_LABELS[os.date('*t', ts).wday],
            visitors = entry and entry.visitors or 0,
            revenue = entry and entry.revenue or 0,
        }
    end

    return series
end

---@param shop BarberShop
---@return BarberDashboard
local function dashboard(shop)
    local visitors, revenue = Storage.getTodayStats(shop.id)
    local stats = Storage.getEmployeeStats(shop.id, limits.topEmployeeDays)
    local topEmployees = {}

    for i = 1, math.min(#stats, limits.topEmployeeLimit) do
        topEmployees[i] = stats[i]
    end

    return {
        stats = {
            visitorsToday = visitors,
            revenueToday = revenue,
            staffOnDuty = Staff.dutyCount(shop.id),
            balance = shop.balance,
        },
        daily = buildDaily(shop.id),
        topEmployees = topEmployees,
        recentLogs = Storage.getRecentServices(shop.id, limits.recentLogsLimit),
    }
end

---@param source number
---@param shopId any
---@return BarberShop?, string?
local function access(source, shopId)
    local shop = Shops.get(shopId)

    if not shop then return end

    local role = Staff.roleOf(source, shop.id)

    if not role then return end

    return shop, role
end

---@param shop BarberShop
---@param build fun(): BarberManagementSync
local function sync(shop, build)
    local revision = Sync.nextRevision()
    local payload = build()

    payload.shopId = shop.id
    payload.revision = revision
    Staff.emit(shop.id, 'sm_barbershop:management:sync', payload)
end

---@param shop BarberShop
local function syncEmployees(shop)
    sync(shop, function()
        return { employees = Staff.list(shop.id), dashboard = dashboard(shop) }
    end)
end

---@param shop BarberShop
local function syncShop(shop)
    sync(shop, function()
        return { shop = Shops.publicData(shop), dashboard = dashboard(shop) }
    end)
end

local function pageOf(value)
    return math.max(1, math.floor(tonumber(value) or 1))
end

local function pageSizeOf(value)
    local size = math.floor(tonumber(value) or limits.logPageSize)

    return math.min(limits.maxPageSize, math.max(1, size))
end

local function searchOf(value)
    if type(value) ~= 'string' then return end

    local term = value:match('^%s*(.-)%s*$'):sub(1, 40)

    return term ~= '' and term or nil
end

local function amountOf(value)
    local amount = tonumber(value)

    if not amount or amount ~= amount then return end

    amount = math.floor(amount)

    if amount <= 0 or amount > limits.maxFinanceAmount then return end

    return amount
end

AddEventHandler('sm_barbershop:internal:serviceRecorded', function(shopId)
    local shop = Shops.get(shopId)

    if shop then
        syncShop(shop)
    end
end)

lib.callback.register('sm_barbershop:management:bootstrap', function(source, shopId)
    local shop, role = access(source, shopId)

    if not shop then return false end

    local revision = Sync.revision
    local player = Staff.getPlayer(source)

    return {
        revision = revision,
        shop = Shops.publicData(shop),
        me = {
            citizenId = Staff.citizenIdOf(player),
            name = Staff.nameOf(player),
            role = role,
            onDuty = Staff.isOnDuty(source, shop.id),
            can = Staff.permissions(shop.id, role),
        },
        dashboard = dashboard(shop),
        employees = Staff.list(shop.id),
        roles = roleOptions(shop.id, role),
        roleSettings = role == 'owner' and roleSettings(shop.id) or nil,
        permissions = config.permissions,
        supplies = config.supplies,
        imagePath = GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images'),
        limits = {
            maxCommissionRate = limits.maxCommissionRate,
            minSelfServiceRate = limits.minSelfServiceRate,
            maxSelfServiceRate = limits.maxSelfServiceRate,
            maxFinanceAmount = limits.maxFinanceAmount,
            minShopName = limits.minShopName,
            maxShopName = limits.maxShopName,
            maxRoles = limits.maxRoles,
            minRoleName = limits.minRoleName,
            maxRoleName = limits.maxRoleName,
        },
        catalog = catalog,
    }
end)

lib.callback.register('sm_barbershop:management:getLogs', function(source, shopId, page, pageSize, search)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'logs') then return false end

    return Storage.getServiceLogs(shop.id, pageOf(page), pageSizeOf(pageSize), searchOf(search))
end)

lib.callback.register('sm_barbershop:management:getTransactions', function(source, shopId, page, pageSize, search)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'finance') then return false end

    return Storage.getTransactions(shop.id, pageOf(page), pageSizeOf(pageSize), searchOf(search))
end)

lib.callback.register('sm_barbershop:management:resolvePlayers', function(source, shopId, ids)
    local shop = access(source, shopId)

    if not shop or type(ids) ~= 'table' then return {} end

    local list = {}

    for i = 1, math.min(#ids, 32) do
        local id = tonumber(ids[i])
        local player = id and id ~= source and Staff.getPlayer(id)

        if player and not Staff.role(shop.id, Staff.citizenIdOf(player)) then
            list[#list + 1] = { value = id, label = Staff.nameOf(player) }
        end
    end

    return list
end)

lib.callback.register('sm_barbershop:management:toggleDuty', function(source, shopId)
    local shop = access(source, shopId)

    if not shop then return fail('Anda bukan staf barbershop ini.') end

    if not Staff.isOnDuty(source, shop.id) and not Staff.can(source, shop.id, 'duty') then
        return fail('Role Anda tidak punya izin untuk mulai shift.')
    end

    local onDuty = Staff.toggleDuty(source, shop.id)

    syncEmployees(shop)

    return { success = true, onDuty = onDuty }
end)

lib.callback.register('sm_barbershop:management:hire', function(source, shopId, targetId, role)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'hire') then return fail('Anda tidak berwenang merekrut.') end

    local roleEntry = Roles.get(shop.id, role)

    if not roleEntry then return fail('Role tidak valid.') end
    if not Staff.outranks(shop.id, Staff.roleOf(source, shop.id), role) then return fail('Anda hanya bisa merekrut ke role di bawah Anda.') end
    if Staff.count(shop.id) >= limits.maxEmployees then return fail('Jumlah karyawan sudah maksimal.') end

    local target = type(targetId) == 'number' and targetId ~= source and Staff.getPlayer(targetId) or nil
    local citizenId = Staff.citizenIdOf(target)

    if not citizenId then return fail('Pemain tidak ditemukan.') end
    if Staff.role(shop.id, citizenId) then return fail('Pemain ini sudah terdaftar.') end

    Staff.hire(shop.id, citizenId, Staff.nameOf(target), role)
    notify(targetId, 'success', ('Anda direkrut sebagai %s di %s.'):format(roleEntry.label, shop.label))
    syncEmployees(shop)

    return { success = true, employees = Staff.list(shop.id) }
end)

lib.callback.register('sm_barbershop:management:setRole', function(source, shopId, citizenId, role)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'setRole') then return fail('Anda tidak berwenang mengubah role.') end

    local employee = type(citizenId) == 'string' and Staff.employee(shop.id, citizenId)

    if not employee then return fail('Karyawan tidak ditemukan.') end
    if citizenId == Staff.citizenId(source) then return fail('Anda tidak bisa mengubah role sendiri.') end
    if not Roles.get(shop.id, role) then return fail('Role tidak valid.') end

    local actorRole = Staff.roleOf(source, shop.id)

    if not Staff.outranks(shop.id, actorRole, employee.role) or not Staff.outranks(shop.id, actorRole, role) then
        return fail('Anda hanya bisa mengatur role di bawah Anda.')
    end

    Staff.setRole(shop.id, citizenId, role)
    Staff.enforceDuty(shop.id)
    syncEmployees(shop)
    reloadCitizen(shop, citizenId)

    return { success = true, employees = Staff.list(shop.id) }
end)

lib.callback.register('sm_barbershop:management:fire', function(source, shopId, citizenId)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'fire') then return fail('Anda tidak berwenang memecat.') end

    local employee = type(citizenId) == 'string' and Staff.employee(shop.id, citizenId)

    if not employee then return fail('Karyawan tidak ditemukan.') end
    if citizenId == Staff.citizenId(source) then return fail('Anda tidak bisa memecat diri sendiri.') end

    if not Staff.outranks(shop.id, Staff.roleOf(source, shop.id), employee.role) then
        return fail('Anda hanya bisa memecat role di bawah Anda.')
    end

    Staff.fire(shop.id, citizenId)
    syncEmployees(shop)

    return { success = true, employees = Staff.list(shop.id) }
end)

lib.callback.register('sm_barbershop:management:setPrices', function(source, shopId, prices)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'prices') then return fail('Anda tidak berwenang mengatur harga.') end
    if type(prices) ~= 'table' or not Shops.setPrices(shop, prices) then return fail('Harga atau komisi di luar batas.') end

    syncShop(shop)

    return { success = true, shop = Shops.publicData(shop) }
end)

lib.callback.register('sm_barbershop:management:setName', function(source, shopId, name)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'settings') then return fail('Anda tidak berwenang mengganti nama toko.') end

    if not Shops.setName(shop, name) then
        return fail(('Nama harus %d-%d karakter, hanya huruf, angka, spasi, dan . \' & -'):format(limits.minShopName, limits.maxShopName))
    end

    syncShop(shop)

    return { success = true, shop = Shops.publicData(shop) }
end)

lib.callback.register('sm_barbershop:management:saveRole', function(source, shopId, key, label, permissions)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'roles') then return fail('Hanya pemilik yang bisa mengatur role.') end
    if key ~= nil and type(key) ~= 'string' then return fail('Role tidak valid.') end

    local role, message = Roles.save(shop.id, key, label, permissions)

    if not role then return fail(message --[[@as string]]) end

    Staff.enforceDuty(shop.id)
    syncEmployees(shop)
    reloadTablets(shop)

    return { success = true, key = role.key }
end)

lib.callback.register('sm_barbershop:management:deleteRole', function(source, shopId, key)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'roles') then return fail('Hanya pemilik yang bisa mengatur role.') end
    if not Roles.get(shop.id, key) then return fail('Role tidak ditemukan.') end
    if #Roles.list(shop.id) <= 1 then return fail('Minimal harus ada satu role.') end

    local members = Staff.countRole(shop.id, key)

    if members > 0 then return fail(('Pindahkan %d karyawan di role ini terlebih dahulu.'):format(members)) end

    Roles.remove(shop.id, key)
    reloadTablets(shop)

    return { success = true }
end)

lib.callback.register('sm_barbershop:management:buySupply', function(source, shopId, itemName, quantity)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'supplies') then return fail('Anda tidak berwenang membeli perlengkapan.') end

    local supply = type(itemName) == 'string' and supplies[itemName]

    if not supply then return fail('Barang tidak tersedia.') end

    local count = math.floor(tonumber(quantity) or 0)

    if count < 1 or count > supply.maxQuantity then return fail(('Jumlah harus 1-%d.'):format(supply.maxQuantity)) end

    local total = supply.price * count

    if total > shop.balance then return fail('Saldo barbershop tidak cukup.') end

    local player = Staff.getPlayer(source)

    if not player then return fail('Data pemain tidak ditemukan.') end
    local metadata = Wear.metadata(supply.item, Wear.max(supply.item))

    if not inventory:CanCarryItem(source, supply.item, count, metadata) then return fail('Inventory penuh.') end
    if not inventory:AddItem(source, supply.item, count, metadata) then return fail('Barang gagal dimasukkan ke inventory.') end

    Shops.addBalance(shop, -total)
    Storage.addTransaction({
        shopId = shop.id,
        type = 'supply',
        amount = total,
        balanceAfter = shop.balance,
        actorCitizenId = Staff.citizenIdOf(player),
        actorName = Staff.nameOf(player),
        note = ('Beli %dx %s'):format(count, supply.label),
    })
    syncShop(shop)

    return { success = true, shop = Shops.publicData(shop) }
end)

lib.callback.register('sm_barbershop:management:deposit', function(source, shopId, value)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'finance') then return fail('Anda tidak berwenang mengelola keuangan.') end

    local amount = amountOf(value)

    if not amount then return fail('Jumlah tidak valid.') end

    local player = Staff.getPlayer(source)

    if not player or player.Functions.RemoveMoney(config.payment.finance, amount, 'barbershop-deposit') ~= true then
        return fail('Saldo tidak cukup.')
    end

    Shops.addBalance(shop, amount)
    Storage.addTransaction({
        shopId = shop.id,
        type = 'deposit',
        amount = amount,
        balanceAfter = shop.balance,
        actorCitizenId = Staff.citizenIdOf(player),
        actorName = Staff.nameOf(player),
        note = 'Setoran',
    })
    syncShop(shop)

    return { success = true, shop = Shops.publicData(shop) }
end)

lib.callback.register('sm_barbershop:management:withdraw', function(source, shopId, value)
    local shop = access(source, shopId)

    if not shop or not Staff.can(source, shop.id, 'withdraw') then return fail('Anda tidak berwenang menarik saldo.') end

    local amount = amountOf(value)

    if not amount then return fail('Jumlah tidak valid.') end
    if amount > shop.balance then return fail('Saldo barbershop tidak cukup.') end

    local player = Staff.getPlayer(source)

    if not player then return fail('Data pemain tidak ditemukan.') end

    Shops.addBalance(shop, -amount)
    player.Functions.AddMoney(config.payment.finance, amount, 'barbershop-withdraw')
    Storage.addTransaction({
        shopId = shop.id,
        type = 'withdraw',
        amount = amount,
        balanceAfter = shop.balance,
        actorCitizenId = Staff.citizenIdOf(player),
        actorName = Staff.nameOf(player),
        note = 'Penarikan',
    })
    syncShop(shop)

    return { success = true, shop = Shops.publicData(shop) }
end)

lib.callback.register('sm_barbershop:shop:purchase', function(source, shopId)
    local shop = Shops.get(shopId)

    if not shop then return fail('Barbershop tidak ditemukan.') end
    if not shop.purchesable then return fail('Barbershop ini tidak dijual.') end
    if Shops.isOwned(shop) then return fail('Barbershop ini sudah dimiliki.') end

    local player = Staff.getPlayer(source)
    local citizenId = Staff.citizenIdOf(player)

    if not player or not citizenId then return fail('Data pemain tidak ditemukan.') end

    if player.Functions.RemoveMoney(config.payment.purchase, shop.purchasePrice, 'barbershop-purchase') ~= true then
        return fail('Saldo bank tidak cukup.')
    end

    Shops.setOwner(shop, citizenId, Staff.nameOf(player))
    Storage.addTransaction({
        shopId = shop.id,
        type = 'purchase',
        amount = shop.purchasePrice,
        balanceAfter = shop.balance,
        actorCitizenId = citizenId,
        actorName = shop.ownerName,
        note = 'Pembelian barbershop',
    })
    Staff.syncPlayer(source)

    return { success = true, message = ('Anda sekarang pemilik %s.'):format(shop.label) }
end)

local LOCATE_RADIUS = 30.0
local COMMAND_USAGE = 'Pakai: /barbershop setowner [playerid] [barberid] | removeowner [barberid] | getid | goto [barberid]'

---@type table<string, vector3>
local managementOf = {}

for i = 1, #config.shops do
    managementOf[config.shops[i].id] = config.shops[i].coords.management
end

---@param source number
---@param notifyType string
---@param message string
local function reply(source, notifyType, message)
    if source == 0 then
        return print(message)
    end

    notify(source, notifyType, message)
end

---@param source number
---@return BarberShop?
local function shopNear(source)
    local ped = GetPlayerPed(source)

    if ped == 0 then return end

    local coords = GetEntityCoords(ped)
    local best, bestDistance

    for id, management in pairs(managementOf) do
        local distance = #(coords - management)

        if distance <= LOCATE_RADIUS and (not bestDistance or distance < bestDistance) then
            best, bestDistance = id, distance
        end
    end

    return best and Shops.get(best) or nil
end

---@type table<string, fun(source: number, first: string?, second: string?)>
local commands = {}

commands.setowner = function(source, playerId, shopId)
    local shop = Shops.get(shopId)

    if not shop then return reply(source, 'error', 'ID barbershop tidak ditemukan.') end

    local target = tonumber(playerId)
    local player = target and Staff.getPlayer(target)
    local citizenId = Staff.citizenIdOf(player)

    if not target or not citizenId then return reply(source, 'error', 'Pemain target tidak ditemukan.') end

    local previousOwner = shop.ownerCitizenId

    Shops.setOwner(shop, citizenId, Staff.nameOf(player))
    Staff.syncPlayer(target)

    if previousOwner and previousOwner ~= citizenId then
        Staff.syncCitizen(previousOwner)
    end

    syncShop(shop)
    reply(source, 'success', ('%s sekarang pemilik %s.'):format(Staff.nameOf(player), shop.label))
end

commands.removeowner = function(source, shopId)
    local shop = Shops.get(shopId)

    if not shop then return reply(source, 'error', 'ID barbershop tidak ditemukan.') end

    local previousOwner = shop.ownerCitizenId

    if not previousOwner then return reply(source, 'error', ('%s belum punya pemilik.'):format(shop.label)) end

    Shops.setOwner(shop, nil, nil)
    Staff.syncCitizen(previousOwner)
    syncShop(shop)
    reply(source, 'success', ('Pemilik %s dihapus.'):format(shop.label))
end

commands.getid = function(source)
    if source == 0 then return reply(source, 'error', 'Command ini hanya bisa dipakai di dalam game.') end

    local shop = shopNear(source)

    if not shop then return reply(source, 'error', 'Anda tidak berada di area barbershop.') end

    reply(source, 'inform', ('ID barbershop: %s (%s)'):format(shop.id, shop.label))
end

commands['goto'] = function(source, shopId)
    if source == 0 then return reply(source, 'error', 'Command ini hanya bisa dipakai di dalam game.') end

    local management = type(shopId) == 'string' and managementOf[shopId]

    if not management then return reply(source, 'error', 'ID barbershop tidak ditemukan.') end

    local ped = GetPlayerPed(source)

    if ped == 0 then return end

    SetEntityCoords(ped, management.x, management.y, management.z, false, false, false, false)
end

lib.addCommand('barbershop', {
    help = 'Kelola barbershop',
    params = {
        { name = 'action', type = 'string', help = 'setowner, removeowner, getid, atau goto' },
        { name = 'first', help = 'setowner: ID pemain · removeowner/goto: ID barbershop', optional = true },
        { name = 'second', help = 'setowner: ID barbershop', optional = true },
    },
    restricted = ('group.%s'):format(config.adminAce),
}, function(source, args)
    local command = commands[args.action and args.action:lower() or '']

    if not command then return reply(source, 'error', COMMAND_USAGE) end

    command(source, args.first, args.second)
end)

CreateThread(function()
    Storage.ensureTables()
    Shops.init()
    Roles.init()
    Staff.init()
    Shops.syncAll()
    TriggerEvent('sm_barbershop:internal:ready')
    Sync.start()

    Wait(1500)

    for _, player in pairs(Core:GetQBPlayers()) do
        Staff.syncPlayer(player.PlayerData.source)
    end
end)
