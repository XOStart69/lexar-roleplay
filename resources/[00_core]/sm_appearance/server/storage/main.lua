local db = exports.oxmysql
local config = require "config.general"

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `playerskins` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(255) NOT NULL,
    `model` varchar(255) NOT NULL,
    `skin` text NOT NULL,
    `active` tinyint(4) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local storage = {}

if config.autoCreateTables then
    CreateThread(function()
        db:query_async(SCHEMA)
    end)
end

---@param identifier string
---@param model string?
---@return PedAppearance?
function storage.getClothing(identifier, model)
    local skin

    if model then
        skin = db:scalar_async("SELECT skin FROM playerskins WHERE citizenid = ? AND model = ?", {
            identifier, model
        })
    else
        skin = db:scalar_async("SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1", {
            identifier
        })
    end

    if not skin then return end

    local ok, appearance = pcall(json.decode, skin)

    return ok and appearance or nil
end

---@param identifier string
---@param appearance PedAppearance
---@return boolean
function storage.saveClothing(identifier, appearance)
    local model = appearance.model

    return db:transaction_async({
        {
            query = "UPDATE playerskins SET active = 0 WHERE citizenid = ?",
            values = { identifier }
        },
        {
            query = "DELETE FROM playerskins WHERE citizenid = ? AND model = ?",
            values = { identifier, model }
        },
        {
            query = "INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, 1)",
            values = { identifier, model, json.encode(appearance) }
        }
    })
end

---@param identifier string
function storage.deleteClothing(identifier)
    db:query_async("DELETE FROM playerskins WHERE citizenid = ?", { identifier })
end

return storage
