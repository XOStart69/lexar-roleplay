---@class TransactionRemoval
---@field item string
---@field count integer
---@field slot integer

---@class TransactionAddition
---@field item string
---@field count integer
---@field metadata? table

---@class TransactionContext
---@field remove string alasan log untuk barang yang diambil
---@field add string alasan log untuk barang yang diberikan

local IGNORED_STACK_KEYS = { value = true, rarity = true }

local pairs = pairs
local type = type

---@param a table?
---@param b table?
---@return boolean
local function sameMetadata(a, b)
    a, b = a or {}, b or {}

    for key, value in pairs(a) do
        if not IGNORED_STACK_KEYS[key] and b[key] ~= value then return false end
    end

    for key, value in pairs(b) do
        if not IGNORED_STACK_KEYS[key] and a[key] ~= value then return false end
    end

    return true
end

---@param item string
---@param metadata table?
---@return number
local function itemWeight(item, metadata)
    local weight = type(metadata) == 'table' and metadata.weight
    if type(weight) == 'number' then return weight end

    local data = ox_items[item]
    return data and data.weight or 0
end

---@param source integer
---@param removals TransactionRemoval[]
---@param additions TransactionAddition[]
---@return boolean
local function canApply(source, removals, additions)
    local inventory = ox_inventory:GetInventory(source)
    if not inventory or not inventory.items then return false end

    local slots = {}
    for slot, data in pairs(inventory.items) do
        slots[slot] = { name = data.name, count = data.count, weight = data.weight or 0, metadata = data.metadata }
    end

    local weight = inventory.weight or 0

    for i = 1, #removals do
        local removal = removals[i]
        local slot = slots[removal.slot]

        if not slot or slot.name ~= removal.item or slot.count < removal.count then return false end

        local unitWeight = slot.count > 0 and slot.weight / slot.count or 0

        slot.count -= removal.count
        slot.weight -= unitWeight * removal.count
        weight -= unitWeight * removal.count

        if slot.count == 0 then slots[removal.slot] = nil end
    end

    local free = 0
    for slot = 1, inventory.slots or 0 do
        if not slots[slot] then free += 1 end
    end

    for i = 1, #additions do
        local addition = additions[i]
        local item = ox_items[addition.item]
        if not item then return false end

        weight += itemWeight(addition.item, addition.metadata) * addition.count

        if item.stack then
            local merged = false

            if not item.degrade and not item.durability then
                for _, slot in pairs(slots) do
                    if slot.name == addition.item and sameMetadata(slot.metadata, addition.metadata) then
                        merged = true
                        break
                    end
                end
            end

            if not merged then free -= 1 end
        else
            free -= addition.count
        end

        if free < 0 then return false end
    end

    return weight <= (inventory.maxWeight or 0)
end

---@param source integer
---@param removals TransactionRemoval[]
---@param additions TransactionAddition[]
---@param context TransactionContext
---@return boolean
return function(source, removals, additions, context)
    if not canApply(source, removals, additions) then return false end

    for i = 1, #removals do
        local removal = removals[i]
        ox_inventory:SetLogContext(source, removal.item, context.remove)
        ox_inventory:RemoveItem(source, removal.item, removal.count, nil, removal.slot)
    end

    for i = 1, #additions do
        local addition = additions[i]
        ox_inventory:SetLogContext(source, addition.item, context.add)
        ox_inventory:AddItem(source, addition.item, addition.count, addition.metadata)
    end

    return true
end
