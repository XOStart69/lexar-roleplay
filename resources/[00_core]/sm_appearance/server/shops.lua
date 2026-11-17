local config = require "config.shops"

---@param shopType string
---@return number?
local function costOf(shopType)
    local cost = config.costs[shopType]

    return cost and cost > 0 and cost or nil
end

---@param source number
---@param cost number
---@return boolean
local function take(source, cost)
    if Framework.RemoveMoney(source, config.account, cost) then
        lib.notify(source, {
            description = locale("shops.paid", cost),
            type = "success"
        })

        return true
    end

    lib.notify(source, {
        description = locale("shops.poor"),
        type = "error"
    })

    return false
end

lib.callback.register("rhd_appearance:shops:charge", function(source, shopType)
    local cost = costOf(shopType)

    if not cost then return true end

    return take(source, cost)
end)

lib.callback.register("rhd_appearance:shops:chargeTattoo", function(source)
    local cost = costOf("tattoo")

    if not cost then return true end

    return take(source, cost)
end)
