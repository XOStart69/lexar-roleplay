---@param src number
---@param homeId string
---@param aptId string|number|nil
---@param permission string?
---@return boolean
function Housing:CanUseTarget(src, homeId, aptId, permission)
    local home = self:GetHome(homeId)
    if not home then return false end

    local identifier = self:GetIdentifier(src)
    if not identifier then return false end

    if home:HasAccess(identifier, permission, aptId) then return true end
    return self:IsAdmin(src) or self:IsPolice(src)
end

exports('CanUseTarget', function(src, homeId, aptId, permission)
    return Housing:CanUseTarget(src, homeId, aptId, permission)
end)

exports('GetHomeData', function(homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return nil end
    return home:GetData(aptId)
end)

exports('GetHomeOwner', function(homeId, aptId)
    local home = Housing:GetHome(homeId)
    if not home then return nil end
    return home:GetOwner(home.owner or '', aptId)
end)