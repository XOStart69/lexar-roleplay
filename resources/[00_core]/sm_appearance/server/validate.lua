local pedModels = require "data.peds"
local constants = require "data.constants"
local shared = require "config.general"
local items = require "modules.items"

local NAME_MAX = 50

local GENDER_BY_MODEL = {
    [shared.freemodeModels.male] = "male",
    [shared.freemodeModels.female] = "female"
}

local SLOT_BY_ID = { components = {}, props = {} }

for name, slot in pairs(constants.SLOTS) do
    SLOT_BY_ID[slot.category][slot.id] = name
end

---@type table<string, true>?
local knownModels

local validate = {}

---@param model any
---@return boolean
function validate.model(model)
    if type(model) ~= "string" then return false end

    if not knownModels then
        knownModels = table.create(0, #pedModels)

        for i = 1, #pedModels do
            knownModels[pedModels[i]] = true
        end
    end

    return knownModels[model] == true
end

---@param value any
---@param min number
---@param max number
---@return boolean
function validate.number(value, min, max)
    return type(value) == "number" and value == value and value >= min and value <= max
end

---@param name any
---@return boolean
function validate.outfitName(name)
    return type(name) == "string" and #name > 0 and #name <= NAME_MAX
end

---@param value any
---@param limit number?
---@return boolean
function validate.name(value, limit)
    return type(value) == "string" and #value > 0 and #value <= (limit or NAME_MAX)
end

---@param value any
---@param limit number
---@return boolean
function validate.strings(value, limit)
    if value == nil then return true end
    if type(value) ~= "table" or #value > limit then return false end

    for i = 1, #value do
        if not validate.name(value[i]) then return false end
    end

    return true
end

---@param value any
---@return boolean
function validate.requireJobs(value)
    if value == nil then return true end
    if validate.name(value) then return true end
    if type(value) ~= "table" then return false end

    local count = 0

    for key, entry in pairs(value) do
        count += 1

        if count > 32 then return false end

        if type(key) == "number" then
            if not validate.name(entry) then return false end
        elseif not validate.name(key) then
            return false
        elseif type(entry) == "number" then
            if not validate.number(entry, 0, 100) then return false end
        elseif type(entry) == "table" then
            if #entry == 0 or #entry > 32 then return false end

            for i = 1, #entry do
                if not validate.number(entry[i], 0, 100) then return false end
            end
        else
            return false
        end
    end

    return true
end

---@param list any
---@param key string
---@return boolean
function validate.slots(list, key)
    if type(list) ~= "table" then return false end

    local bounds = constants.RANGES.slot

    for i = 1, #list do
        local slot = list[i]

        if type(slot) ~= "table"
            or not validate.number(slot[key], bounds.id.min, bounds.id.max)
            or not validate.number(slot.drawable, bounds.drawable.min, bounds.drawable.max)
            or not validate.number(slot.texture, bounds.texture.min, bounds.texture.max) then
            return false
        end
    end

    return true
end

---@param appearance table
---@return boolean
local function freeOfItems(appearance)
    local gender = GENDER_BY_MODEL[appearance.model]

    if not gender then return true end

    local components = appearance.components

    for i = 1, #components do
        local piece = components[i]
        local slot = SLOT_BY_ID.components[piece.component_id]

        if slot and items.blocks(gender, slot, piece.drawable, piece.texture) then return false end
    end

    local props = appearance.props

    for i = 1, #props do
        local piece = props[i]
        local slot = SLOT_BY_ID.props[piece.prop_id]

        if slot and items.blocks(gender, slot, piece.drawable, piece.texture) then return false end
    end

    return true
end

---@param appearance any
---@return boolean
function validate.appearance(appearance)
    if type(appearance) ~= "table" then return false end
    if not validate.model(appearance.model) then return false end
    if not validate.slots(appearance.components, "component_id") then return false end
    if not validate.slots(appearance.props, "prop_id") then return false end

    return freeOfItems(appearance)
end

return validate
