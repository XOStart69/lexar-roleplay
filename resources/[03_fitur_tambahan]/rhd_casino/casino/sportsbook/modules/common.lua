local config = require 'casino.sportsbook.config'

local Common = {}

---@param source number
---@return 'admin'|'staff'|nil
function Common.getRole(source)
    local job = sm_core:GetPlayerData(source, 'job')
    if not job or job.name ~= shared.casinoJobName then return nil end

    local level = tonumber(job.grade?.level) or 0
    if level >= config.access.admin then return 'admin' end
    if level >= config.access.staff then return 'staff' end

    return nil
end

---@param source number
---@param required 'admin'|'staff'
---@return boolean
function Common.hasRole(source, required)
    local role = Common.getRole(source)
    if not role then return false end
    if required == 'staff' then return true end
    return role == 'admin'
end

---@param source number
---@return { identifier: string?, name: string }
function Common.staffInfo(source)
    return {
        identifier = shared.getIdentifier(source),
        name = shared.getPlayerName(source),
    }
end

---@param value any
---@param maxLength integer
---@return string?
function Common.cleanString(value, maxLength)
    if type(value) ~= 'string' then return nil end
    local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then return nil end
    return trimmed:sub(1, maxLength)
end

---@param value any
---@param min number
---@param max number
---@return integer?
function Common.cleanInt(value, min, max)
    local number = math.floor(tonumber(value) or -1)
    if number < min or number > max then return nil end
    return number
end

---@param staffSource number
---@param targetSource number
---@return boolean
function Common.isNearStaff(staffSource, targetSource)
    if staffSource == targetSource then return true end
    if not shared.playerExist(targetSource) then return false end

    local staffPed = GetPlayerPed(staffSource)
    local targetPed = GetPlayerPed(targetSource)
    if staffPed == 0 or targetPed == 0 then return false end

    return #(GetEntityCoords(staffPed) - GetEntityCoords(targetPed)) <= config.maxBettorDistance
end

return Common
