--[[
    sm_pets :: server/shop
    Toko NPC statis dan toko pemain (stok, harga, riwayat penjualan), plus pembelian pet/barang.
]]

local Config = localmodule 'config.shared'
local Catalog = localmodule 'config.catalog'
local Pets = localmodule 'config.pets'
local S = SmPetsServer

local QBCore = exports['qb-core']:GetCoreObject()

local shopConfig = Config.Shop or {}
local playerShop = Config.PlayerShop or {}
local consumables = Catalog.consumables or {}
local wardrobe = Catalog.wardrobe or {}

local MONEY = Config.MoneyAccount or 'cash'
local MAX_OWNED = Config.MaxOwnedPets or 5
local NAME_LEN = Config.NameLength or { min = 2, max = 20 }

local shops = {}
local npcShops = shopConfig.npc or {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_pets_shops` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(64) NOT NULL,
    `job` varchar(64) NOT NULL,
    `manageGrade` int(11) NOT NULL DEFAULT 2,
    `vetGrade` int(11) NOT NULL DEFAULT 1,
    `wholesale` double NOT NULL DEFAULT 0.7,
    `points` longtext NULL,
    `blip` longtext NULL,
    PRIMARY KEY (`id`),
    KEY `job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sm_pets_stock` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `shop_id` int(11) NOT NULL,
    `item_key` varchar(64) NOT NULL,
    `price` int(11) NOT NULL,
    `amount` int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `shop_item` (`shop_id`, `item_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sm_pets_sales` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `shop_id` int(11) NOT NULL,
    `citizenid` varchar(64) NOT NULL,
    `total` int(11) NOT NULL,
    `items` longtext NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `shop_id` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function notify(src, message, nType)
    lib.notify(src, { title = 'Pet Shop', description = message, type = nType or 'inform' })
end

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function decode(raw, fallback)
    if type(raw) == 'table' then return raw end
    if not raw or raw == '' then return fallback end

    local ok, value = pcall(json.decode, raw)
    return ok and value or fallback
end

local function jobOf(src)
    local player = ply(src)
    local job = player and player.PlayerData.job
    if not job then return nil, 0 end

    return job.name, tonumber(type(job.grade) == 'table' and job.grade.level or job.grade) or 0
end

local function isAdmin(src)
    if IsPlayerAceAllowed(src, 'admin') then return true end

    local name = jobOf(src)
    local adminJobs = Config.AdminJobs or {}

    return name ~= nil and adminJobs[name] == true
end

local function isManager(src, shop)
    local name, grade = jobOf(src)
    if not name or name ~= shop.job then return false end

    return grade >= (tonumber(shop.manageGrade) or 2)
end

local function petType(id)
    for i = 1, #Pets do
        if Pets[i].id == id then return Pets[i] end
    end
end

local function ownedCount(citizenid)
    return MySQL.scalar.await('SELECT COUNT(*) FROM sm_pets_pets WHERE citizenid = ?', { citizenid }) or 0
end

local function buildGlobalState()
    local list = {}

    for id, shop in pairs(shops) do
        list[#list + 1] = {
            id = id,
            name = shop.name,
            job = shop.job,
            manageGrade = shop.manageGrade,
            points = shop.points,
            blip = shop.blip
        }
    end

    GlobalState.smPetShops = list
end

local function shopData(shop)
    local stock = MySQL.query.await('SELECT item_key, price, amount FROM sm_pets_stock WHERE shop_id = ?', { shop.id }) or {}
    local rows = {}

    for i = 1, #stock do
        rows[#rows + 1] = { key = stock[i].item_key, price = tonumber(stock[i].price), amount = tonumber(stock[i].amount) }
    end

    local sales = MySQL.query.await(
        'SELECT citizenid, total, items, created_at FROM sm_pets_sales WHERE shop_id = ? ORDER BY id DESC LIMIT ?',
        { shop.id, shopConfig.salesHistory or 50 }
    ) or {}

    local history = {}

    for i = 1, #sales do
        history[#history + 1] = {
            citizenid = sales[i].citizenid,
            total = tonumber(sales[i].total),
            items = decode(sales[i].items, {}),
            at = tostring(sales[i].created_at)
        }
    end

    return { ok = true, shopId = shop.id, stock = rows, sales = history, wholesale = shop.wholesale }
end

lib.callback.register('sm_pets:shop:open', function(src, ref)
    local player = ply(src)
    if not player then return { ok = false, msg = 'Data pemain tidak ditemukan.' } end

    if type(ref) ~= 'string' then return { ok = false, msg = 'Toko tidak dikenal.' } end

    local npcIndex = tonumber(ref:match('^npc:(%d+)$'))
    local shopId = tonumber(ref:match('^shop:(%d+)$'))

    local entry, stock

    if npcIndex then
        entry = npcShops[npcIndex]
        if not entry then return { ok = false, msg = 'Toko tidak dikenal.' } end

        if entry.jobs then
            local name = jobOf(src)
            if not name or not entry.jobs[name] then
                return { ok = false, msg = 'Job kamu tidak boleh belanja di sini.' }
            end
        end
    elseif shopId then
        local shop = shops[shopId]
        if not shop then return { ok = false, msg = 'Toko sudah tidak ada.' } end

        entry = { label = shop.name, k9 = false }
        stock = {}

        local rows = MySQL.query.await('SELECT item_key, price, amount FROM sm_pets_stock WHERE shop_id = ?', { shopId }) or {}

        for i = 1, #rows do
            stock[rows[i].item_key] = { price = tonumber(rows[i].price), amount = tonumber(rows[i].amount) }
        end
    else
        return { ok = false, msg = 'Toko tidak dikenal.' }
    end

    local pets = {}

    local owned = MySQL.query.await('SELECT * FROM sm_pets_pets WHERE citizenid = ?', { player.PlayerData.citizenid }) or {}

    for i = 1, #owned do
        pets[#pets + 1] = {
            id = owned[i].id,
            type = owned[i].type,
            name = owned[i].name,
            health = tonumber(owned[i].health) or 0,
            k9 = tonumber(owned[i].k9) == 1
        }
    end

    return {
        ok = true,
        ref = ref,
        name = entry.label,
        npc = npcIndex ~= nil,
        money = player.PlayerData.money[MONEY] or 0,
        k9 = entry.k9 == true,
        maxOwned = MAX_OWNED,
        pets = pets,
        stock = stock,
        sellItems = shopConfig.sellItems == true,
        showHidden = isAdmin(src)
    }
end)

lib.callback.register('sm_pets:shop:buyPet', function(src, ref, typeId, name)
    local player = ply(src)
    if not player then return { ok = false, msg = 'Data pemain tidak ditemukan.' } end

    local entry = petType(typeId)
    if not entry then return { ok = false, msg = 'Jenis pet tidak dikenal.' } end

    if type(name) ~= 'string' then return { ok = false, msg = 'Nama pet tidak valid.' } end
    name = name:sub(1, NAME_LEN.max)

    if #name < NAME_LEN.min then
        return { ok = false, msg = ('Nama minimal %d karakter.'):format(NAME_LEN.min) }
    end

    local citizenid = player.PlayerData.citizenid
    if ownedCount(citizenid) >= MAX_OWNED then
        return { ok = false, msg = ('Maksimal %d pet.'):format(MAX_OWNED) }
    end

    local price = tonumber(entry.price) or 0

    local npcIndex = type(ref) == 'string' and tonumber(ref:match('^npc:(%d+)$'))
    local shopId = type(ref) == 'string' and tonumber(ref:match('^shop:(%d+)$'))

    if shopId then
        local row = MySQL.single.await(
            'SELECT price, amount FROM sm_pets_stock WHERE shop_id = ? AND item_key = ?',
            { shopId, ('pet:%s'):format(typeId) }
        )

        if not row or tonumber(row.amount) < 1 then
            return { ok = false, msg = 'Stok habis.' }
        end

        price = tonumber(row.price) or price
    elseif not npcIndex then
        return { ok = false, msg = 'Toko tidak dikenal.' }
    end

    if (player.PlayerData.money[MONEY] or 0) < price then
        return { ok = false, msg = ('Uang tidak cukup ($%s).'):format(price) }
    end

    if price > 0 then player.Functions.RemoveMoney(MONEY, price, 'pet-shop') end

    if shopId then
        MySQL.update.await('UPDATE sm_pets_stock SET amount = amount - 1 WHERE shop_id = ? AND item_key = ?', {
            shopId, ('pet:%s'):format(typeId)
        })
    end

    local skills = {}
    for name_, cfg in pairs((Config.K9 and Config.K9.skills) or {}) do
        skills[name_] = cfg.default
    end

    MySQL.insert.await([[
        INSERT INTO sm_pets_pets (citizenid, type, name, species, model, health, k9, skills)
        VALUES (?, ?, ?, ?, ?, 100, ?, ?)
    ]], {
        citizenid, entry.id, name, entry.species, entry.model,
        entry.k9 and 1 or 0, json.encode(skills)
    })

    return { ok = true, msg = ('%s dibeli.'):format(name) }
end)

lib.callback.register('sm_pets:shop:buyItems', function(src, ref, cart, petId)
    local player = ply(src)
    if not player then return { ok = false, msg = 'Data pemain tidak ditemukan.' } end
    if type(cart) ~= 'table' or #cart == 0 then return { ok = false, msg = 'Keranjang kosong.' } end

    local shopId = type(ref) == 'string' and tonumber(ref:match('^shop:(%d+)$'))
    local stock = {}

    if shopId then
        local rows = MySQL.query.await('SELECT item_key, price, amount FROM sm_pets_stock WHERE shop_id = ?', { shopId }) or {}

        for i = 1, #rows do
            stock[rows[i].item_key] = { price = tonumber(rows[i].price), amount = tonumber(rows[i].amount) }
        end
    end

    local pet
    if petId then
        local row = MySQL.single.await('SELECT * FROM sm_pets_pets WHERE id = ? AND citizenid = ?', {
            tonumber(petId) or 0, player.PlayerData.citizenid
        })

        if row then
            pet = { id = row.id, wardrobe = decode(row.wardrobe, {}) }
        end
    end

    local total, lines = 0, {}
    local maxQty = shopConfig.maxQty or 500

    for i = 1, #cart do
        local line = cart[i]
        local key = type(line) == 'table' and line.key
        local qty = type(line) == 'table' and math.floor(tonumber(line.qty) or 0) or 0

        if type(key) == 'string' and qty > 0 and qty <= maxQty then
            local item = consumables[key] or wardrobe[key]

            if item then
                local price = tonumber(item.price) or 0

                if stock[key] then
                    if stock[key].amount < qty then return { ok = false, msg = ('Stok %s habis.'):format(item.label or key) } end
                    price = stock[key].price
                end

                total = total + price * qty
                lines[#lines + 1] = { key = key, qty = qty, item = item }
            end
        end
    end

    if #lines == 0 then return { ok = false, msg = 'Tidak ada item valid.' } end
    if (player.PlayerData.money[MONEY] or 0) < total then
        return { ok = false, msg = ('Uang tidak cukup ($%s).'):format(total) }
    end

    if total > 0 then player.Functions.RemoveMoney(MONEY, total, 'pet-shop') end

    for i = 1, #lines do
        local line = lines[i]

        if consumables[line.key] then
            local itemName = line.item.item or line.key
            exports.ox_inventory:AddItem(src, itemName, (line.item.amount or 1) * line.qty)
        elseif pet then
            local list = pet.wardrobe
            local known = {}

            for j = 1, #list do known[list[j]] = true end

            for _ = 1, line.qty do
                if not known[line.key] then
                    list[#list + 1] = line.key
                    known[line.key] = true
                end
            end

            pet.wardrobe = list
        end

        if shopId then
            MySQL.update.await('UPDATE sm_pets_stock SET amount = GREATEST(0, amount - ?) WHERE shop_id = ? AND item_key = ?', {
                line.qty, shopId, line.key
            })
        end
    end

    if pet then
        MySQL.update.await('UPDATE sm_pets_pets SET wardrobe = ? WHERE id = ?', { json.encode(pet.wardrobe), pet.id })
    end

    if shopId then
        local receipt = {}
        for i = 1, #lines do receipt[#receipt + 1] = { key = lines[i].key, qty = lines[i].qty } end

        MySQL.insert.await('INSERT INTO sm_pets_sales (shop_id, citizenid, total, items) VALUES (?, ?, ?, ?)', {
            shopId, player.PlayerData.citizenid, total, json.encode(receipt)
        })
    end

    return { ok = true, msg = ('Pembelian selesai ($%s).'):format(total) }
end)

lib.callback.register('sm_pets:manage:open', function(src, shopId)
    local shop = shops[tonumber(shopId) or 0]
    if not shop then return { ok = false, msg = 'Toko tidak dikenal.' } end
    if not isManager(src, shop) then return { ok = false, msg = 'Akses ditolak.' } end

    return shopData(shop)
end)

lib.callback.register('sm_pets:manage:restock', function(src, shopId, items)
    local shop = shops[tonumber(shopId) or 0]
    if not shop then return { ok = false, msg = 'Toko tidak dikenal.' } end
    if not isManager(src, shop) then return { ok = false, msg = 'Akses ditolak.' } end
    if type(items) ~= 'table' then return { ok = false, msg = 'Data tidak valid.' } end

    local maxQty = shopConfig.maxQty or 500

    for i = 1, #items do
        local line = items[i]
        local key = type(line) == 'table' and line.key
        local qty = type(line) == 'table' and math.floor(tonumber(line.qty) or 0) or 0

        if type(key) == 'string' and qty > 0 and qty <= maxQty then
            local entry = consumables[key] or wardrobe[key]
            local base = entry and tonumber(entry.price) or 0
            local wholesale = math.ceil(base * (shop.wholesale or 0.7))

            MySQL.insert.await([[
                INSERT INTO sm_pets_stock (shop_id, item_key, price, amount) VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)
            ]], { shop.id, key, wholesale, qty })
        end
    end

    local data = shopData(shop)
    data.msg = 'Stok ditambah.'

    return data
end)

lib.callback.register('sm_pets:manage:setPrice', function(src, shopId, key, price)
    local shop = shops[tonumber(shopId) or 0]
    if not shop then return { ok = false, msg = 'Toko tidak dikenal.' } end
    if not isManager(src, shop) then return { ok = false, msg = 'Akses ditolak.' } end

    price = math.floor(tonumber(price) or 0)
    if price < 1 or price > (shopConfig.maxPrice or 100000000) then
        return { ok = false, msg = 'Harga tidak valid.' }
    end

    MySQL.update.await('UPDATE sm_pets_stock SET price = ? WHERE shop_id = ? AND item_key = ?', { price, shop.id, key })

    return { ok = true, msg = 'Harga diperbarui.' }
end)

lib.callback.register('sm_pets:manage:remove', function(src, shopId, key, qty)
    local shop = shops[tonumber(shopId) or 0]
    if not shop then return { ok = false } end
    if not isManager(src, shop) then return { ok = false } end

    qty = math.floor(tonumber(qty) or 0)

    if qty <= 0 then
        MySQL.update.await('DELETE FROM sm_pets_stock WHERE shop_id = ? AND item_key = ?', { shop.id, key })
    else
        MySQL.update.await('UPDATE sm_pets_stock SET amount = GREATEST(0, amount - ?) WHERE shop_id = ? AND item_key = ?', {
            qty, shop.id, key
        })
    end

    local data = shopData(shop)
    data.ok = true

    return data
end)

lib.callback.register('sm_pets:creator:list', function(src)
    if not isAdmin(src) then return nil end

    local list = {}

    for id, shop in pairs(shops) do
        list[#list + 1] = {
            id = id,
            name = shop.name,
            job = shop.job,
            manageGrade = shop.manageGrade,
            vetGrade = shop.vetGrade,
            points = shop.points,
            blip = shop.blip
        }
    end

    return list
end)

lib.callback.register('sm_pets:creator:save', function(src, draft)
    if not isAdmin(src) then return { ok = false, msg = 'Akses ditolak.' } end
    if type(draft) ~= 'table' then return { ok = false, msg = 'Data tidak valid.' } end

    local name = tostring(draft.name or ''):sub(1, 64)
    local job = tostring(draft.job or ''):sub(1, 64)

    if name == '' or job == '' then return { ok = false, msg = 'Nama dan job wajib.' } end

    local points = draft.points or {}
    if not points.counter then return { ok = false, msg = 'Titik counter wajib diisi.' } end

    local tables = points.tables or {}
    if #tables > (playerShop.tablesPerShop or 6) then
        return { ok = false, msg = ('Maksimal %d meja.'):format(playerShop.tablesPerShop or 6) }
    end

    local payload = {
        name, job,
        tonumber(draft.manageGrade) or playerShop.defaultManageGrade or 2,
        tonumber(draft.vetGrade) or playerShop.defaultVetGrade or 1,
        tonumber(draft.wholesale) or shopConfig.wholesaleMultiplier or 0.7,
        json.encode(points),
        json.encode(draft.blip or playerShop.blip or {})
    }

    local id = tonumber(draft.id)

    if id and shops[id] then
        MySQL.update.await([[
            UPDATE sm_pets_shops SET name = ?, job = ?, manageGrade = ?, vetGrade = ?, wholesale = ?, points = ?, blip = ?
            WHERE id = ?
        ]], { payload[1], payload[2], payload[3], payload[4], payload[5], payload[6], payload[7], id })
    else
        id = MySQL.insert.await([[
            INSERT INTO sm_pets_shops (name, job, manageGrade, vetGrade, wholesale, points, blip)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], payload)
    end

    if not id then return { ok = false, msg = 'Gagal menyimpan.' } end

    shops[id] = {
        id = id, name = name, job = job,
        manageGrade = payload[3], vetGrade = payload[4], wholesale = payload[5],
        points = points, blip = draft.blip or playerShop.blip or {}
    }

    buildGlobalState()

    return { ok = true, id = id, msg = 'Toko disimpan.' }
end)

lib.callback.register('sm_pets:creator:delete', function(src, id)
    if not isAdmin(src) then return false end

    id = tonumber(id)
    if not id or not shops[id] then return false end

    shops[id] = nil

    MySQL.update.await('DELETE FROM sm_pets_shops WHERE id = ?', { id })
    MySQL.update.await('DELETE FROM sm_pets_stock WHERE shop_id = ?', { id })

    buildGlobalState()

    return true
end)

CreateThread(function()
    for stmt in string.gmatch(SCHEMA, '([^;]+)') do
        local s = stmt:gsub('^%s+', ''):gsub('%s+$', '')
        if s ~= '' then MySQL.query.await(s) end
    end

    local rows = MySQL.query.await('SELECT * FROM sm_pets_shops') or {}

    for i = 1, #rows do
        local row = rows[i]

        shops[row.id] = {
            id = row.id,
            name = row.name,
            job = row.job,
            manageGrade = tonumber(row.manageGrade) or 2,
            vetGrade = tonumber(row.vetGrade) or 1,
            wholesale = tonumber(row.wholesale) or 0.7,
            points = decode(row.points, {}),
            blip = decode(row.blip, {})
        }
    end

    buildGlobalState()

    print(('^2[sm_pets] %d toko pemain dimuat^7'):format(#rows))
end)
