local events = require "modules.events"

local ESX = exports.es_extended:getSharedObject()

local framework = {}
local playerdata = {}

---@param data table?
---@return boolean
local function sync(data)
    data = data or ESX.GetPlayerData()

    if not data or not data.identifier then return false end

    playerdata.job = data.job
    playerdata.gang = data.job
    playerdata.identifier = data.identifier
    playerdata.gender = data.sex == "f" and "female" or "male"

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

    return tonumber(group.grade) or 0
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

RegisterNetEvent("esx:playerLoaded", function(xPlayer)
    if sync(xPlayer) then
        events.emit("playerLoaded")
    end
end)

RegisterNetEvent("esx:setJob", function(job)
    playerdata.job = job
    playerdata.gang = job
end)

local firstSpawn = false

AddEventHandler("esx_skin:resetFirstSpawn", function()
    firstSpawn = true
end)

AddEventHandler("esx_skin:playerRegistered", function()
    if not firstSpawn then return end

    firstSpawn = false

    events.emit("newCharacter")
end)

CreateThread(function()
    if sync() then
        events.emit("playerLoaded")
    end
end)

return framework
