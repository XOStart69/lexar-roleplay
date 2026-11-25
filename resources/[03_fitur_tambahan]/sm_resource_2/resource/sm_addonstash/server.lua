--[[
    sm_addonstash :: server
    1) Mendaftarkan semua stash lokasi (data/location.lua) ke ox_inventory.
    2) Tas item (config.bags): tiap tas punya stash sendiri berdasarkan metadata `bagId`.
]]

local config = localmodule 'config'
local locations = localmodule 'data.location'

local function register(entry, coords)
    if not entry.name then return end

    exports.ox_inventory:RegisterStash(
        entry.name, entry.label or entry.name, entry.slots or 50, entry.weight or 100000,
        entry.owner or false, entry.groups, type(coords) == 'vector3' and coords or nil)
end

CreateThread(function()
    for i = 1, #locations do
        local entry = locations[i]
        if entry.list then
            for d = 1, #entry.list do register(entry.list[d]) end
        else
            register(entry)
        end
    end
end)

local function newId()
    return ('%x%x'):format(os.time(), math.random(0x100000, 0xFFFFFF))
end

RegisterTokenEvent('sm_addonstash:openBag', function(itemName, slotNumber)
    local src = source
    local bag = config.bags[tostring(itemName)]
    slotNumber = tonumber(slotNumber)
    if not bag or not slotNumber then return end

    local slot = exports.ox_inventory:GetSlot(src, slotNumber)
    if not slot or slot.name ~= itemName then return end

    local metadata = slot.metadata or {}
    if not metadata.bagId then
        metadata.bagId = newId()
        exports.ox_inventory:SetMetadata(src, slotNumber, metadata)
    end

    local id = bag.stashPrefix .. metadata.bagId
    exports.ox_inventory:RegisterStash(id, bag.label, bag.slots, bag.weight, false)
    exports.ox_inventory:forceOpenInventory(src, 'stash', id)
end)

-- batasi isi tas ke allowedItems
for itemName, bag in pairs(config.bags) do
    if bag.allowedItems then
        exports.ox_inventory:registerHook('swapItems', function(payload)
            if payload.toType ~= 'stash' then return end

            local target = tostring(payload.toInventory or '')
            if target:sub(1, #bag.stashPrefix) ~= bag.stashPrefix then return end

            local moving = payload.fromSlot and payload.fromSlot.name
            if moving and not bag.allowedItems[moving] then
                TriggerClientEvent('ox_lib:notify', payload.source, {
                    description = ('%s hanya bisa menyimpan item tertentu.'):format(bag.label), type = 'error' })
                return false
            end
        end, { inventoryFilter = { '^' .. bag.stashPrefix .. '.*' } })
    end
end
