---@class CartServer
local cart = {}

local shared = modules.cart

---@param prices table
---@param base table
---@param patch table
---@return number
function cart.total(prices, base, patch)
    return shared.total(prices, base, patch)
end

---@param prices table
---@param patch table
---@return number
function cart.sum(prices, patch)
    return shared.sum(prices, patch)
end

---@param props table
---@return table
function cart.repair(props)
    return shared.repair(props)
end

---@param props table
---@return table
function cart.clean(props)
    return shared.clean(props)
end

return cart
