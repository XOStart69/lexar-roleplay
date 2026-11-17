local config = localmodule 'config.shared'

local function getItemLabel(item)
    return config.itemLabels[item] or item
end

local function getItemCount(item)
    return exports.ox_inventory:GetItemCount(item) or 0
end

local function createRegularSellMenu(configTable, menuTitle, selectEvent)
    local options = {}

    for item, price in pairs(configTable) do
        local itemCount = getItemCount(item)
        local itemLabel = getItemLabel(item)
        local statusText = itemCount > 0 and
            string.format("Kamu punya: %dx %s", itemCount, itemLabel) or
            "❌ Kamu tidak memiliki item ini"

        table.insert(options, {
            title = string.format("%s ($%d per item)", itemLabel, price),
            description = statusText,
            icon = itemCount > 0 and 'fa-solid fa-box' or 'fa-solid fa-box-open',
            event = selectEvent,
            args = item
        })
    end

    if #options == 0 then
        lib.notify({ title = 'Jual Item', description = 'Tidak ada item yang tersedia untuk dijual.', type = 'error' })
        return
    end

    lib.registerContext({ id = 'sell_items_menu', title = menuTitle, options = options })
    lib.showContext('sell_items_menu')
end

local function createBlackmarketCategoryMenu()
    local options = {}

    for categoryId, categoryInfo in pairs(config.blackmarketCategories) do
        table.insert(options, {
            title = string.format('%s %s', categoryInfo.icon, categoryInfo.title),
            description = 'Klik untuk melihat item yang bisa dijual',
            event = 'axon-sellitems:openCategoryMenu',
            args = categoryId
        })
    end

    lib.registerContext({
        id = 'blackmarket_category_menu',
        title = 'Pilih Kategori Blackmarket',
        options = options
    })
    lib.showContext('blackmarket_category_menu')
end

local function createBlackmarketItemMenu(category)
    local categoryData = config.blackmarket[category]
    local categoryInfo = config.blackmarketCategories[category]

    if not categoryData or not categoryInfo then
        lib.notify({ title = 'Error', description = 'Kategori blackmarket tidak ditemukan.', type = 'error' })
        return
    end

    local options = {}

    for item, priceRange in pairs(categoryData) do
        local itemCount = getItemCount(item)
        local itemLabel = getItemLabel(item)
        local statusText = itemCount > 0 and
            string.format("Kamu punya: %dx %s", itemCount, itemLabel) or
            "❌ Kamu tidak memiliki item ini"

        local priceText
        if priceRange.min == priceRange.max then
            priceText = string.format("$%d", priceRange.min)
        else
            priceText = string.format("$%d - $%d", priceRange.min, priceRange.max)
        end

        table.insert(options, {
            title = string.format("%s (%s)", itemLabel, priceText),
            description = statusText .. " | Dibayar dengan black money",
            icon = itemCount > 0 and 'fa-solid fa-gem' or 'fa-solid fa-box-open',
            event = 'axon-sellitems:selectItemBlackmarket',
            args = { item = item, category = category }
        })
    end

    if #options == 0 then
        lib.notify({ title = 'Jual Item Blackmarket', description = 'Tidak ada item yang tersedia untuk dijual.', type = 'error' })
        return
    end

    lib.registerContext({
        id = 'sell_blackmarket_items_menu',
        title = string.format('Jual Barang - %s %s', categoryInfo.title, categoryInfo.icon),
        menu = 'blackmarket_category_menu',
        options = options
    })
    lib.showContext('sell_blackmarket_items_menu')
end

local function createBlackmarketShopCategoryMenu()
    if not config.blackmarketShopCategories then
        lib.notify({ title = 'Error', description = 'Shop tidak tersedia.', type = 'error' })
        return
    end

    local options = {}

    for categoryId, categoryInfo in pairs(config.blackmarketShopCategories) do
        table.insert(options, {
            title = string.format('%s %s', categoryInfo.icon, categoryInfo.title),
            description = 'Klik untuk melihat item yang bisa dibeli',
            event = 'axon-sellitems:openShopCategoryMenu',
            args = categoryId
        })
    end

    lib.registerContext({
        id = 'blackmarket_shop_category_menu',
        title = 'Black Market - Beli Barang',
        options = options
    })
    lib.showContext('blackmarket_shop_category_menu')
end

local function createBlackmarketShopItemMenu(category)
    local categoryData = config.blackmarketShop and config.blackmarketShop[category]
    local categoryInfo = config.blackmarketShopCategories and config.blackmarketShopCategories[category]

    if not categoryData or not categoryInfo then
        lib.notify({ title = 'Error', description = 'Kategori shop tidak ditemukan.', type = 'error' })
        return
    end

    local options = {}

    for item, itemConfig in pairs(categoryData) do
        local itemLabel = itemConfig.label or getItemLabel(item)
        local currencyLabel = itemConfig.currency == 'red_money' and 'Red Money' or 'Black Money'

        table.insert(options, {
            title = string.format("%s ($%d %s)", itemLabel, itemConfig.price, currencyLabel),
            description = 'Klik untuk membeli',
            icon = 'fa-solid fa-cart-shopping',
            event = 'axon-sellitems:selectBuyItem',
            args = { item = item, category = category }
        })
    end

    if #options == 0 then
        lib.notify({ title = 'Black Market Shop', description = 'Tidak ada item tersedia.', type = 'error' })
        return
    end

    lib.registerContext({
        id = 'blackmarket_shop_items_menu',
        title = string.format('%s %s', categoryInfo.icon, categoryInfo.title),
        menu = 'blackmarket_shop_category_menu',
        options = options
    })
    lib.showContext('blackmarket_shop_items_menu')
end

local function selectItemForSale(item, eventName)
    local maxAmount = getItemCount(item)

    if maxAmount == 0 then
        lib.notify({ title = 'Jual Item', description = 'Kamu tidak memiliki item ini.', type = 'error' })
        return
    end

    local sliderMax = math.min(maxAmount, config.maxAmountPerSale or 500)
    local input = lib.inputDialog('Jumlah Item yang Akan Dijual', {
        {
            type = 'slider',
            label = 'Pilih jumlah',
            icon = 'fa-solid fa-box',
            required = true,
            default = 1,
            min = 1,
            max = sliderMax,
            step = 1
        }
    })

    if input and tonumber(input[1]) then
        TriggerTokenEvent(eventName, item, tonumber(input[1]))
    end
end

local function selectItemForSaleBlackmarket(data)
    local maxAmount = getItemCount(data.item)

    if maxAmount == 0 then
        lib.notify({ title = 'Jual Item Blackmarket', description = 'Kamu tidak memiliki item ini.', type = 'error' })
        return
    end

    local sliderMax = math.min(maxAmount, config.maxAmountPerSale or 500)
    local input = lib.inputDialog('Jumlah Item yang Akan Dijual', {
        {
            type = 'slider',
            label = 'Pilih jumlah',
            icon = 'fa-solid fa-gem',
            required = true,
            default = 1,
            min = 1,
            max = sliderMax,
            step = 1
        }
    })

    if input and tonumber(input[1]) then
        TriggerTokenEvent('axon-sellitems:sellBlackmarket', data.item, tonumber(input[1]), data.category)
    end
end

local function selectItemForPurchase(data)
    local input = lib.inputDialog('Jumlah Item yang Akan Dibeli', {
        {
            type = 'slider',
            label = 'Pilih jumlah',
            icon = 'fa-solid fa-cart-shopping',
            required = true,
            default = 1,
            min = 1,
            max = config.maxAmountPerPurchase or 50,
            step = 1
        }
    })

    if input and tonumber(input[1]) then
        TriggerTokenEvent('axon-sellitems:buyBlackmarket', data.item, tonumber(input[1]), data.category)
    end
end

RegisterNetEvent('axon-sellitems:openSellMenu', function()
    createRegularSellMenu(config.sellableItems, 'Jual Barang - Government', 'axon-sellitems:selectItem')
end)

RegisterNetEvent('axon-sellitems:openSellMenuPawn', function()
    createRegularSellMenu(config.sellableItemsPawn, 'Jual Barang - Pawn Shop', 'axon-sellitems:selectItemPawn')
end)

RegisterNetEvent('axon-sellitems:openSellMenuFishingMan', function()
    createRegularSellMenu(config.fishingMan, 'Jual Ikan - Fishing 🐟', 'axon-sellitems:selectItemFishingMan')
end)

RegisterNetEvent('axon-sellitems:openSellMenuBlackmarket', function()
    createBlackmarketCategoryMenu()
end)

RegisterNetEvent('axon-sellitems:openCategoryMenu', function(category)
    createBlackmarketItemMenu(category)
end)

RegisterNetEvent('axon-sellitems:openSellMenuShopBlackmarket', function()
    createBlackmarketShopCategoryMenu()
end)

RegisterNetEvent('axon-sellitems:openShopCategoryMenu', function(category)
    createBlackmarketShopItemMenu(category)
end)

RegisterNetEvent('axon-sellitems:selectItem', function(item)
    selectItemForSale(item, 'axon-sellitems:sellItem')
end)

RegisterNetEvent('axon-sellitems:selectItemPawn', function(item)
    selectItemForSale(item, 'axon-sellitems:sellItemPawn')
end)

RegisterNetEvent('axon-sellitems:selectItemFishingMan', function(item)
    selectItemForSale(item, 'axon-sellitems:sellItemFishingMan')
end)

RegisterNetEvent('axon-sellitems:selectItemBlackmarket', function(data)
    selectItemForSaleBlackmarket(data)
end)

RegisterNetEvent('axon-sellitems:selectBuyItem', function(data)
    selectItemForPurchase(data)
end)