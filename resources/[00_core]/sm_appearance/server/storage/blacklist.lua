local db = exports.oxmysql
local config = require "config.general"

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `appearance_blacklist` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `gender` varchar(10) NOT NULL,
    `category` varchar(20) NOT NULL,
    `slot` varchar(30) NOT NULL DEFAULT '',
    `drawable` int(11) NOT NULL,
    `textures` varchar(255) DEFAULT NULL,
    `jobs` varchar(500) DEFAULT NULL,
    `gangs` varchar(500) DEFAULT NULL,
    `aces` varchar(500) DEFAULT NULL,
    `citizenids` varchar(1000) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `gender_category_slot_drawable` (`gender`,`category`,`slot`,`drawable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local blacklist = {}

if config.autoCreateTables then
    CreateThread(function()
        db:query_async(SCHEMA)
    end)
end

---@param value string?
---@return any?
local function decode(value)
    if not value then return nil end

    local result = json.decode(value)

    if type(result) == "table" and next(result) == nil then return nil end

    return result
end

---@param value any?
---@return string?
local function encode(value)
    if value == nil then return nil end
    if type(value) == "table" and next(value) == nil then return nil end

    return json.encode(value)
end

---@return BlacklistRow[]
function blacklist.all()
    local rows = db:query_async(
        "SELECT id, gender, category, slot, drawable, textures, jobs, gangs, aces, citizenids FROM appearance_blacklist"
    ) or {}

    for i = 1, #rows do
        local row = rows[i]

        row.textures = decode(row.textures)
        row.jobs = decode(row.jobs)
        row.gangs = decode(row.gangs)
        row.aces = decode(row.aces)
        row.citizenids = decode(row.citizenids)
    end

    return rows
end

---@param entry BlacklistRow
---@return number? id
function blacklist.save(entry)
    return db:insert_async([[
        INSERT INTO appearance_blacklist (gender, category, slot, drawable, textures, jobs, gangs, aces, citizenids)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            id = LAST_INSERT_ID(id),
            textures = VALUES(textures),
            jobs = VALUES(jobs),
            gangs = VALUES(gangs),
            aces = VALUES(aces),
            citizenids = VALUES(citizenids)
    ]], {
        entry.gender,
        entry.category,
        entry.slot,
        entry.drawable,
        encode(entry.textures),
        encode(entry.jobs),
        encode(entry.gangs),
        encode(entry.aces),
        encode(entry.citizenids)
    })
end

---@param id number
---@param entry BlacklistRow
function blacklist.update(id, entry)
    db:update_async([[
        UPDATE appearance_blacklist
        SET gender = ?, category = ?, slot = ?, drawable = ?, textures = ?, jobs = ?, gangs = ?,
            aces = ?, citizenids = ?
        WHERE id = ?
    ]], {
        entry.gender,
        entry.category,
        entry.slot,
        entry.drawable,
        encode(entry.textures),
        encode(entry.jobs),
        encode(entry.gangs),
        encode(entry.aces),
        encode(entry.citizenids),
        id
    })
end

---@param id number
function blacklist.remove(id)
    db:update_async("DELETE FROM appearance_blacklist WHERE id = ?", { id })
end

return blacklist
