---@class JobsServer
local jobs = {}

local QBCore = exports['qb-core']:GetCoreObject()

---@param source number
---@return CachedJob?
function jobs.of(source)
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then return end

    local job = Player.PlayerData.job

    if not job then return end

    return { name = job.name, grade = job.grade.level, onduty = job.onduty }
end

---@param source number
---@param zone table
---@return boolean
function jobs.allowed(source, zone)
    return modules.zones.member(zone, jobs.of(source), true)
end

return jobs
