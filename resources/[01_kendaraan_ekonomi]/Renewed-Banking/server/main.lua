local framework = require 'server.framework'
local logs = require 'server.logs'

local function account(id)
    return MySQL.single.await('SELECT * FROM bank_accounts WHERE id = ?', { tonumber(id) })
end

local function isOwner(row, citizenid)
    return row and row.owner_citizenid == citizenid
end

local function isMember(row, citizenid)
    if isOwner(row, citizenid) then return true end

    return MySQL.scalar.await('SELECT 1 FROM bank_account_members WHERE account_id = ? AND citizenid = ?', {
        row.id, citizenid,
    }) ~= nil
end

local function accountsOf(citizenid)
    local rows = MySQL.query.await([[
        SELECT a.id, a.account_name, a.balance, a.account_type, a.owner_citizenid
        FROM bank_accounts a
        LEFT JOIN bank_account_members m ON m.account_id = a.id
        WHERE a.owner_citizenid = ? OR m.citizenid = ?
        GROUP BY a.id
        ORDER BY a.id ASC
    ]], { citizenid, citizenid })

    for i = 1, #rows do
        rows[i].isOwner = rows[i].owner_citizenid == citizenid
        rows[i].owner_citizenid = nil
        rows[i].platinum = rows[i].balance >= Config.platinumThreshold
    end

    return rows
end

local function ensurePersonal(citizenid, name)
    local existing = MySQL.scalar.await([[SELECT id FROM bank_accounts
        WHERE owner_citizenid = ? AND account_type = 'personal' LIMIT 1]], { citizenid })

    if existing then return existing end

    return MySQL.insert.await([[INSERT INTO bank_accounts (account_name, owner_citizenid, balance, account_type)
        VALUES (?, ?, 0, 'personal')]], { ('Rekening %s'):format(name), citizenid })
end

CreateThread(function()
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS bank_accounts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        account_name VARCHAR(64) NOT NULL,
        owner_citizenid VARCHAR(50) NOT NULL,
        balance BIGINT NOT NULL DEFAULT 0,
        account_type VARCHAR(16) NOT NULL DEFAULT 'personal',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_owner (owner_citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS bank_account_members (
        account_id INT NOT NULL,
        citizenid VARCHAR(50) NOT NULL,
        PRIMARY KEY (account_id, citizenid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS bank_transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        account_id INT NOT NULL,
        citizenid VARCHAR(50) NOT NULL,
        kind VARCHAR(16) NOT NULL,
        amount BIGINT NOT NULL,
        target_account INT DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_account (account_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
end)

RegisterNetEvent('Renewed-Banking:server:getBankData', function()
    local source = source
    local cid = framework.citizen(source)

    if not cid then return end

    ensurePersonal(cid, framework.name(source))

    TriggerClientEvent('Renewed-Banking:client:receiveBankData', source, accountsOf(cid))
end)

RegisterNetEvent('Renewed-Banking:server:getPlayerAccounts', function()
    local source = source
    local cid = framework.citizen(source)

    if not cid then return end

    TriggerClientEvent('Renewed-Banking:client:receiveBankData', source, accountsOf(cid))
end)

local function doDeposit(source, data)
    local cid = framework.citizen(source)
    local Player = framework.player(source)

    if not cid or not Player or type(data) ~= 'table' then return { success = false, message = 'Data tidak valid' } end

    local row = account(data.account)

    if not row or not isMember(row, cid) then return { success = false, message = 'Rekening tidak ditemukan' } end

    local amount = math.floor(tonumber(data.amount) or 0)

    if amount <= 0 then return { success = false, message = 'Jumlah tidak valid' } end

    if not Player.Functions.RemoveMoney('cash', amount, 'bank deposit') then
        return { success = false, message = 'Uang tunai tidak cukup' }
    end

    MySQL.update.await('UPDATE bank_accounts SET balance = balance + ? WHERE id = ?', { amount, row.id })

    logs.write(row.id, cid, 'deposit', amount)

    return { success = true, message = ('Setor $%d berhasil'):format(amount), balance = row.balance + amount }
end

local function doWithdraw(source, data)
    local cid = framework.citizen(source)
    local Player = framework.player(source)

    if not cid or not Player or type(data) ~= 'table' then return { success = false, message = 'Data tidak valid' } end

    local row = account(data.account)

    if not row or not isMember(row, cid) then return { success = false, message = 'Rekening tidak ditemukan' } end

    local amount = math.floor(tonumber(data.amount) or 0)

    if amount <= 0 then return { success = false, message = 'Jumlah tidak valid' } end

    if row.balance < amount then return { success = false, message = 'Saldo tidak cukup' } end

    MySQL.update.await('UPDATE bank_accounts SET balance = balance - ? WHERE id = ?', { amount, row.id })
    Player.Functions.AddMoney('cash', amount, 'bank withdraw')

    logs.write(row.id, cid, 'withdraw', amount)

    return { success = true, message = ('Tarik $%d berhasil'):format(amount), balance = row.balance - amount }
end

local function doTransfer(source, data)
    local cid = framework.citizen(source)

    if not cid or type(data) ~= 'table' then return { success = false, message = 'Data tidak valid' } end

    local from = account(data.account)
    local toId = tonumber(data.target or data.to or data.receiver)

    if not from or not isMember(from, cid) then return { success = false, message = 'Rekening asal tidak ditemukan' } end
    if not toId then return { success = false, message = 'Rekening tujuan kosong' } end

    local to = account(toId)

    if not to then return { success = false, message = 'Rekening tujuan tidak ada' } end
    if to.id == from.id then return { success = false, message = 'Rekening sama' } end

    local amount = math.floor(tonumber(data.amount) or 0)

    if amount <= 0 then return { success = false, message = 'Jumlah tidak valid' } end
    if from.balance < amount then return { success = false, message = 'Saldo tidak cukup' } end

    MySQL.update.await('UPDATE bank_accounts SET balance = balance - ? WHERE id = ?', { amount, from.id })
    MySQL.update.await('UPDATE bank_accounts SET balance = balance + ? WHERE id = ?', { amount, to.id })

    logs.write(from.id, cid, 'transfer_out', amount, to.id)
    logs.write(to.id, cid, 'transfer_in', amount, from.id)

    return { success = true, message = ('Transfer $%d berhasil'):format(amount), balance = from.balance - amount }
end

lib.callback.register('Renewed-Banking:server:deposit', doDeposit)
lib.callback.register('Renewed-Banking:server:withdraw', doWithdraw)
lib.callback.register('Renewed-Banking:server:transfer', doTransfer)

RegisterNetEvent('Renewed-Banking:server:createNewAccount', function(data)
    local source = source
    local cid = framework.citizen(source)

    if not cid then return end

    local name = type(data) == 'table' and data.name or nil
    local kind = type(data) == 'table' and data.type or 'personal'

    MySQL.insert.await([[INSERT INTO bank_accounts (account_name, owner_citizenid, balance, account_type)
        VALUES (?, ?, 0, ?)]], { name or 'Rekening Baru', cid, kind })

    framework.notify(source, 'Rekening dibuat', 'success')

    TriggerClientEvent('Renewed-Banking:client:receiveBankData', source, accountsOf(cid))
end)

lib.callback.register('Renewed-Banking:server:getMemberManagement', function(source, data)
    local cid = framework.citizen(source)

    if not cid or not data or not data.account then return nil end

    local row = account(data.account)

    if not row or not isMember(row, cid) then return nil end

    local members = MySQL.query.await([[SELECT m.citizenid, p.charinfo
        FROM bank_account_members m
        LEFT JOIN players p ON p.citizenid = m.citizenid
        WHERE m.account_id = ?]], { row.id })

    local list = {}

    for i = 1, #members do
        local info = members[i].charinfo and json.decode(members[i].charinfo) or {}

        list[#list + 1] = {
            citizenid = members[i].citizenid,
            name = ('%s %s'):format(info.firstname or '?', info.lastname or ''),
        }
    end

    return { account = row.id, owner = row.owner_citizenid, members = list }
end)

RegisterNetEvent('Renewed-Banking:server:viewMemberManagement', function(data)
    local source = source

    if not data or not data.account then return end

    TriggerClientEvent('Renewed-Banking:client:viewMemberManagement', source, data)
end)

RegisterNetEvent('Renewed-Banking:server:addAccountMember', function(accountId, memberId)
    local source = source
    local cid = framework.citizen(source)
    local row = account(accountId)

    if not cid or not row or not isOwner(row, cid) then return framework.notify(source, 'Hanya pemilik rekening', 'error') end

    local target = framework.player(memberId)

    if not target then return framework.notify(source, 'Player tidak ditemukan', 'error') end

    MySQL.query.await('INSERT IGNORE INTO bank_account_members (account_id, citizenid) VALUES (?, ?)', {
        row.id, target.PlayerData.citizenid,
    })

    framework.notify(source, 'Anggota ditambahkan', 'success')
end)

RegisterNetEvent('Renewed-Banking:server:removeAccountMember', function(data)
    local source = source
    local cid = framework.citizen(source)

    if not cid or not data or not data.account or not data.citizenid then return end

    local row = account(data.account)

    if not row or not isOwner(row, cid) then return framework.notify(source, 'Hanya pemilik rekening', 'error') end

    MySQL.update.await('DELETE FROM bank_account_members WHERE account_id = ? AND citizenid = ?', {
        row.id, data.citizenid,
    })

    framework.notify(source, 'Anggota dihapus', 'success')
end)

RegisterNetEvent('Renewed-Banking:server:changeAccountName', function(accountId, newName)
    local source = source
    local cid = framework.citizen(source)

    if not cid or type(newName) ~= 'string' then return end

    local row = account(accountId)

    if not row or not isOwner(row, cid) then return framework.notify(source, 'Hanya pemilik rekening', 'error') end

    MySQL.update.await('UPDATE bank_accounts SET account_name = ? WHERE id = ?', { newName:sub(1, 64), row.id })

    framework.notify(source, 'Nama rekening diubah', 'success')
end)

RegisterNetEvent('Renewed-Banking:server:deleteAccount', function(data)
    local source = source
    local cid = framework.citizen(source)

    if not cid or not data or not data.account then return end

    local row = account(data.account)

    if not row or not isOwner(row, cid) then return framework.notify(source, 'Hanya pemilik rekening', 'error') end

    if row.balance > 0 then
        return framework.notify(source, 'Kosongkan saldo dulu', 'error')
    end

    MySQL.update.await('DELETE FROM bank_account_members WHERE account_id = ?', { row.id })
    MySQL.update.await('DELETE FROM bank_accounts WHERE id = ?', { row.id })

    framework.notify(source, 'Rekening dihapus', 'success')

    TriggerClientEvent('Renewed-Banking:client:receiveBankData', source, accountsOf(cid))
end)

lib.print.info('Renewed-Banking server siap')
