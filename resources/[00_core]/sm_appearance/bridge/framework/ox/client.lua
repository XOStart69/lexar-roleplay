local events = require "modules.events"

local Ox = require "@ox_core.lib.init"

local framework = {}
local playerdata = {}

---@param character table?
---@return boolean
local function sync(character)
    local player = Ox.GetPlayer()

    if not player or not player.charId then return false end

    playerdata.job = character and character.groups or nil
    playerdata.gang = playerdata.job
    playerdata.identifier = tostring(player.charId)
    playerdata.gender = player.get("gender") == "female" and "female" or "male"

    return true
end

---@return string
function framework.GetGender()
    return playerdata.gender or "male"
end

function framework.getState()
    return playerdata
end

---@param name string
---@return number? grade
function framework.jobGrade(name)
    local groups = playerdata.job

    return groups and groups[name] or nil
end

---@param name string
---@return number? grade
function framework.gangGrade(name)
    return framework.jobGrade(name)
end

RegisterNetEvent("ox:setActiveCharacter", function(character)
    if not sync(character) then return end

    if character and character.isNew then
        return events.emit("newCharacter")
    end

    events.emit("playerLoaded")
end)

CreateThread(function()
    if sync() then
        events.emit("playerLoaded")
    end
end)

return framework
