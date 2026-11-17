local events = require "modules.events"
local storage = require "server.storage.main"

local ESX = exports["es_extended"]:getSharedObject()

local framework = {}

---@param source number
---@return string?
function framework.GetIdentifier(source)
    local player = ESX.GetPlayerFromId(source)

    return player and player.identifier
end

---@param group table?
---@param name string
---@return number?
local function gradeOf(group, name)
    if not group or group.name ~= name then return nil end

    return tonumber(group.grade) or 0
end

---@param source number
---@param name string
---@return number? grade
function framework.PlayerJobGrade(source, name)
    local player = ESX.GetPlayerFromId(source)

    return player and gradeOf(player.job, name) or nil
end

---@param source number
---@param name string
---@return number? grade
function framework.PlayerGangGrade(source, name)
    return nil
end

---@param identifier string
---@return PedAppearance?
function framework.GetAppearance(identifier)
    return storage.getUserClothing(identifier)
end

---@param identifier string
---@param appearance PedAppearance
function framework.SaveAppearance(identifier, appearance)
    storage.saveUserClothing(identifier, appearance)
end

---@param account string
---@return string
local function accountName(account)
    return account == "cash" and "money" or account
end

---@param source number
---@param account string
---@param amount number
---@return boolean
function framework.HasMoney(source, account, amount)
    local player = ESX.GetPlayerFromId(source)

    if not player then return false end

    return player.getAccount(accountName(account)).money >= amount
end

---@param source number
---@param account string
---@param amount number
---@return boolean
function framework.RemoveMoney(source, account, amount)
    local player = ESX.GetPlayerFromId(source)

    if not player then return false end

    local name = accountName(account)

    if player.getAccount(name).money < amount then return false end

    player.removeAccountMoney(name, amount)

    return true
end

RegisterNetEvent("esx:playerLoaded", function(playerId)
    events.emit("playerLoaded", playerId)
end)

---@param name string
---@param cb fun(source: number)
function framework.registerUsableItem(name, cb)
    ESX.RegisterUsableItem(name, cb)
end

return framework
