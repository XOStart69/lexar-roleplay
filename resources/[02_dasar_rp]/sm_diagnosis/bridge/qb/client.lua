require '@sm_core.modules.playerdata'

local bridge = {}

---@return boolean
function bridge.isStarving()
    local metadata = QBPlayerData.metadata
    if not metadata then return false end

    return metadata.hunger <= 0 or metadata.thirst <= 0
end

---@return boolean
function bridge.isDead()
    local metadata = QBPlayerData.metadata
    if not metadata then return false end

    return metadata.isdead or metadata.inlaststand or false
end

return bridge
