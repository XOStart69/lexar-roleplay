local db = exports.oxmysql
local config = require "config.general"

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `appearance_ped_access` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `label` varchar(50) NOT NULL DEFAULT '',
    `models` text NOT NULL,
    `jobs` varchar(500) DEFAULT NULL,
    `gangs` varchar(500) DEFAULT NULL,
    `aces` varchar(500) DEFAULT NULL,
    `citizenids` varchar(1000) DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local peds = {}

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

---@return PedRule[]
function peds.all()
    local rows = db:query_async(
        "SELECT id, label, models, jobs, gangs, aces, citizenids FROM appearance_ped_access") or {}

    for i = 1, #rows do
        local row = rows[i]

        row.models = decode(row.models) or {}
        row.jobs = decode(row.jobs)
        row.gangs = decode(row.gangs)
        row.aces = decode(row.aces)
        row.identifiers = decode(row.citizenids)
        row.citizenids = nil
    end

    return rows
end

---@param rule table
---@return number? id
function peds.insert(rule)
    return db:insert_async([[
        INSERT INTO appearance_ped_access (label, models, jobs, gangs, aces, citizenids)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        rule.label or "",
        json.encode(rule.models),
        encode(rule.jobs),
        encode(rule.gangs),
        encode(rule.aces),
        encode(rule.identifiers)
    })
end

---@param id number
---@param rule table
---@return boolean
function peds.update(id, rule)
    local affected = db:update_async([[
        UPDATE appearance_ped_access
        SET label = ?, models = ?, jobs = ?, gangs = ?, aces = ?, citizenids = ?
        WHERE id = ?
    ]], {
        rule.label or "",
        json.encode(rule.models),
        encode(rule.jobs),
        encode(rule.gangs),
        encode(rule.aces),
        encode(rule.identifiers),
        id
    })

    return affected ~= nil
end

---@param id number
function peds.remove(id)
    db:update_async("DELETE FROM appearance_ped_access WHERE id = ?", { id })
end

return peds
