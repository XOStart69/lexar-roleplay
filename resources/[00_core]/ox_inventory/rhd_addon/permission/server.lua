local Permission = {}

---@param source number
---@return boolean
local function isStaff(source)
    return IsPlayerAceAllowed(source, 'ox_inventory.give') or IsPlayerAceAllowed(source, 'ox_inventory.refund')
end

---@param source number
---@param item string
---@return boolean
---@return string?
function Permission.canGiveItem(source, item)
    if isStaff(source) then return true end

    return false, ('tidak punya izin memberi %s'):format(item)
end

---@param source number
---@param item string
---@return boolean
---@return string?
function Permission.canRefund(source, item)
    if isStaff(source) then return true end

    return false, ('tidak punya izin refund %s'):format(item)
end

return Permission