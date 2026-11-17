local HEALTH <const> = { 'bodyHealth', 'engineHealth', 'tankHealth' }
local DAMAGE <const> = { 'windows', 'doors', 'tyres' }
local TOGGLES <const> = { modTurbo = true, modXenon = true }
local LINKED <const> = { neonColor = 'neonEnabled', tyreSmokeColor = 'modSmokeEnabled' }
local SERVICES <const> = { repair = true, clean = true }
local WHEELS <const> = {
    [0] = 'sport',
    'muscle',
    'lowrider',
    'suv',
    'offroad',
    'tuner',
    'bike',
    'highend',
    'bennys_original',
    'bennys_bespoke',
    'open_wheel',
    'street',
    'track',
}

---@class CartShared
local cart = {}

---@alias CustomPrices table<string, number | number[] | table<string, number>>

---@param a any
---@param b any
---@return boolean
local function same(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end

    for k, v in pairs(a) do
        if b[k] ~= v then return false end
    end

    for k, v in pairs(b) do
        if a[k] ~= v then return false end
    end

    return true
end

---@param kind integer
---@return string?
function cart.wheel(kind)
    return WHEELS[kind]
end

---@param key string
---@param value any
---@return boolean
local function stock(key, value)
    if value == false then return TOGGLES[key] == true end

    return value == -1 and key:sub(1, 3) == 'mod' and key ~= 'modBackWheels'
end

---@param prices CustomPrices
---@param key string
---@param value any
---@param wheel? integer
---@return number
function cart.price(prices, key, value, wheel)
    local fee = prices.stock

    if type(fee) == 'number' and stock(key, value) then return fee end

    local price = prices[key] or prices.default

    if key == 'extras' then return type(price) == 'number' and price or 0 end

    if type(price) == 'table' then
        if type(value) == 'string' then return price[value] or prices.default end
        if type(value) ~= 'number' or value < 0 then return 0 end
        if price[1] == nil then return price[WHEELS[wheel] or ''] or prices.default end

        return price[math.min(value + 1, #price)]
    end

    return value == false and 0 or price
end

---@param charged table<string, number>
---@return number
local function overlap(charged)
    local saved = 0

    for key, partner in pairs(LINKED) do
        if charged[key] and charged[partner] then saved += math.min(charged[key], charged[partner]) end
    end

    return saved
end

---@param prices CustomPrices
---@param patch table
---@return number
function cart.sum(prices, patch)
    local total, charged = 0, {}

    for key, value in pairs(patch) do
        local price = cart.price(prices, key, value, patch.wheels)

        charged[key] = price
        total += price
    end

    return total - overlap(charged)
end

---@param base table
---@param patch table
---@return table
function cart.merge(base, patch)
    local result = table.clone(base)

    for key, value in pairs(patch) do
        if key == 'extras' then
            local extras = table.clone(base.extras or {})

            for id, state in pairs(value) do
                extras[tonumber(id)] = state
            end

            value = extras
        end

        result[key] = value
    end

    return result
end

---@param prices CustomPrices
---@param base table
---@param patch table
---@return number
function cart.total(prices, base, patch)
    local total, charged = 0, {}
    local wheel = patch.wheels

    if wheel == nil then wheel = base.wheels end

    for key, value in pairs(patch) do
        if key == 'extras' then
            for id, state in pairs(value) do
                if base.extras?[tonumber(id)] ~= state then
                    total += cart.price(prices, key, state)
                end
            end
        elseif not same(base[key], value) then
            local price = cart.price(prices, key, value, wheel)

            charged[key] = price
            total += price
        end
    end

    return total - overlap(charged)
end

---@param props table
---@return table
function cart.repair(props)
    local result = table.clone(props)

    result.repair = nil

    for _, key in ipairs(HEALTH) do
        if result[key] ~= nil then result[key] = 1000 end
    end

    for _, key in ipairs(DAMAGE) do
        if result[key] ~= nil then result[key] = {} end
    end

    return result
end

---@param patch table
---@return boolean
function cart.serviceOnly(patch)
    for key in pairs(patch) do
        if not SERVICES[key] then return false end
    end

    return true
end

---@param patch table
---@return boolean
function cart.serviced(patch)
    return patch.repair == true or patch.clean == true
end

---@param prices CustomPrices
---@param patch table
---@return number
function cart.serviceCost(prices, patch)
    local cost = 0

    for key in pairs(SERVICES) do
        if patch[key] then cost += cart.price(prices, key, true) end
    end

    return cost
end

---@param props table
---@return table
function cart.clean(props)
    local result = table.clone(props)

    result.clean = nil
    result.dirtLevel = 0

    return result
end

return cart
