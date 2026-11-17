local events = require "modules.events"
local storage = require "server.storage.main"

local Ox = require "@ox_core.lib.init"

local framework = {}

---@param source number
---@return string?
function framework.GetIdentifier(source)
    local player = Ox.GetPlayer(source)

    return player and tostring(player.charId)
end

---@param source number
---@param name string
---@return number? grade
function framework.PlayerJobGrade(source, name)
    local player = Ox.GetPlayer(source)

    if not player then return nil end

    return player.getGroups()[name]
end

---@param source number
---@param name string
---@return number? grade
function framework.PlayerGangGrade(source, name)
    return framework.PlayerJobGrade(source, name)
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
    return exports.ox_inventory:GetItemCount(source, account) >= amount
end

---@param source number
---@param account string
---@param amount number
---@return boolean
function framework.RemoveMoney(source, account, amount)
    return exports.ox_inventory:RemoveItem(source, account, amount) == true
end

AddEventHandler("ox:playerLoaded", function(playerId)
    events.emit("playerLoaded", playerId)
end)

---@return boolean registered
function framework.registerUsableItem()
    return false
end

return framework
