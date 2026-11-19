local logs = {}

function logs.write(accountId, citizenid, kind, amount, targetAccount)
    MySQL.insert.await([[
        INSERT INTO bank_transactions (account_id, citizenid, kind, amount, target_account)
        VALUES (?, ?, ?, ?, ?)
    ]], { accountId, citizenid, kind, amount, targetAccount })
end

return logs
