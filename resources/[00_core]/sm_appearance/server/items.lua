local config = require "config.items"

---@type table<number, table<string, true>>
local worn = {}

---@type table<number, true>
local busy = {}

---@param source number
---@param name string
---@return boolean
local function owns(source, name)
    return exports.ox_inventory:GetItemCount(source, name) > 0
end

---@param source number
---@param name string
local function use(source, name)
    if busy[source] or not owns(source, name) then return end

    busy[source] = true

    local wearing = lib.callback.await("rhd_appearance:items:use", source, name)

    busy[source] = nil

    local list = worn[source]

    if not wearing then
        if list then list[name] = nil end

        return
    end

    if not list then
        list = {}
        worn[source] = list
    end

    list[name] = true
end

AddEventHandler("playerDropped", function()
    worn[source] = nil
    busy[source] = nil
end)

---@param payload table
---@return boolean
local function onSwap(payload)
    if payload.fromInventory == payload.toInventory then return true end
    if payload.fromType ~= "player" then return true end

    local list = worn[payload.fromInventory]
    local name = payload.fromSlot and payload.fromSlot.name

    if not list or not name or not list[name] then return true end

    list[name] = nil

    TriggerClientEvent("rhd_appearance:items:refuse", payload.fromInventory, name)

    return false
end

CreateThread(function()
    local filter = {}
    local any = false

    for name in pairs(config) do
        filter[name] = true
        any = true
    end

    if not any then return end

    if GetResourceState("ox_inventory") ~= "started" then
        return lib.print.warn("clothing items are configured but ox_inventory is not running")
    end

    exports.ox_inventory:registerHook("swapItems", onSwap, { print = false, itemFilter = filter })

    for name in pairs(config) do
        local registered = Framework.registerUsableItem(name, function(player)
            use(player, name)
        end)

        if registered == false then
            lib.print.warn(("'%s' cannot be used: this framework has no usable item registry"):format(name))
        end
    end
end)
