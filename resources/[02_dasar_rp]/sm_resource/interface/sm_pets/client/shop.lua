local Config = SmPets.Config
local Catalog = SmPets.Catalog
local shopConfig = Config.Shop
local petTypes = SmPets.petTypes
local uiActions = SmPets.uiActions

local AddBlipForCoord = AddBlipForCoord
local SetBlipSprite = SetBlipSprite
local SetBlipColour = SetBlipColour
local SetBlipScale = SetBlipScale
local SetBlipAsShortRange = SetBlipAsShortRange
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandSetBlipName = EndTextCommandSetBlipName
local RemoveBlip = RemoveBlip
local DoesBlipExist = DoesBlipExist
local CreatePed = CreatePed
local DeletePed = DeletePed
local DoesEntityExist = DoesEntityExist
local SetEntityInvincible = SetEntityInvincible
local FreezeEntityPosition = FreezeEntityPosition
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local IsControlJustPressed = IsControlJustPressed
local Wait = Wait
local CreateThread = CreateThread
local type = type
local pairs = pairs
local tonumber = tonumber
local mceil = math.ceil
local sformat = string.format

local CARE_CATEGORY = { food = 'food', treat = 'food', water = 'water', medkit = 'health' }
local APPAREL = { collar = true, bandana = true, clothes = true, shoes = true, head = true, patch = true, glasses = true, mask = true }

local npcPeds = {}
local npcBlips = {}
local shopBlips = {}
local shopPoints = {}

---@param coords vector3
---@param blip table
---@param label string
---@return integer
local function makeBlip(coords, blip, label)
    local handle = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(handle, blip.sprite or 442)
    SetBlipColour(handle, blip.color or 5)
    SetBlipScale(handle, blip.scale or 0.7)
    SetBlipAsShortRange(handle, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(handle)
    return handle
end

---@return table[]
local function fullCatalog()
    local list, n = {}, 0
    for i = 1, #Config.Pets do
        local entry = Config.Pets[i]
        n = n + 1
        list[n] = {
            key = 'pet:' .. entry.id, kind = 'pet', group = 'pets', cat = 'pets',
            label = entry.label, price = entry.price, image = SmPets.imageFor(entry.image),
            species = entry.species, k9 = entry.k9 == true, clothing = entry.clothing == true, vanilla = entry.vanilla == true,
            description = entry.description or (entry.vanilla and 'Basic Animal - Cant Dressed Up' or 'Addon Animal - Dressed Up'),
            hidden = entry.hidden == true,
        }
    end
    for key, item in pairs(Catalog.consumables) do
        n = n + 1
        list[n] = {
            key = key, kind = 'consumable', group = 'care', cat = CARE_CATEGORY[item.kind] or 'food',
            label = item.label, price = item.price, image = SmPets.imageFor(key, 'consumable'),
            description = item.description, amount = item.amount, itemKind = item.kind,
        }
    end
    for key, item in pairs(Catalog.wardrobe) do
        local models
        if item.kind == 'clothing' then
            models = {}
            for model, fit in pairs(SmPets.Fits) do
                if fit[key] then models[#models + 1] = model end
            end
        end
        n = n + 1
        list[n] = {
            key = key, kind = 'wardrobe', group = APPAREL[item.cat] and 'apparel' or 'accessories', cat = item.cat,
            label = item.label, price = item.price, image = SmPets.imageFor(key),
            species = item.species, k9 = item.k9 == true, clothingOnly = item.kind == 'clothing', itemKind = item.kind, models = models,
        }
    end
    return list
end

local catalogCache = fullCatalog()

---@param pets table[]
---@return table[]
local function decoratePets(pets)
    for i = 1, #pets do
        local entry = pets[i]
        local petType = petTypes[entry.type]
        entry.typeLabel = petType and petType.label or entry.type
        entry.species = petType and petType.species or 'bigdog'
        entry.clothing = petType and petType.clothing == true
        entry.model = petType and petType.model or ''
        entry.image = SmPets.imageFor(petType and petType.image or 'placeholder')
    end
    return pets
end

---@param data table
---@return table
local function shopPayload(data)
    local items, n = {}, 0
    for i = 1, #catalogCache do
        local entry = catalogCache[i]
        local allowed
        if entry.kind == 'pet' then
            allowed = (entry.k9 or not data.k9) and (not entry.hidden or data.showHidden == true)
            if allowed and entry.k9 and not data.k9 then
                local copy = {}
                for k, v in pairs(entry) do copy[k] = v end
                copy.k9 = false
                entry = copy
            end
        else
            allowed = not entry.k9 or data.k9
        end
        if data.stock then
            local stock = data.stock[entry.key]
            if stock and allowed then
                n = n + 1
                local copy = {}
                for k, v in pairs(entry) do copy[k] = v end
                copy.price = stock.price
                copy.stock = stock.amount
                items[n] = copy
            end
        elseif allowed and (entry.kind == 'pet' or data.sellItems) then
            n = n + 1
            items[n] = entry
        end
    end
    return {
        ref = data.ref,
        name = data.name,
        npc = data.npc,
        money = data.money,
        k9 = data.k9,
        maxOwned = data.maxOwned,
        nameLength = Config.NameLength,
        pets = decoratePets(data.pets),
        items = items,
    }
end

---@param ref string
function SmPets.openShop(ref)
    local data = lib.callback.await('sm_pets:shop:open', false, ref)
    if not data or not data.ok then return SmPets.notify(data and data.msg or 'Toko tidak bisa dibuka.', 'error') end
    SmPets.openUI('shop', shopPayload(data))
end

---@param ref string
---@return table|nil
local function refreshShop(ref)
    local data = lib.callback.await('sm_pets:shop:open', false, ref)
    if not data or not data.ok then return nil end
    local payload = shopPayload(data)
    payload.view = 'shop'
    return payload
end

uiActions.buyPet = function(data)
    local result = lib.callback.await('sm_pets:shop:buyPet', false, data.ref, data.typeId, data.name)
    if not result then return { ok = false } end
    SmPets.notify(result.msg, result.ok and 'success' or 'error')
    if not result.ok then return result end
    local payload = refreshShop(data.ref) or {}
    payload.ok = true
    return payload
end

uiActions.buyItems = function(data)
    local result = lib.callback.await('sm_pets:shop:buyItems', false, data.ref, data.cart, tonumber(data.petId))
    if not result then return { ok = false } end
    SmPets.notify(result.msg, result.ok and 'success' or 'error')
    if not result.ok then return result end
    local payload = refreshShop(data.ref) or {}
    payload.ok = true
    return payload
end

---@param data table
---@return table
local function managePayload(data)
    local catalog, n = {}, 0
    local labels = {}
    for i = 1, #catalogCache do
        local entry = catalogCache[i]
        labels[entry.key] = entry
        if (entry.kind == 'pet' and not entry.hidden) or (entry.kind ~= 'pet' and not entry.k9) then
            n = n + 1
            catalog[n] = {
                key = entry.key, label = entry.label, image = entry.image, group = entry.group, cat = entry.cat,
                price = entry.price, wholesale = mceil(entry.price * data.wholesale),
            }
        end
    end
    for i = 1, #data.stock do
        local row = data.stock[i]
        local entry = labels[row.key]
        row.label = entry and entry.label or row.key
        row.image = entry and entry.image or SmPets.imageFor('placeholder')
        row.group = entry and entry.group or 'care'
        row.basePrice = entry and entry.price or 0
    end
    for i = 1, #data.sales do
        local sale = data.sales[i]
        for j = 1, #sale.items do
            local line = sale.items[j]
            local entry = labels[line.key]
            line.label = entry and entry.label or line.key
        end
    end
    data.catalog = catalog
    return data
end

---@param shopId integer
function SmPets.openManage(shopId)
    local data = lib.callback.await('sm_pets:manage:open', false, shopId)
    if not data or not data.ok then return SmPets.notify(data and data.msg or 'Akses ditolak.', 'error') end
    SmPets.openUI('manage', managePayload(data))
end

uiActions.restock = function(data)
    local result = lib.callback.await('sm_pets:manage:restock', false, data.shopId, data.items)
    if not result then return { ok = false } end
    SmPets.notify(result.msg, result.ok and 'success' or 'error')
    if not result.ok then return result end
    local payload = managePayload(result)
    payload.view = 'manage'
    return payload
end

uiActions.setPrice = function(data)
    local result = lib.callback.await('sm_pets:manage:setPrice', false, data.shopId, data.key, data.price)
    if result and result.msg then SmPets.notify(result.msg, result.ok and 'success' or 'error') end
    return result or { ok = false }
end

uiActions.removeStock = function(data)
    return lib.callback.await('sm_pets:manage:remove', false, data.shopId, data.key, data.qty) or { ok = false }
end

uiActions.manageRefresh = function(data)
    local result = lib.callback.await('sm_pets:manage:open', false, data.shopId)
    if not result or not result.ok then return { ok = false } end
    local payload = managePayload(result)
    payload.view = 'manage'
    return payload
end

---@return table[]
local function jobList()
    local list, n = {}, 0
    for name, job in pairs(qb_jobs or {}) do
        n = n + 1
        local grades, g = {}, 0
        for level, grade in pairs(job.grades or {}) do
            g = g + 1
            grades[g] = { level = tonumber(level) or 0, name = grade.name }
        end
        table.sort(grades, function(a, b) return a.level < b.level end)
        list[n] = { name = name, label = job.label or name, grades = grades }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

---@param draft? table
function SmPets.openCreator(draft)
    local shops = lib.callback.await('sm_pets:creator:list', false)
    if not shops then return end
    SmPets.openUI('creator', {
        shops = shops,
        jobs = jobList(),
        draft = draft,
        defaults = {
            manageGrade = Config.PlayerShop.defaultManageGrade,
            vetGrade = Config.PlayerShop.defaultVetGrade,
            blip = Config.PlayerShop.blip,
            maxTables = Config.PlayerShop.tablesPerShop,
        },
    })
end

local capturing = false

uiActions.creatorCapture = function(data)
    if capturing or type(data.draft) ~= 'table' then return { ok = false } end
    local draft, target = data.draft, data.target
    capturing = true
    SmPets.closeUI()
    infoUI.show({
        id = 'sm_pets:capture',
        title = 'Ambil Titik Toko',
        icon = 'fas fa-location-dot',
        description = 'Berdiri di posisi yang diinginkan lalu tekan E. Tekan Backspace untuk batal.',
    })
    CreateThread(function()
        local result
        while capturing do
            if IsControlJustPressed(0, 38) then
                local ped = cache.ped
                local coords = GetEntityCoords(ped)
                result = { x = coords.x, y = coords.y, z = coords.z - 1.0, w = GetEntityHeading(ped) }
                break
            elseif IsControlJustPressed(0, 177) then
                break
            end
            Wait(0)
        end
        capturing = false
        infoUI.remove('sm_pets:capture')
        if result then
            draft.points = draft.points or {}
            draft.points.tables = draft.points.tables or {}
            local tableIndex = tonumber(type(target) == 'string' and target:match('^table:(%d+)$'))
            if target == 'table' then
                draft.points.tables[#draft.points.tables + 1] = result
            elseif tableIndex and tableIndex <= #draft.points.tables then
                draft.points.tables[tableIndex] = result
            elseif target == 'counter' or target == 'manage' then
                draft.points[target] = result
            end
        end
        SmPets.openCreator(draft)
    end)
    return { ok = true, closed = true }
end

uiActions.creatorSave = function(data)
    local result = lib.callback.await('sm_pets:creator:save', false, data.shop)
    if result and result.msg then SmPets.notify(result.msg, result.ok and 'success' or 'error') end
    if not result or not result.ok then return result or { ok = false } end
    SmPets.notify('Toko disimpan.', 'success')
    return { ok = true, id = result.id, shops = lib.callback.await('sm_pets:creator:list', false) or {} }
end

uiActions.creatorDelete = function(data)
    local ok = lib.callback.await('sm_pets:creator:delete', false, data.id)
    return { ok = ok == true, shops = lib.callback.await('sm_pets:creator:list', false) or {} }
end

RegisterNetEvent('sm_pets:client:openCreator', function()
    SmPets.openCreator()
end)

local function spawnNpc(index)
    local entry = shopConfig.npc[index]
    local hash = SmPets.loadModel(entry.model)
    if not hash then return end
    local c = entry.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w, false, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(hash)
    npcPeds[index] = ped
end

for i = 1, #shopConfig.npc do
    local entry = shopConfig.npc[i]
    local coords = entry.coords.xyz
    if entry.blip then npcBlips[i] = makeBlip(coords, entry.blip, entry.label) end
    lib.points.new({
        coords = coords,
        distance = 60.0,
        onEnter = function() spawnNpc(i) end,
        onExit = function()
            local ped = npcPeds[i]
            if ped and DoesEntityExist(ped) then DeletePed(ped) end
            npcPeds[i] = nil
        end,
    })
end

SmPets.onInteractReady(function()
    for i = 1, #shopConfig.npc do
        exports.rhd_interact:addCoords({
            id = ('sm_pets:npc:%d'):format(i),
            coords = shopConfig.npc[i].coords.xyz + vec3(0.0, 0.0, 0.2),
            options = {
                {
                    name = 'sm_pets:npc:open',
                    label = 'Buka Pet Shop',
                    icon = 'fas fa-paw',
                    distance = shopConfig.openDistance,
                    onSelect = function() SmPets.openShop(('npc:%d'):format(i)) end,
                },
            },
        })
    end
end)

---@param shop table
---@return boolean
local function isManager(shop)
    local job = QBPlayerData.job
    return job ~= nil and job.name == shop.job and (job.grade and job.grade.level or 0) >= shop.manageGrade
end

local function clearShopPoints()
    for i = 1, #shopBlips do
        if DoesBlipExist(shopBlips[i]) then RemoveBlip(shopBlips[i]) end
        shopBlips[i] = nil
    end
    local ready = SmPets.interactReady()
    for i = 1, #shopPoints do
        if ready then exports.rhd_interact:removeCoords(shopPoints[i]) end
        shopPoints[i] = nil
    end
end

---@param shops table[]|nil
local function buildShopPoints(shops)
    clearShopPoints()
    if not shops or not SmPets.interactReady() then return end
    for i = 1, #shops do
        local shop = shops[i]
        local counter, manage = shop.points.counter, shop.points.manage
        if counter then
            local coords = vec3(counter.x, counter.y, counter.z)
            if shop.blip and shop.blip.enabled ~= false then
                shopBlips[#shopBlips + 1] = makeBlip(coords, shop.blip, shop.name)
            end
            local id = sformat('sm_pets:shop:%d:counter', shop.id)
            exports.rhd_interact:addCoords({
                id = id,
                coords = coords + vec3(0.0, 0.0, 1.0),
                options = {
                    {
                        name = 'sm_pets:shop:open',
                        label = ('Belanja di %s'):format(shop.name),
                        icon = 'fas fa-store',
                        distance = shopConfig.openDistance,
                        onSelect = function() SmPets.openShop(('shop:%d'):format(shop.id)) end,
                    },
                },
            })
            shopPoints[#shopPoints + 1] = id
        end
        if manage then
            local id = sformat('sm_pets:shop:%d:manage', shop.id)
            exports.rhd_interact:addCoords({
                id = id,
                coords = vec3(manage.x, manage.y, manage.z + 1.0),
                options = {
                    {
                        name = 'sm_pets:shop:manage',
                        label = 'Manajemen Toko',
                        icon = 'fas fa-clipboard-list',
                        distance = shopConfig.openDistance,
                        canInteract = function() return isManager(shop) end,
                        onSelect = function() SmPets.openManage(shop.id) end,
                    },
                },
            })
            shopPoints[#shopPoints + 1] = id
        end
    end
end

AddStateBagChangeHandler('smPetShops', 'global', function(_, _, value)
    buildShopPoints(value)
    TriggerEvent('sm_pets:client:shopsUpdated', value)
end)

SmPets.onInteractReady(function()
    buildShopPoints(GlobalState.smPetShops)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    for _, ped in pairs(npcPeds) do
        if DoesEntityExist(ped) then DeletePed(ped) end
    end
    for _, blip in pairs(npcBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    clearShopPoints()
end)
