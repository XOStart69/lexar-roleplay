local config = localmodule 'config'
local stashes = localmodule 'data.location'
local exportWrapper = require 'export_wrapper'
local interact = exports.rhd_interact

local DISTANCE = config.interactDistance

---@param data table
---@param coords vector3[]
local function addTargetStash(data, coords)
    local name = data.name
    local options = {
        {
            name = 'sm_addonstash_' .. name,
            label = 'Buka ' .. data.label,
            icon = 'fas fa-warehouse',
            groups = data.groups,
            distance = DISTANCE,
            onSelect = function()
                ox_inventory:openInventory('stash', name)
            end,
        },
    }

    for i = 1, #coords do
        ox_target:addSphereZone({
            name = ('sm_addonstash_%s_%d'):format(name, i),
            coords = coords[i],
            radius = 1.0,
            options = options,
        })
    end
end

---@param data table
---@param coords vector3|vector3[]
local function addStash(data, coords)
    if type(coords) ~= 'table' then coords = { coords } end

    if data.target then
        return addTargetStash(data, coords)
    end

    local name = data.name
    local options = {
        {
            label = 'Buka ' .. data.label,
            icon = 'warehouse',
            groups = data.groups,
            distance = DISTANCE,
            onSelect = function()
                ox_inventory:openInventory('stash', name)
            end,
        },
    }

    for i = 1, #coords do
        interact:addCoords({
            id = ('sm_addonstash_%s_%d'):format(name, i),
            coords = coords[i],
            options = options,
        })
    end
end

CreateThread(function()
    for i = 1, #stashes do
        local entry = stashes[i]
        local list = entry.list

        if list then
            for d = 1, #list do
                addStash(list[d], entry.coords)
            end
        else
            addStash(entry, entry.coords)
        end
    end
end)

for itemName, bag in pairs(config.bags) do
    local function useBag(_, slot)
        TriggerTokenEvent('sm_addonstash:openBag', itemName, slot.slot)
        return true
    end

    exports(bag.export, useBag)
    exportWrapper('sm_addonstash', bag.export, useBag)
end
