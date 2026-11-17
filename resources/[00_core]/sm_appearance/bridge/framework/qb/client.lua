local QBCore = exports["qb-core"]:GetCoreObject()
local events = require "modules.events"

local framework = {}
local playerdata = {}

local function sync()
    local data = QBCore.Functions.GetPlayerData()

    if not data or not data.citizenid then return false end

    playerdata.job = data.job
    playerdata.gang = data.gang
    playerdata.identifier = data.citizenid
    playerdata.gender = data.charinfo.gender == 1 and "female" or "male"

    return true
end

---@return string
function framework.GetGender()
    return playerdata.gender or "male"
end

function framework.getState()
    return playerdata
end

---@param group table?
---@param name string
---@return number?
local function gradeOf(group, name)
    if not group or group.name ~= name then return nil end

    return type(group.grade) == "table" and (group.grade.level or 0) or tonumber(group.grade) or 0
end

---@param name string
---@return number? grade
function framework.jobGrade(name)
    return gradeOf(playerdata.job, name)
end

---@param name string
---@return number? grade
function framework.gangGrade(name)
    return gradeOf(playerdata.gang, name)
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    if sync() then
        events.emit("playerLoaded")
    end
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
    playerdata.job = job
end)

RegisterNetEvent("qb-clothes:client:CreateFirstCharacter", function()
    sync()
    events.emit("newCharacter")
end)

RegisterNetEvent("QBCore:Client:OnGangUpdate", function(gang)
    playerdata.gang = gang
end)

CreateThread(function()
    if sync() then
        events.emit("playerLoaded")
    end
end)

return framework
