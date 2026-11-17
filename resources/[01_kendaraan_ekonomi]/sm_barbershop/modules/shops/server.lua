local config = Config
local limits = config.limits

local Shops = { list = {}, byId = {} }

---@param key string
---@param value any
---@return integer?
local function itemPrice(key, value)
    local price = tonumber(value)
    local min, max = Pricing.bounds(key)

    if not price or price ~= price then return end

    price = math.floor(price)

    if price < min or price > max then return end

    return price
end

---@param key string
---@param value any
---@return integer
local function storedPrice(key, value)
    local price = tonumber(value)

    if not price or price ~= price then return Pricing.defaultPrice(key) end

    local min, max = Pricing.bounds(key)

    return math.min(max, math.max(min, math.floor(price)))
end

---@param value any
---@return integer?
local function selfServiceRate(value)
    local rate = tonumber(value)

    if not rate or rate ~= rate then return end

    rate = math.floor(rate)

    if rate < limits.minSelfServiceRate or rate > limits.maxSelfServiceRate then return end

    return rate
end

---@param value any
---@return string?
local function shopName(value)
    return Text.name(value, limits.minShopName, limits.maxShopName)
end

---@param raw any
---@return table<string, integer>
local function decodePrices(raw)
    local ok, decoded = pcall(json.decode, type(raw) == 'string' and raw or 'null')
    local stored = ok and type(decoded) == 'table' and decoded or {}
    local prices = {}

    for i = 1, #config.priceItems do
        local item = config.priceItems[i]

        prices[item.key] = storedPrice(item.key, stored[item.key])
    end

    return prices
end

function Shops.init()
    local rows = Storage.loadShops()

    for i = 1, #config.shops do
        local entry = config.shops[i]
        local row = rows[entry.id]

        ---@type BarberShop
        local shop = {
            id = entry.id,
            label = shopName(row and row.name) or entry.label,
            defaultLabel = entry.label,
            chairs = entry.coords.chairs,
            purchasePrice = config.purchesable_shop.price,
            purchesable = config.purchesable_shop.enable == true,
            ownerCitizenId = row and row.owner_citizenid or nil,
            ownerName = row and row.owner_name or nil,
            balance = row and math.floor(tonumber(row.balance) or 0) or 0,
            commissionRate = row and math.floor(tonumber(row.commission_rate) or 0) or config.defaults.commissionRate,
            selfServiceRate = selfServiceRate(row and row.self_service_rate) or config.defaults.selfServiceRate,
            itemPrices = decodePrices(row and row.item_prices),
        }

        if not row then
            Storage.saveShop(shop)
        end

        Shops.list[#Shops.list + 1] = shop
        Shops.byId[shop.id] = shop
    end
end

---@param id any
---@return BarberShop?
function Shops.get(id)
    if type(id) ~= 'string' then return end

    return Shops.byId[id]
end

---@param shop BarberShop
---@param index any
---@return vector4?
function Shops.chair(shop, index)
    if type(index) == 'string' then return Portable.chair(shop.id, index) end
    if type(index) ~= 'number' then return end

    return shop.chairs[index]
end

---@param shop BarberShop
---@return boolean
function Shops.isOwned(shop)
    return shop.ownerCitizenId ~= nil
end

---@param shop BarberShop
---@return boolean
function Shops.isOperational(shop)
    return Shops.isOwned(shop) and Staff.dutyCount(shop.id) > 0
end

---@param shop BarberShop
---@return boolean
function Shops.selfServiceAllowed(shop)
    return not Shops.isOperational(shop)
end

---@param shop BarberShop
function Shops.sync(shop)
    local operational = Shops.isOperational(shop)

    Sync.setState(shop.id, {
        label = shop.label,
        owned = Shops.isOwned(shop),
        ownerName = shop.ownerName,
        purchasePrice = shop.purchasePrice,
        purchesable = shop.purchesable,
        selfServiceRate = shop.selfServiceRate,
        staffOnDuty = Staff.dutyCount(shop.id),
        operational = operational,
        selfService = not operational,
    })
end

function Shops.syncAll()
    for i = 1, #Shops.list do
        Shops.sync(Shops.list[i])
    end
end

---@param shop BarberShop
function Shops.save(shop)
    Storage.saveShop(shop)
    Shops.sync(shop)
end

---@param shop BarberShop
---@param citizenId string?
---@param name string?
function Shops.setOwner(shop, citizenId, name)
    if shop.ownerCitizenId ~= citizenId then
        shop.label = shop.defaultLabel
    end

    shop.ownerCitizenId = citizenId
    shop.ownerName = name
    Shops.save(shop)
end

---@param shop BarberShop
---@param value any
---@return boolean
function Shops.setName(shop, value)
    local name = value == '' and shop.defaultLabel or shopName(value)

    if not name then return false end

    shop.label = name
    Shops.save(shop)

    return true
end

---@param shop BarberShop
---@param delta number
---@return number balance
function Shops.addBalance(shop, delta)
    shop.balance = math.max(0, shop.balance + math.floor(delta))
    Shops.save(shop)

    return shop.balance
end

---@param shop BarberShop
---@param payload { itemPrices: any, commissionRate: any, selfServiceRate: any }
---@return boolean
function Shops.setPrices(shop, payload)
    local commissionRate = tonumber(payload.commissionRate)
    local rate = selfServiceRate(payload.selfServiceRate)

    if not commissionRate or commissionRate ~= commissionRate or not rate or type(payload.itemPrices) ~= 'table' then
        return false
    end

    commissionRate = math.floor(commissionRate)

    if commissionRate < 0 or commissionRate > limits.maxCommissionRate then return false end

    local prices = {}

    for i = 1, #config.priceItems do
        local key = config.priceItems[i].key
        local price = itemPrice(key, payload.itemPrices[key])

        if not price then return false end

        prices[key] = price
    end

    shop.itemPrices = prices
    shop.commissionRate = commissionRate
    shop.selfServiceRate = rate
    Shops.save(shop)

    return true
end

---@param shop BarberShop
---@param mode 'barber'|'self'
---@return table<string, integer>
function Shops.priceList(shop, mode)
    local list = {}

    for key, price in pairs(shop.itemPrices) do
        list[key] = mode == 'self' and math.floor(price * shop.selfServiceRate / 100 + 0.5) or price
    end

    return list
end

---@param shop BarberShop
---@return BarberShopPublic
function Shops.publicData(shop)
    return {
        id = shop.id,
        label = shop.label,
        defaultLabel = shop.defaultLabel,
        owned = Shops.isOwned(shop),
        ownerName = shop.ownerName,
        balance = shop.balance,
        commissionRate = shop.commissionRate,
        selfServiceRate = shop.selfServiceRate,
        itemPrices = shop.itemPrices,
        purchasePrice = shop.purchasePrice,
    }
end

return Shops
