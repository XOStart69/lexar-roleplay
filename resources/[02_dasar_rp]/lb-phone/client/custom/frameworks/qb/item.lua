if Config.Framework ~= "qb" then
    return
end

while not QB do
    Wait(500)
    debugprint("Item: Waiting for QB to load")
end

---@param itemName string
---@return boolean
function HasItem(itemName)
    if GetResourceState("ox_inventory") == "started" then
        local slots = exports.ox_inventory:Search("slots", itemName) or {}
        for i = 1, #slots do
            local durability = slots[i].metadata and tonumber(slots[i].metadata.durability)
            if durability == nil or durability > 0 then
                return true
            end
        end
        return false
    end

    return QB.Functions.HasItem(itemName)
end
