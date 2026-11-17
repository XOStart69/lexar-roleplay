local bridge = {}

local utils = require 'modules.utils'

function bridge.checkJob(source, target)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end
    local myjob = Player.PlayerData.job
    return utils.job_contains(myjob, target)
end

function bridge.isDead(source)
    return Player(source).state.isDead
end

return bridge