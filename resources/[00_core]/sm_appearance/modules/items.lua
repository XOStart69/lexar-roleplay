local config = require "config.items"
local constants = require "data.constants"

---@type table<string, BlacklistEntry[]>?
local cache

local items = {}

---@return table<string, BlacklistEntry[]>
local function index()
    if cache then return cache end

    cache = {}

    ---@type table<string, table<number, number[]|false>>
    local byDrawable = {}

    for name, genders in pairs(config) do
        for gender, look in pairs(genders) do
            for slot, piece in pairs(look) do
                if not constants.SLOTS[slot] then
                    error(("rhd_appearance: item '%s' uses unknown slot '%s'"):format(name, slot))
                end

                if not piece.free then
                    local key = gender .. "/" .. slot
                    local drawables = byDrawable[key]

                    if not drawables then
                        drawables = {}
                        byDrawable[key] = drawables
                    end

                    local current = drawables[piece.drawable]

                    if piece.texture == nil then
                        drawables[piece.drawable] = false
                    elseif current ~= false then
                        current = current or {}
                        current[#current + 1] = piece.texture
                        drawables[piece.drawable] = current
                    end
                end
            end
        end
    end

    for key, drawables in pairs(byDrawable) do
        local entries = {}
        local whole = {}

        for drawable, textures in pairs(drawables) do
            if textures == false then
                whole[#whole + 1] = drawable
            else
                entries[#entries + 1] = { drawables = { drawable }, textures = textures }
            end
        end

        if #whole > 0 then
            entries[#entries + 1] = { drawables = whole }
        end

        cache[key] = entries
    end

    return cache
end

---@param gender string
---@param slot string
---@return BlacklistEntry[]?
function items.entries(gender, slot)
    return index()[gender .. "/" .. slot]
end

---@param gender string
---@param slot string
---@param drawable number
---@param texture number
---@return boolean
function items.blocks(gender, slot, drawable, texture)
    local entries = items.entries(gender, slot)

    if not entries then return false end

    for i = 1, #entries do
        local entry = entries[i]
        local list = entry.drawables

        for j = 1, #list do
            if list[j] == drawable then
                if not entry.textures then return true end

                for k = 1, #entry.textures do
                    if entry.textures[k] == texture then return true end
                end
            end
        end
    end

    return false
end

---@param name string
---@param gender string
---@return ClothingItemLook?
function items.look(name, gender)
    local entry = config[name]

    return entry and entry[gender]
end

---@param name string
---@return boolean
function items.exists(name)
    return config[name] ~= nil
end

return items
