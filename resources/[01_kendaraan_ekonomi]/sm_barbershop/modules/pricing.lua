local config = Config

local Pricing = {}

local OPACITY_EPSILON = 0.001

local MIN_VALUES = {
    style = -1,
    texture = 0,
    color = 0,
    highlight = 0,
    secondColor = 0,
    fade = -1,
    eyeColor = 0,
}

---@type table<string, BarberPriceItem>
local byKey = {}

for i = 1, #config.priceItems do
    local item = config.priceItems[i]

    byKey[item.key] = item
end

Pricing.byKey = byKey

---@type table<string, BarberPriceGroup>
local groups = {}

for i = 1, #config.priceGroups do
    groups[config.priceGroups[i].id] = config.priceGroups[i]
end

---@param key string
---@return integer min
---@return integer max
function Pricing.bounds(key)
    local item = byKey[key]
    local group = item and groups[item.group]

    if not group then return 0, 0 end

    return group.min, group.max
end

---@param key string
---@return integer
function Pricing.defaultPrice(key)
    local min, max = Pricing.bounds(key)

    return math.floor((min + max) / 2)
end

---@param key string
---@return string section
---@return string? field
local function split(key)
    local section, field = key:match('^(%w+)%.(%w+)$')

    if section then
        return section, field
    end

    return key
end

---@param appearance table
---@param key string
---@return number?
function Pricing.read(appearance, key)
    local section, field = split(key)

    if not field then
        return tonumber(appearance[section])
    end

    local source = section == 'hair' and appearance.hair or (appearance.headOverlays and appearance.headOverlays[section])

    return source and tonumber(source[field]) or nil
end

---@param appearance table
---@param key string
---@param value number
function Pricing.write(appearance, key, value)
    local section, field = split(key)

    if not field then
        appearance[section] = value

        return
    end

    if section == 'hair' then
        appearance.hair = appearance.hair or {}
        appearance.hair[field] = value

        return
    end

    appearance.headOverlays = appearance.headOverlays or {}
    appearance.headOverlays[section] = appearance.headOverlays[section] or { style = 0, opacity = 0.0, color = 0, secondColor = 0 }
    appearance.headOverlays[section][field] = value
end

---@param field string
---@param value any
---@return number?
local function normalizeField(field, value)
    local number = tonumber(value)

    if not number or number ~= number then return end

    if field == 'opacity' then
        return math.floor(math.min(1, math.max(0, number)) * 100 + 0.5) / 100
    end

    local min = MIN_VALUES[field]
    local integer = min and math.tointeger(math.floor(number))

    if not integer or integer < min then return end

    return integer
end

---@param key string
---@param value any
---@return number?
function Pricing.normalize(key, value)
    if not byKey[key] then return end

    local _, field = split(key)

    return normalizeField(field or key, value)
end

local HAIR_FIELDS = { 'style', 'texture', 'color', 'highlight', 'fade' }
local OVERLAY_FIELDS = { 'style', 'opacity', 'color', 'secondColor' }

local OVERLAYS = {
    blemishes = true,
    beard = true,
    eyebrows = true,
    ageing = true,
    makeUp = true,
    blush = true,
    complexion = true,
    sunDamage = true,
    lipstick = true,
    moleAndFreckles = true,
    chestHair = true,
    bodyBlemishes = true,
}

---@param values any
---@return BarberAppearanceFields?
function Pricing.sanitizePreview(values)
    if type(values) ~= 'table' then return end

    local clean, any = {}, false

    if values.hair ~= nil then
        if type(values.hair) ~= 'table' then return end

        local hair = {}

        for i = 1, #HAIR_FIELDS do
            local field = HAIR_FIELDS[i]
            local value = normalizeField(field, values.hair[field])

            if value == nil then return end

            hair[field] = value
        end

        clean.hair, any = hair, true
    end

    if values.headOverlays ~= nil then
        if type(values.headOverlays) ~= 'table' then return end

        local overlays = {}

        for name, overlay in pairs(values.headOverlays) do
            if not OVERLAYS[name] or type(overlay) ~= 'table' then return end

            local entry = {}

            for i = 1, #OVERLAY_FIELDS do
                local field = OVERLAY_FIELDS[i]
                local value = normalizeField(field, overlay[field])

                if value == nil then return end

                entry[field] = value
            end

            overlays[name] = entry
            any = true
        end

        clean.headOverlays = overlays
    end

    if values.eyeColor ~= nil then
        local value = normalizeField('eyeColor', values.eyeColor)

        if value == nil then return end

        clean.eyeColor, any = value, true
    end

    return any and clean or nil
end

---@param appearance table
---@return BarberAppearanceFields
function Pricing.barberFields(appearance)
    return {
        hair = appearance.hair,
        headOverlays = appearance.headOverlays,
        eyeColor = appearance.eyeColor,
    }
end

---@param items BarberLineItem[]
---@return { label: string, price: integer }[]
function Pricing.describe(items)
    local lines = {}

    for i = 1, #items do
        local item = items[i]
        local group = groups[item.group] and groups[item.group].label or item.group

        lines[i] = {
            label = item.key == item.group and group or ('%s · %s'):format(group, item.label),
            price = item.price,
        }
    end

    return lines
end

---@param values any
---@return table<string, number>
function Pricing.sanitize(values)
    local clean = {}

    if type(values) ~= 'table' then return clean end

    for key, value in pairs(values) do
        if type(key) == 'string' then
            clean[key] = Pricing.normalize(key, value)
        end
    end

    return clean
end

---@param key string
---@param before number?
---@param after number?
---@return boolean
local function differs(key, before, after)
    if before == nil or after == nil then
        return before ~= after
    end

    if key:sub(-8) == '.opacity' then
        return math.abs(before - after) > OPACITY_EPSILON
    end

    return before ~= after
end

---@param original table
---@param values table<string, number>
---@param prices table<string, number>
---@return table final
---@return BarberLineItem[] items
---@return integer total
function Pricing.apply(original, values, prices)
    local final = lib.table.deepclone(original)
    local changed = {}

    for i = 1, #config.priceItems do
        local key = config.priceItems[i].key
        local value = values[key]

        if value ~= nil and differs(key, Pricing.read(original, key), value) then
            Pricing.write(final, key, value)
            changed[key] = true
        end
    end

    local items, total = {}, 0

    for i = 1, #config.priceItems do
        local item = config.priceItems[i]

        if changed[item.key] then
            local price = (item.includedWith and changed[item.includedWith]) and 0 or math.floor(prices[item.key] or 0)

            items[#items + 1] = { key = item.key, group = item.group, label = item.label, price = price }
            total += price
        end
    end

    return final, items, total
end

local CUT_GROUPS = { hair = true, beard = true, eyebrows = true, chestHair = true }

---@param items BarberLineItem[]
---@return boolean
function Pricing.needsCut(items)
    for i = 1, #items do
        if CUT_GROUPS[items[i].group] then
            return true
        end
    end

    return false
end

return Pricing
