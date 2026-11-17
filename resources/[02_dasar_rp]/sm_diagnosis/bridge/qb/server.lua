local QBCore = exports['qb-core']:GetCoreObject()
local bridge = {}

local utils = require 'modules.utils'

function bridge.checkJob(source, target)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local myjob = Player.PlayerData.job
    return utils.job_contains(myjob, target)
end


function bridge.isDead(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local metadata = Player.PlayerData.metadata
    return metadata.isdead or metadata.inlaststand
end

return bridge