local QBCore = exports["qb-core"]:GetCoreObject()
local events = require "modules.events"
local storage = require "server.storage.main"

local framework = {}

---@param source number
---@return string?
function framework.GetIdentifier(source)
    local player = QBCore.Functions.GetPlayer(source)

    return player and player.PlayerData.citizenid
end

---@param group table?
---@param name string
---@return number?
local function gradeOf(group, name)
    if not group or group.name ~= name then return nil end

    return type(group.grade) == "table" and (group.grade.level or 0) or tonumber(group.grade) or 0
end

---@param source number
---@param name string
---@return number? grade
function framework.PlayerJobGrade(source, name)
    local player = QBCore.Functions.GetPlayer(source)

    return player and gradeOf(player.PlayerData.job, name) or nil
end

---@param source number
---@param name string
---@return number? grade
function framework.PlayerGangGrade(source, name)
    local player = QBCore.Functions.GetPlayer(source)

    return player and gradeOf(player.PlayerData.gang, name) or nil
end

---@param identifier string
---@param model string?
---@return PedAppearance?
function framework.GetAppearance(identifier, model)
    return storage.getClothing(identifier, model)
end

---@param identifier string
---@param appearance PedAppearance
function framework.SaveAppearance(identifier, appearance)
    storage.saveClothing(identifier, appearance)
end

---@param source number
---@param account string
---@param amount number
---@return boolean
function framework.HasMoney(source, account, amount)
    local player = QBCore.Functions.GetPlayer(source)

    return player ~= nil and (player.PlayerData.money[account] or 0) >= amount
end

---@param source number
---@param account string
---@param amount number
---@return boolean
function framework.RemoveMoney(source, account, amount)
    local player = QBCore.Functions.GetPlayer(source)

    return player ~= nil and player.Functions.RemoveMoney(account, amount) == true
end

RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
    events.emit("playerLoaded", source)
end)

---@param name string
---@param cb fun(source: number)
function framework.registerUsableItem(name, cb)
    QBCore.Functions.CreateUseableItem(name, cb)
end

return framework
