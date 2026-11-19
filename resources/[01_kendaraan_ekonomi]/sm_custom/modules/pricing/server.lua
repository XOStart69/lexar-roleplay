local data = (function()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'data/pricing.json')

    if raw then
        local ok, decoded = pcall(json.decode, raw)

        if ok and type(decoded) == 'table' then return decoded end
    end

    return lib.load('data.pricing')
end)()

---@class PricingServer
local pricing = {}

---@return table
function pricing.data()
    return data
end

---@param key string?
---@return table?
function pricing.of(key)
    local group = key and data.groups and data.groups[key]

    if group then return group.prices end
end

---@param zone table
---@return table?
function pricing.zone(zone)
    local prices = pricing.of(zone.society)

    if prices then return prices end

    for _, group in pairs(data.groups or {}) do
        if group.prices then return group.prices end
    end

    return data.prices or {}
end

function pricing.save()
    SaveResourceFile(GetCurrentResourceName(), 'data/pricing.json', json.encode(data), -1)
end

return pricing
