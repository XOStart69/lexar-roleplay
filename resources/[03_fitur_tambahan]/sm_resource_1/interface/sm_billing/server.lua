--[[
    sm_billing :: server
    Tagihan per citizenid. Bunga dihitung saat baca, bukan disimpan.
]]

local Config = localmodule 'config'

local DB = Config.Database
local TBL = DB.invoices
local ITEMS = DB.invoice_items
local LOGS = DB.invoice_logs

local MIN_AMOUNT = Config.MinInvoiceAmount or 1
local MAX_AMOUNT = Config.MaxInvoiceAmount or 1000000
local OVERDUE_DAYS = Config.OverdueDays or 3
local RATE = Config.InterestRate or 0.05
local MAX_INTEREST = Config.MaxInterestDays or 30
local AUTO_ATTEMPTS = Config.AutoDebitMaxAttempts or 3
local ADMIN_GROUPS = Config.AdminGroups or { 'admin', 'god' }
local NOTIF = Config.Notifications or {}

local SCHEMA = {
    ([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `number` varchar(32) NOT NULL,
        `sender_citizenid` varchar(64) NOT NULL,
        `sender_name` varchar(128) DEFAULT NULL,
        `sender_job` varchar(64) DEFAULT NULL,
        `target_citizenid` varchar(64) NOT NULL,
        `target_name` varchar(128) DEFAULT NULL,
        `title` varchar(191) NOT NULL,
        `description` text DEFAULT NULL,
        `amount` int(11) NOT NULL,
        `status` varchar(24) NOT NULL DEFAULT 'pending',
        `attempts` int(11) NOT NULL DEFAULT 0,
        `created_at` int(11) NOT NULL,
        `due_date` int(11) NOT NULL,
        `paid_at` int(11) DEFAULT NULL,
        `paid_method` varchar(16) DEFAULT NULL,
        `cancelled_at` int(11) DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `target` (`target_citizenid`),
        KEY `sender` (`sender_citizenid`),
        KEY `status` (`status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(TBL),

    ([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `invoice_id` int(11) NOT NULL,
        `label` varchar(191) NOT NULL,
        `price` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `invoice` (`invoice_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(ITEMS),

    ([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `invoice_id` int(11) DEFAULT NULL,
        `actor` varchar(64) DEFAULT NULL,
        `action` varchar(48) NOT NULL,
        `detail` text DEFAULT NULL,
        `stamp` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `invoice` (`invoice_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(LOGS),
}

local function now()
    return os.time()
end

local function money(amount)
    local str = tostring(math.floor(tonumber(amount) or 0))
    local out = str:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. (out:gsub('^%.', ''))
end

local function stamp(value)
    return os.date('%d/%m/%Y', tonumber(value) or now())
end

local function notify(src, key)
    local cfg = NOTIF[key]
    if not cfg or not src then return end
    TriggerClientEvent('ox_lib:notify', src, { title = cfg.title, description = cfg.description, type = cfg.type })
end

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function byCitizen(citizenid)
    for _, raw in ipairs(GetPlayers()) do
        local player = qb_ecore:GetPlayer(tonumber(raw))
        if player and player.PlayerData.citizenid == citizenid then return player, tonumber(raw) end
    end
end

local function isAdmin(player)
    if not player then return false end
    for _, group in ipairs(ADMIN_GROUPS) do
        if qb_ecore:HasPermission(player.PlayerData.source, group) then return true end
    end
    return false
end

local function canBill(player)
    if not player then return false end
    for _, job in ipairs(Config.AllowedJobsCreateInvoice or {}) do
        if player.PlayerData.job.name == job then return true end
    end
    return false
end

local function log(invoiceId, actor, action, detail)
    MySQL.insert('INSERT INTO ' .. LOGS .. ' (invoice_id, actor, action, detail, stamp) VALUES (?, ?, ?, ?, ?)', {
        invoiceId, actor, action, detail, now(),
    })
end

local function interestOf(invoice)
    local base = tonumber(invoice.amount) or 0
    local late = math.floor((now() - (tonumber(invoice.due_date) or now())) / 86400)
    if late <= 0 then return 0, 0 end

    late = math.min(late, MAX_INTEREST)
    return math.floor(base * RATE * late), late
end

local function decorate(invoice)
    local extra, days = interestOf(invoice)
    invoice.interest = extra
    invoice.interest_days = days
    invoice.total = (tonumber(invoice.amount) or 0) + extra
    invoice.amount_formatted = money(invoice.amount)
    invoice.total_formatted = money(invoice.total)
    invoice.due_date_formatted = stamp(invoice.due_date)
    invoice.created_at_formatted = stamp(invoice.created_at)
    return invoice
end

local function pager(page, limit)
    page = math.max(math.floor(tonumber(page) or 1), 1)
    limit = math.min(math.max(math.floor(tonumber(limit) or 20), 1), 100)
    return page, limit, (page - 1) * limit
end

lib.callback.register('xx-billing:server:GetPlayersData', function(src, list)
    if type(list) ~= 'table' then return {} end

    local ped = GetPlayerPed(src)
    if ped == 0 then return {} end

    local coords = GetEntityCoords(ped)
    local out = {}

    for i = 1, #list do
        local target = tonumber(list[i])
        local player = target and qb_ecore:GetPlayer(target)
        if player then
            local tped = GetPlayerPed(target)
            if tped ~= 0 and #(coords - GetEntityCoords(tped)) <= 12.0 then
                out[#out + 1] = { citizenid = player.PlayerData.citizenid, source = target }
            end
        end
    end

    return out
end)

lib.callback.register('xx-billing:server:GetInvoiceDetails', function(src, invoiceId)
    local player = playerOf(src)
    if not player then return nil end

    local invoice = MySQL.single.await('SELECT * FROM ' .. TBL .. ' WHERE id = ?', { tonumber(invoiceId) })
    if not invoice then return nil end

    local cid = player.PlayerData.citizenid
    if invoice.target_citizenid ~= cid and invoice.sender_citizenid ~= cid and not isAdmin(player) then
        return nil
    end

    invoice.items = MySQL.query.await('SELECT label, price FROM ' .. ITEMS .. ' WHERE invoice_id = ?', { invoice.id }) or {}

    return decorate(invoice)
end)

lib.callback.register('xx-billing:server:GetCompanyData', function(src, jobName, filters, page, limit)
    local player = playerOf(src)
    if not player then return { invoices = {}, total = 0, page = 1, pages = 1 } end

    local logs = Config.CompanyLogs and Config.CompanyLogs[jobName]
    if not logs or not logs.enabled then return { invoices = {}, total = 0, page = 1, pages = 1 } end
    if player.PlayerData.job.name ~= jobName then return { invoices = {}, total = 0, page = 1, pages = 1 } end
    if (player.PlayerData.job.grade.level or 0) < (logs.minGrade or 0) then
        return { invoices = {}, total = 0, page = 1, pages = 1 }
    end

    page, limit, offset = pager(page, limit)

    local where = { 'sender_job = ?' }
    local args = { jobName }

    filters = type(filters) == 'table' and filters or {}

    if filters.status and filters.status ~= '' then
        where[#where + 1] = 'status = ?'
        args[#args + 1] = tostring(filters.status)
    end
    if filters.search and filters.search ~= '' then
        where[#where + 1] = '(title LIKE ? OR target_name LIKE ? OR number LIKE ?)'
        local like = '%' .. filters.search .. '%'
        args[#args + 1] = like
        args[#args + 1] = like
        args[#args + 1] = like
    end
    if tonumber(filters.dateFrom) then
        where[#where + 1] = 'created_at >= ?'
        args[#args + 1] = tonumber(filters.dateFrom)
    end
    if tonumber(filters.dateTo) then
        where[#where + 1] = 'created_at <= ?'
        args[#args + 1] = tonumber(filters.dateTo)
    end

    local clause = table.concat(where, ' AND ')

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. TBL .. ' WHERE ' .. clause, args) or 0

    local rows = MySQL.query.await(
        ('SELECT * FROM %s WHERE %s ORDER BY id DESC LIMIT ? OFFSET ?'):format(TBL, clause),
        { table.unpack(args), limit, offset }
    ) or {}

    for i = 1, #rows do decorate(rows[i]) end

    return { invoices = rows, total = total, page = page, pages = math.max(math.ceil(total / limit), 1) }
end)

lib.callback.register('xx-billing:server:GetMyCreatedInvoices', function(src, page, limit)
    local player = playerOf(src)
    if not player then return { invoices = {}, total = 0, page = 1, pages = 1 } end

    page, limit, offset = pager(page, limit)
    local cid = player.PlayerData.citizenid

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. TBL .. ' WHERE sender_citizenid = ?', { cid }) or 0
    local rows = MySQL.query.await(
        ('SELECT * FROM %s WHERE sender_citizenid = ? ORDER BY id DESC LIMIT ? OFFSET ?'):format(TBL),
        { cid, limit, offset }
    ) or {}

    for i = 1, #rows do decorate(rows[i]) end

    return { invoices = rows, total = total, page = page, pages = math.max(math.ceil(total / limit), 1) }
end)

lib.callback.register('xx-billing:server:GetMyInvoices', function(src, page, limit)
    local player = playerOf(src)
    if not player then return { invoices = {}, total = 0, page = 1, pages = 1 } end

    page, limit, offset = pager(page, limit)
    local cid = player.PlayerData.citizenid

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. TBL .. ' WHERE target_citizenid = ?', { cid }) or 0
    local rows = MySQL.query.await(
        ('SELECT * FROM %s WHERE target_citizenid = ? ORDER BY id DESC LIMIT ? OFFSET ?'):format(TBL),
        { cid, limit, offset }
    ) or {}

    for i = 1, #rows do decorate(rows[i]) end

    return { invoices = rows, total = total, page = page, pages = math.max(math.ceil(total / limit), 1) }
end)

lib.callback.register('xx-billing:server:GetPaymentHistory', function(src, page, limit)
    local player = playerOf(src)
    if not player then return { history = {}, total = 0, page = 1, pages = 1 } end

    page, limit, offset = pager(page, limit)
    local cid = player.PlayerData.citizenid

    local total = MySQL.scalar.await(
        'SELECT COUNT(*) FROM ' .. TBL .. ' WHERE target_citizenid = ? AND status = ?', { cid, 'paid' }
    ) or 0

    local rows = MySQL.query.await(
        ('SELECT * FROM %s WHERE target_citizenid = ? AND status = ? ORDER BY paid_at DESC LIMIT ? OFFSET ?'):format(TBL),
        { cid, 'paid', limit, offset }
    ) or {}

    for i = 1, #rows do decorate(rows[i]) end

    return { history = rows, total = total, page = page, pages = math.max(math.ceil(total / limit), 1) }
end)

RegisterNetEvent('xx-billing:server:CreateInvoice', function(data)
    local src = source
    local player = playerOf(src)
    if not player or type(data) ~= 'table' then return end

    if not canBill(player) then return notify(src, 'no_permission') end

    local targetCid = tostring(data.targetId or '')
    local target, targetSrc = byCitizen(targetCid)
    if not target then return notify(src, 'no_permission') end

    local cid = player.PlayerData.citizenid
    if targetCid == cid then return notify(src, 'no_permission') end

    local amount = math.floor(tonumber(data.amount) or 0)
    if amount < MIN_AMOUNT or amount > MAX_AMOUNT then return notify(src, 'no_permission') end

    local title = tostring(data.title or ''):sub(1, 191)
    if title == '' then return notify(src, 'no_permission') end

    local job = player.PlayerData.job.name
    local days = (Config.AutoCollectionDays and (Config.AutoCollectionDays[job] or Config.AutoCollectionDays['default'])) or 7

    local stampNow = now()
    local id = MySQL.insert.await(
        ('INSERT INTO %s (number, sender_citizenid, sender_name, sender_job, target_citizenid, target_name, title, description, amount, status, created_at, due_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(TBL),
        {
            ('INV-%s-%d'):format(os.date('%Y%m%d'), stampNow),
            cid,
            ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname),
            job,
            targetCid,
            ('%s %s'):format(target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname),
            title,
            tostring(data.description or ''):sub(1, 1000),
            amount,
            'pending',
            stampNow,
            stampNow + (days * 86400),
        }
    )

    if not id then return notify(src, 'no_permission') end

    if type(data.items) == 'table' then
        for i = 1, math.min(#data.items, 30) do
            local item = data.items[i]
            if type(item) == 'table' and tonumber(item.price) then
                MySQL.insert('INSERT INTO ' .. ITEMS .. ' (invoice_id, label, price) VALUES (?, ?, ?)', {
                    id, tostring(item.label or 'Item'):sub(1, 191), math.floor(tonumber(item.price)),
                })
            end
        end
    end

    log(id, cid, 'created', ('%s -> %s (%d)'):format(title, targetCid, amount))
    notify(src, 'invoice_created')

    TriggerClientEvent('xx-billing:client:InvoiceReceived', targetSrc)

    TriggerClientEvent('xx-billing:client:InvoiceConfirmation', targetSrc, {
        id = id,
        title = title,
        description = tostring(data.description or ''),
        amount = amount,
        amount_formatted = money(amount),
        sender = ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname),
        sender_job = player.PlayerData.job.label,
        due_date_formatted = stamp(stampNow + (days * 86400)),
    })
end)

local function settle(invoice, payer, method)
    local extra = interestOf(invoice)
    local total = (tonumber(invoice.amount) or 0) + extra

    if not payer.Functions.RemoveMoney(method, total, ('invoice-%s'):format(invoice.number)) then
        return false, total
    end

    MySQL.update('UPDATE ' .. TBL .. ' SET status = ?, paid_at = ?, paid_method = ? WHERE id = ?', {
        'paid', now(), method, invoice.id,
    })

    local sender, senderSrc = byCitizen(invoice.sender_citizenid)
    if sender then
        sender.Functions.AddMoney(method, total, ('invoice-%s'):format(invoice.number))
        notify(senderSrc, 'invoice_paid')
        TriggerClientEvent('xx-billing:client:InvoicePaid', senderSrc)
    end

    log(invoice.id, payer.PlayerData.citizenid, 'paid', ('%s %d'):format(method, total))

    return true, total
end

RegisterNetEvent('xx-billing:server:PayInvoiceWithMethod', function(invoiceId, method)
    local src = source
    local player = playerOf(src)
    if not player then return end
    if method ~= 'cash' and method ~= 'bank' then return end

    local invoice = MySQL.single.await('SELECT * FROM ' .. TBL .. ' WHERE id = ?', { tonumber(invoiceId) })
    if not invoice then return end
    if invoice.target_citizenid ~= player.PlayerData.citizenid then return notify(src, 'no_permission') end
    if invoice.status ~= 'pending' and invoice.status ~= 'overdue' then return notify(src, 'no_permission') end

    local ok = settle(invoice, player, method)
    if not ok then return notify(src, 'insufficient_funds') end
end)

RegisterNetEvent('xx-billing:server:CancelInvoice', function(invoiceId)
    local src = source
    local player = playerOf(src)
    if not player then return end

    local invoice = MySQL.single.await('SELECT * FROM ' .. TBL .. ' WHERE id = ?', { tonumber(invoiceId) })
    if not invoice then return end

    local cid = player.PlayerData.citizenid
    local allowed = invoice.sender_citizenid == cid or isAdmin(player)
    if not allowed then return notify(src, 'no_permission') end
    if invoice.status == 'paid' or invoice.status == 'cancelled' then return notify(src, 'no_permission') end

    MySQL.update('UPDATE ' .. TBL .. ' SET status = ?, cancelled_at = ? WHERE id = ?', { 'cancelled', now(), invoice.id })

    log(invoice.id, cid, 'cancelled')

    local target, targetSrc = byCitizen(invoice.target_citizenid)
    if target then
        TriggerClientEvent('xx-billing:client:InvoiceReceived', targetSrc)
    end

    notify(src, 'invoice_cancelled')
end)

CreateThread(function()
    MySQL.query.await(SCHEMA[1])
    MySQL.query.await(SCHEMA[2])
    MySQL.query.await(SCHEMA[3])

    while true do
        Wait(60000)

        local overdue = MySQL.query.await(
            ('SELECT * FROM %s WHERE status = ? AND due_date < ?'):format(TBL),
            { 'pending', now() }
        ) or {}

        for i = 1, #overdue do
            local invoice = overdue[i]
            MySQL.update('UPDATE ' .. TBL .. ' SET status = ? WHERE id = ?', { 'overdue', invoice.id })
            log(invoice.id, 'system', 'overdue')

            local _, targetSrc = byCitizen(invoice.target_citizenid)
            if targetSrc then
                TriggerClientEvent('xx-billing:client:InvoiceOverdue', targetSrc, { title = invoice.title })
                notify(targetSrc, 'invoice_overdue')
            end
        end

        local debts = MySQL.query.await(
            ('SELECT * FROM %s WHERE status = ? AND due_date < ? AND attempts < ?'):format(TBL),
            { 'overdue', now() - (OVERDUE_DAYS * 86400), AUTO_ATTEMPTS }
        ) or {}

        for i = 1, #debts do
            local invoice = debts[i]
            local payer, payerSrc = byCitizen(invoice.target_citizenid)

            if payer then
                local ok = settle(invoice, payer, 'bank')
                if not ok then
                    MySQL.update('UPDATE ' .. TBL .. ' SET attempts = attempts + 1 WHERE id = ?', { invoice.id })
                    log(invoice.id, 'system', 'autodebit-failed')
                end
            end
        end
    end
end)

print('^2[sm_billing] server siap^7')