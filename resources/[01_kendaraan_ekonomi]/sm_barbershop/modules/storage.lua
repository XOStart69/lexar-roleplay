local db = exports.oxmysql
local storage = {}

---@param row table
---@return BarberServiceLog
local function mapService(row)
    return {
        id = row.id,
        mode = row.mode,
        customerName = row.customer_name,
        employeeName = row.employee_name,
        amount = tonumber(row.amount) or 0,
        commission = tonumber(row.commission) or 0,
        date = row.date,
        at = row.at,
    }
end

---@param row table
---@return BarberTransactionLog
local function mapTransaction(row)
    return {
        id = row.id,
        type = row.tx_type,
        amount = tonumber(row.amount) or 0,
        balanceAfter = tonumber(row.balance_after) or 0,
        actorName = row.actor_name,
        note = row.note,
        date = row.date,
        at = row.at,
    }
end

---@param search string?
---@return string?
local function likePattern(search)
    if type(search) ~= 'string' or search == '' then return end

    return '%' .. search:gsub('[\\%%_]', '\\%0') .. '%'
end

---@param items table[]
---@param page integer
---@param pageSize integer
---@param total integer
---@return table
local function pageOf(items, page, pageSize, total)
    return {
        items = items,
        page = page,
        pageSize = pageSize,
        total = total,
        numberOfPages = math.max(1, math.ceil(total / pageSize)),
    }
end

---@param tableName string
---@param column string
---@return boolean
local function columnExists(tableName, column)
    local count = tonumber(db:scalar_async([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { tableName, column })) or 0

    return count > 0
end

---@param tableName string
---@param column string
---@param definition string
local function ensureColumn(tableName, column, definition)
    if not columnExists(tableName, column) then
        db:query_async(('ALTER TABLE `%s` ADD COLUMN `%s` %s'):format(tableName, column, definition))
    end
end

---@param tableName string
---@param column string
local function dropColumn(tableName, column)
    if columnExists(tableName, column) then
        db:query_async(('ALTER TABLE `%s` DROP COLUMN `%s`'):format(tableName, column))
    end
end

function storage.ensureTables()
    db:query_async([[
        CREATE TABLE IF NOT EXISTS `sm_barbershop_shops` (
            `shop_id` varchar(32) NOT NULL,
            `owner_citizenid` varchar(64) DEFAULT NULL,
            `owner_name` varchar(128) DEFAULT NULL,
            `balance` int NOT NULL DEFAULT 0,
            `commission_rate` int NOT NULL DEFAULT 0,
            `self_service_rate` int NOT NULL DEFAULT 0,
            `item_prices` text DEFAULT NULL,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`shop_id`),
            KEY `owner_citizenid` (`owner_citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    ensureColumn('sm_barbershop_shops', 'name', 'varchar(64) DEFAULT NULL AFTER `shop_id`')
    ensureColumn('sm_barbershop_shops', 'self_service_rate', 'int NOT NULL DEFAULT 0 AFTER `commission_rate`')
    ensureColumn('sm_barbershop_shops', 'item_prices', 'text DEFAULT NULL AFTER `self_service_rate`')
    dropColumn('sm_barbershop_shops', 'self_service_price')
    dropColumn('sm_barbershop_shops', 'service_price')

    db:query_async([[
        CREATE TABLE IF NOT EXISTS `sm_barbershop_employees` (
            `id` int NOT NULL AUTO_INCREMENT,
            `shop_id` varchar(32) NOT NULL,
            `citizenid` varchar(64) NOT NULL,
            `name` varchar(128) NOT NULL,
            `role` varchar(16) NOT NULL DEFAULT 'barber',
            `hired_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `shop_employee` (`shop_id`, `citizenid`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    db:query_async([[
        CREATE TABLE IF NOT EXISTS `sm_barbershop_services` (
            `id` int NOT NULL AUTO_INCREMENT,
            `shop_id` varchar(32) NOT NULL,
            `mode` varchar(8) NOT NULL,
            `customer_citizenid` varchar(64) NOT NULL,
            `customer_name` varchar(128) NOT NULL,
            `employee_citizenid` varchar(64) DEFAULT NULL,
            `employee_name` varchar(128) DEFAULT NULL,
            `amount` int NOT NULL DEFAULT 0,
            `commission` int NOT NULL DEFAULT 0,
            `items` text DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `shop_created` (`shop_id`, `created_at`),
            KEY `shop_employee` (`shop_id`, `employee_citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    ensureColumn('sm_barbershop_services', 'items', 'text DEFAULT NULL AFTER `commission`')

    db:query_async([[
        CREATE TABLE IF NOT EXISTS `sm_barbershop_transactions` (
            `id` int NOT NULL AUTO_INCREMENT,
            `shop_id` varchar(32) NOT NULL,
            `tx_type` varchar(16) NOT NULL,
            `amount` int NOT NULL DEFAULT 0,
            `balance_after` int NOT NULL DEFAULT 0,
            `actor_citizenid` varchar(64) DEFAULT NULL,
            `actor_name` varchar(128) DEFAULT NULL,
            `note` varchar(255) DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `shop_created` (`shop_id`, `created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    db:query_async([[
        CREATE TABLE IF NOT EXISTS `sm_barbershop_roles` (
            `id` int NOT NULL AUTO_INCREMENT,
            `shop_id` varchar(32) NOT NULL,
            `role_key` varchar(16) DEFAULT NULL,
            `label` varchar(32) NOT NULL,
            `permissions` text DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `shop_id` (`shop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    db:query_async([[
        CREATE TABLE IF NOT EXISTS `sm_barbershop_portables` (
            `id` int NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(64) NOT NULL,
            `shop_id` varchar(32) NOT NULL,
            `placed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    ensureColumn('sm_barbershop_portables', 'used', 'int DEFAULT NULL AFTER `shop_id`')
end

---@return table<string, table>
function storage.loadShops()
    local rows = db:query_async('SELECT * FROM `sm_barbershop_shops`')
    local byId = {}

    if type(rows) == 'table' then
        for i = 1, #rows do
            byId[rows[i].shop_id] = rows[i]
        end
    end

    return byId
end

---@param shop BarberShop
function storage.saveShop(shop)
    db:insert_async([[
        INSERT INTO `sm_barbershop_shops`
            (shop_id, name, owner_citizenid, owner_name, balance, commission_rate, self_service_rate, item_prices)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            owner_citizenid = VALUES(owner_citizenid),
            owner_name = VALUES(owner_name),
            balance = VALUES(balance),
            commission_rate = VALUES(commission_rate),
            self_service_rate = VALUES(self_service_rate),
            item_prices = VALUES(item_prices)
    ]], {
        shop.id,
        shop.label ~= shop.defaultLabel and shop.label or nil,
        shop.ownerCitizenId,
        shop.ownerName,
        shop.balance,
        shop.commissionRate,
        shop.selfServiceRate,
        json.encode(shop.itemPrices),
    })
end

---@return table[]
function storage.loadEmployees()
    local rows = db:query_async([[
        SELECT shop_id, citizenid, name, role, DATE_FORMAT(hired_at, '%Y-%m-%d') AS hired_at
        FROM `sm_barbershop_employees`
        ORDER BY id ASC
    ]])

    return type(rows) == 'table' and rows or {}
end

---@param shopId string
---@param citizenId string
---@param name string
---@param role string
function storage.addEmployee(shopId, citizenId, name, role)
    db:insert_async([[
        INSERT INTO `sm_barbershop_employees` (shop_id, citizenid, name, role)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), role = VALUES(role)
    ]], { shopId, citizenId, name, role })
end

---@param shopId string
---@param citizenId string
---@param role string
function storage.setEmployeeRole(shopId, citizenId, role)
    db:update_async(
        'UPDATE `sm_barbershop_employees` SET role = ? WHERE shop_id = ? AND citizenid = ?',
        { role, shopId, citizenId }
    )
end

---@param shopId string
---@param citizenId string
function storage.removeEmployee(shopId, citizenId)
    db:update_async(
        'DELETE FROM `sm_barbershop_employees` WHERE shop_id = ? AND citizenid = ?',
        { shopId, citizenId }
    )
end

---@param entry BarberServiceRecord
---@return integer?
function storage.addService(entry)
    return db:insert_async([[
        INSERT INTO `sm_barbershop_services`
            (shop_id, mode, customer_citizenid, customer_name, employee_citizenid, employee_name, amount, commission, items)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        entry.shopId,
        entry.mode,
        entry.customerCitizenId,
        entry.customerName,
        entry.employeeCitizenId,
        entry.employeeName,
        entry.amount,
        entry.commission or 0,
        entry.items and json.encode(entry.items) or nil,
    })
end

---@param entry BarberTransactionRecord
---@return integer?
function storage.addTransaction(entry)
    return db:insert_async([[
        INSERT INTO `sm_barbershop_transactions`
            (shop_id, tx_type, amount, balance_after, actor_citizenid, actor_name, note)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        entry.shopId,
        entry.type,
        entry.amount,
        entry.balanceAfter,
        entry.actorCitizenId,
        entry.actorName,
        entry.note,
    })
end

---@param shopId string
---@param limit integer
---@return BarberServiceLog[]
function storage.getRecentServices(shopId, limit)
    local rows = db:query_async([[
        SELECT id, mode, customer_name, employee_name, amount, commission,
            DATE_FORMAT(created_at, '%Y-%m-%d') AS date, DATE_FORMAT(created_at, '%H:%i') AS at
        FROM `sm_barbershop_services`
        WHERE shop_id = ?
        ORDER BY id DESC
        LIMIT ?
    ]], { shopId, limit })

    local items = {}

    if type(rows) == 'table' then
        for i = 1, #rows do
            items[i] = mapService(rows[i])
        end
    end

    return items
end

---@param shopId string
---@param page integer
---@param pageSize integer
---@param search string?
---@return BarberServicePage
function storage.getServiceLogs(shopId, page, pageSize, search)
    local pattern = likePattern(search)
    local filter = pattern and ' AND (customer_name LIKE ? OR employee_name LIKE ?)' or ''
    local params = pattern and { shopId, pattern, pattern } or { shopId }

    local total = tonumber(db:scalar_async(
        'SELECT COUNT(*) FROM `sm_barbershop_services` WHERE shop_id = ?' .. filter,
        params
    )) or 0

    local rows = db:query_async(([[
        SELECT id, mode, customer_name, employee_name, amount, commission,
            DATE_FORMAT(created_at, '%%Y-%%m-%%d') AS date, DATE_FORMAT(created_at, '%%H:%%i') AS at
        FROM `sm_barbershop_services`
        WHERE shop_id = ?%s
        ORDER BY id DESC
        LIMIT ? OFFSET ?
    ]]):format(filter), pattern
        and { shopId, pattern, pattern, pageSize, (page - 1) * pageSize }
        or { shopId, pageSize, (page - 1) * pageSize })

    local items = {}

    if type(rows) == 'table' then
        for i = 1, #rows do
            items[i] = mapService(rows[i])
        end
    end

    return pageOf(items, page, pageSize, total)
end

---@param shopId string
---@param page integer
---@param pageSize integer
---@param search string?
---@return BarberTransactionPage
function storage.getTransactions(shopId, page, pageSize, search)
    local pattern = likePattern(search)
    local filter = pattern and ' AND (note LIKE ? OR actor_name LIKE ? OR tx_type LIKE ?)' or ''
    local params = pattern and { shopId, pattern, pattern, pattern } or { shopId }

    local total = tonumber(db:scalar_async(
        'SELECT COUNT(*) FROM `sm_barbershop_transactions` WHERE shop_id = ?' .. filter,
        params
    )) or 0

    local rows = db:query_async(([[
        SELECT id, tx_type, amount, balance_after, actor_name, note,
            DATE_FORMAT(created_at, '%%Y-%%m-%%d') AS date, DATE_FORMAT(created_at, '%%H:%%i') AS at
        FROM `sm_barbershop_transactions`
        WHERE shop_id = ?%s
        ORDER BY id DESC
        LIMIT ? OFFSET ?
    ]]):format(filter), pattern
        and { shopId, pattern, pattern, pattern, pageSize, (page - 1) * pageSize }
        or { shopId, pageSize, (page - 1) * pageSize })

    local items = {}

    if type(rows) == 'table' then
        for i = 1, #rows do
            items[i] = mapTransaction(rows[i])
        end
    end

    return pageOf(items, page, pageSize, total)
end

---@param shopId string
---@return integer visitors
---@return integer revenue
function storage.getTodayStats(shopId)
    local row = db:single_async([[
        SELECT COUNT(*) AS visitors, COALESCE(SUM(amount), 0) AS revenue
        FROM `sm_barbershop_services`
        WHERE shop_id = ? AND DATE(created_at) = CURDATE()
    ]], { shopId })

    return tonumber(row and row.visitors) or 0, tonumber(row and row.revenue) or 0
end

---@param shopId string
---@param days integer
---@return table<string, { visitors: integer, revenue: integer }>
function storage.getDailyStats(shopId, days)
    local since = os.date('%Y-%m-%d', os.time() - (days - 1) * 86400)
    local rows = db:query_async([[
        SELECT DATE_FORMAT(created_at, '%Y-%m-%d') AS date, COUNT(*) AS visitors, COALESCE(SUM(amount), 0) AS revenue
        FROM `sm_barbershop_services`
        WHERE shop_id = ? AND DATE(created_at) >= ?
        GROUP BY DATE(created_at)
    ]], { shopId, since })

    local byDate = {}

    if type(rows) == 'table' then
        for i = 1, #rows do
            local row = rows[i]
            byDate[row.date] = { visitors = tonumber(row.visitors) or 0, revenue = tonumber(row.revenue) or 0 }
        end
    end

    return byDate
end

---@param shopId string
---@param days integer
---@return BarberEmployeeStat[]
function storage.getEmployeeStats(shopId, days)
    local since = os.date('%Y-%m-%d', os.time() - (days - 1) * 86400)
    local rows = db:query_async([[
        SELECT employee_citizenid, employee_name, COUNT(*) AS services, COALESCE(SUM(amount), 0) AS revenue
        FROM `sm_barbershop_services`
        WHERE shop_id = ? AND employee_citizenid IS NOT NULL AND DATE(created_at) >= ?
        GROUP BY employee_citizenid, employee_name
        ORDER BY services DESC, revenue DESC
    ]], { shopId, since })

    local list = {}

    if type(rows) == 'table' then
        for i = 1, #rows do
            local row = rows[i]
            list[i] = {
                citizenId = row.employee_citizenid,
                name = row.employee_name,
                services = tonumber(row.services) or 0,
                revenue = tonumber(row.revenue) or 0,
            }
        end
    end

    return list
end

---@return table[]
function storage.loadRoles()
    local rows = db:query_async('SELECT id, shop_id, role_key, label, permissions FROM `sm_barbershop_roles` ORDER BY id ASC')

    return type(rows) == 'table' and rows or {}
end

---@param shopId string
---@param roleKey string?
---@param label string
---@param permissions string
---@return integer?
function storage.addRole(shopId, roleKey, label, permissions)
    return db:insert_async(
        'INSERT INTO `sm_barbershop_roles` (shop_id, role_key, label, permissions) VALUES (?, ?, ?, ?)',
        { shopId, roleKey, label, permissions }
    )
end

---@param id integer
---@param label string
---@param permissions string
function storage.saveRole(id, label, permissions)
    db:update_async('UPDATE `sm_barbershop_roles` SET label = ?, permissions = ? WHERE id = ?', { label, permissions, id })
end

---@param id integer
function storage.removeRole(id)
    db:update_async('DELETE FROM `sm_barbershop_roles` WHERE id = ?', { id })
end

---@param citizenId string
---@param shopId string
---@param used integer
---@return integer?
function storage.addPortable(citizenId, shopId, used)
    return db:insert_async('INSERT INTO `sm_barbershop_portables` (citizenid, shop_id, used) VALUES (?, ?, ?)', { citizenId, shopId, used })
end

---@param id integer
---@param used integer
function storage.setPortableUsed(id, used)
    db:update_async('UPDATE `sm_barbershop_portables` SET used = ? WHERE id = ?', { used, id })
end

---@param id integer
function storage.removePortable(id)
    db:update_async('DELETE FROM `sm_barbershop_portables` WHERE id = ?', { id })
end

---@param citizenId string
---@return { id: integer, used: integer? }[]
function storage.portablesOf(citizenId)
    local rows = db:query_async('SELECT id, used FROM `sm_barbershop_portables` WHERE citizenid = ? ORDER BY id ASC', { citizenId })

    return type(rows) == 'table' and rows or {}
end

return storage
