local constants = require "data.constants"
local registry = require "modules.items"
local ped = require "core.ped"
local clothing = require "features.clothing"

---@type table<string, table<string, { drawable: number, texture: number }>>
local worn = {}

local items = {}

---@param slot string
---@return { category: string, id: number }
local function meta(slot)
    return constants.SLOTS[slot]
end

---@param slot string
---@return { drawable: number, texture: number }
local function current(slot)
    local entry = meta(slot)

    if entry.category == "components" then
        return {
            drawable = GetPedDrawableVariation(cache.ped, entry.id),
            texture = GetPedTextureVariation(cache.ped, entry.id)
        }
    end

    return {
        drawable = GetPedPropIndex(cache.ped, entry.id),
        texture = GetPedPropTextureIndex(cache.ped, entry.id)
    }
end

---@param slot string
---@param drawable number
---@param texture number
local function apply(slot, drawable, texture)
    local entry = meta(slot)

    if entry.category == "components" then
        SetPedComponentVariation(cache.ped, entry.id, drawable, texture, 0)

        return
    end

    if drawable < 0 then
        ClearPedProp(cache.ped, entry.id)
    else
        SetPedPropIndex(cache.ped, entry.id, drawable, texture, true)
    end
end

---@param name string
---@return boolean
function items.worn(name)
    return worn[name] ~= nil
end

---@return boolean
function items.anyWorn()
    return next(worn) ~= nil
end

---@return table<string, { drawable: number, texture: number }>
local function heldSlots()
    local held = {}

    for _, previous in pairs(worn) do
        for slot, piece in pairs(previous) do
            held[slot] = piece
        end
    end

    return held
end

---@param slot string
---@return boolean
function items.holds(slot)
    return heldSlots()[slot] ~= nil
end

---@param list table[]
---@param key string
---@return table[]
function items.without(list, key)
    local held = heldSlots()

    if not next(held) then return list end

    local components = key == "component_id"
    local taken = {}

    for slot in pairs(held) do
        local entry = meta(slot)

        if (entry.category == "components") == components then
            taken[entry.id] = true
        end
    end

    local result = table.create(#list, 0)

    for i = 1, #list do
        if not taken[list[i][key]] then
            result[#result + 1] = list[i]
        end
    end

    return result
end

---@param list table[]?
---@param swap table<number, { drawable: number, texture: number }>
---@param key string
---@return table[]?
local function replaced(list, swap, key)
    if not list then return list end

    local result = table.create(#list, 0)

    for i = 1, #list do
        local piece = list[i]
        local under = swap[piece[key]]

        result[i] = under and { [key] = piece[key], drawable = under.drawable, texture = under.texture } or piece
    end

    return result
end

---@param appearance PedAppearance
---@return PedAppearance
function items.underneath(appearance)
    local held = heldSlots()

    if not next(held) then return appearance end

    local swap = { components = {}, props = {} }

    for slot, piece in pairs(held) do
        local entry = meta(slot)

        swap[entry.category][entry.id] = piece
    end

    local result = {}

    for key, value in pairs(appearance) do
        result[key] = value
    end

    result.components = replaced(appearance.components, swap.components, "component_id")
    result.props = replaced(appearance.props, swap.props, "prop_id")

    return result
end

---@param look ClothingItemLook
---@param except string
---@return boolean
local function slotTaken(look, except)
    for name, taken in pairs(worn) do
        if name ~= except then
            for slot in pairs(look) do
                if taken[slot] then return true end
            end
        end
    end

    return false
end

---@param name string
---@return boolean
function items.wear(name)
    if worn[name] then return false end

    if not ped.isFreemode(cache.ped) then
        lib.notify({ description = locale("items.wrongModel"), type = "error" })

        return false
    end

    local look = registry.look(name, ped.gender(cache.ped))

    if not look then
        lib.notify({ description = locale("items.wrongModel"), type = "error" })

        return false
    end

    if slotTaken(look, name) then
        lib.notify({ description = locale("items.slotTaken"), type = "error" })

        return false
    end

    local previous = {}

    for slot, piece in pairs(look) do
        local entry = meta(slot)

        clothing.forget(entry.category == "props" and "prop" or "component", entry.id)

        previous[slot] = current(slot)

        apply(slot, piece.drawable, piece.texture or 0)
    end

    worn[name] = previous

    return true
end

---@param name string
---@return boolean
function items.remove(name)
    local previous = worn[name]

    if not previous then return false end

    worn[name] = nil

    for slot, piece in pairs(previous) do
        apply(slot, piece.drawable, piece.texture)
    end

    return true
end

---@param name string
---@return boolean worn
function items.toggle(name)
    if worn[name] then
        items.remove(name)

        return false
    end

    return items.wear(name)
end

function items.reapply()
    if not next(worn) then return end

    local freemode = ped.isFreemode(cache.ped)
    local gender = ped.gender(cache.ped)

    for name, previous in pairs(worn) do
        local look = freemode and registry.look(name, gender) or nil

        if not look then
            worn[name] = nil
        else
            for slot, piece in pairs(look) do
                previous[slot] = current(slot)

                apply(slot, piece.drawable, piece.texture or 0)
            end
        end
    end
end

function items.clear()
    for name in pairs(worn) do
        items.remove(name)
    end
end

return items
