local db = exports.oxmysql
local config = require "config.general"

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `appearance_config_state` (
    `section` varchar(20) NOT NULL,
    `synced_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`section`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local state = {}

if config.autoCreateTables then
    CreateThread(function()
        db:query_async(SCHEMA)
    end)
end

---@return table<string, true>
function state.synced()
    local rows = db:query_async("SELECT section FROM appearance_config_state") or {}
    local result = {}

    for i = 1, #rows do
        result[rows[i].section] = true
    end

    return result
end

---@param section string
function state.mark(section)
    db:update_async(
        "INSERT INTO appearance_config_state (section) VALUES (?) ON DUPLICATE KEY UPDATE synced_at = CURRENT_TIMESTAMP",
        { section })
end

---@param section string
function state.clear(section)
    db:update_async("DELETE FROM appearance_config_state WHERE section = ?", { section })
end

return state
