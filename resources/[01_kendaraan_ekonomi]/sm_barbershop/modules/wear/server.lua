local config = Config
local inventory = exports.ox_inventory

local DEFAULT_USES = 3

local Wear = {}

---@type table<string, integer>
local maxUses = {}

for i = 1, #config.supplies do
    maxUses[config.supplies[i].item] = config.supplies[i].uses or DEFAULT_USES
end

---@param item string
---@return integer
function Wear.max(item)
    return maxUses[item] or DEFAULT_USES
end

---@param metadata table?
---@return integer
function Wear.remaining(metadata)
    local used = metadata and tonumber(metadata.used)

    return used and math.floor(used) or 0
end

---@param item string
---@param used integer
---@param base table?
---@return table
function Wear.metadata(item, used, base)
    local metadata = base and lib.table.deepclone(base) or {}

    metadata.used = used
    metadata.description = ('Sisa pemakaian: %d/%d'):format(used, Wear.max(item))

    return metadata
end

---@param source number
---@param item string
---@return table? slot
function Wear.slot(source, item)
    local slots = inventory:Search(source, 'slots', item)
    local best, bestLeft

    if type(slots) ~= 'table' then return end

    for i = 1, #slots do
        local left = Wear.remaining(slots[i].metadata)

        if left > 0 and (not bestLeft or left < bestLeft) then
            best, bestLeft = slots[i], left
        end
    end

    return best
end

---@param source number
---@param item string
---@return integer? left
function Wear.consume(source, item)
    local slot = Wear.slot(source, item)

    if not slot then return end

    local left = Wear.remaining(slot.metadata) - 1

    if left <= 0 then
        inventory:RemoveItem(source, item, 1, nil, slot.slot)

        return 0
    end

    inventory:SetMetadata(source, slot.slot, Wear.metadata(item, left, slot.metadata))

    return left
end

return Wear
