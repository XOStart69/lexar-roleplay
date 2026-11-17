local db = exports.oxmysql
local config = require "config.general"

local SCHEMA = {
    [[
    CREATE TABLE IF NOT EXISTS `appearance_half_peds` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(50) NOT NULL,
        `gender` varchar(10) NOT NULL,
        `drawable` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `gender_drawable` (`gender`,`drawable`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
    CREATE TABLE IF NOT EXISTS `appearance_half_ped_access` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `half_ped_id` int(11) NOT NULL,
        `name` varchar(50) NOT NULL,
        `citizenid` varchar(50) NOT NULL,
        `expires_at` date DEFAULT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `half_ped_citizenid` (`half_ped_id`,`citizenid`),
        KEY `citizenid` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
}

local halfped = {}

if config.autoCreateTables then
    CreateThread(function()
        for i = 1, #SCHEMA do
            db:query_async(SCHEMA[i])
        end
    end)
end

---@return HalfPed[]
function halfped.all()
    local rows = db:query_async("SELECT id, name, gender, drawable FROM appearance_half_peds") or {}

    return rows
end

---@param name string
---@param gender string
---@param drawable number
---@return number? id
function halfped.register(name, gender, drawable)
    return db:insert_async(
        "INSERT INTO appearance_half_peds (name, gender, drawable) VALUES (?, ?, ?)", {
            name, gender, drawable
        })
end

---@param id number
function halfped.remove(id)
    db:transaction_async({
        { query = "DELETE FROM appearance_half_ped_access WHERE half_ped_id = ?", values = { id } },
        { query = "DELETE FROM appearance_half_peds WHERE id = ?", values = { id } }
    })
end

---@return HalfPedAccess[]
function halfped.allAccess()
    return db:query_async([[
        SELECT a.id, a.half_ped_id AS halfPedId, a.name, a.citizenid,
               DATE_FORMAT(a.expires_at, '%Y-%m-%d') AS expires,
               p.gender, p.drawable
        FROM appearance_half_ped_access a
        JOIN appearance_half_peds p ON p.id = a.half_ped_id
    ]]) or {}
end

---@param halfPedId number
---@param name string
---@param identifier string
---@param expires string?
---@return number? id
function halfped.grant(halfPedId, name, identifier, expires)
    return db:insert_async([[
        INSERT INTO appearance_half_ped_access (half_ped_id, name, citizenid, expires_at)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), name = VALUES(name), expires_at = VALUES(expires_at)
    ]], { halfPedId, name, identifier, expires })
end

---@param id number
function halfped.revoke(id)
    db:query_async("DELETE FROM appearance_half_ped_access WHERE id = ?", { id })
end

return halfped
