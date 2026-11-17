if not interface.init(false) then
    return
end

local Config = localmodule 'config'
local Catalog = localmodule 'modules.catalog'

local Tables = Catalog.tables
local canUseTable = Catalog.canUseTable

local DefaultIcon = Config.defaultIcon
local TargetDistance = Config.targetDistance
local ZoneSize = Config.zoneSize

local IsPedArmed = IsPedArmed
local CreateObject = CreateObject
local SetEntityHeading = SetEntityHeading
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local FreezeEntityPosition = FreezeEntityPosition
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local pairs = pairs
local type = type
local sgsub = string.gsub
local GetCloudTimeAsInt = GetCloudTimeAsInt

local EMPTY = {}

local frameMounted = false
local frameReady = false
local uiOpen = false
local busy = false
local pendingPayload = nil
local currentTable = nil
local entities = {}

---@param message string
---@param kind? string
local function notify(message, kind)
    lib.notify({ description = message, type = kind or 'error' })
end

---@param metadata table?
---@param now integer
---@return boolean
local function isFresh(metadata, now)
    local durability = metadata and metadata.durability
    if type(durability) ~= 'number' then return true end
    if durability > 100 then return durability > now end
    return durability > 0
end

---@param name string
---@return string?
local function itemImage(name)
    local item = ox_items and ox_items[name]
    local image = item and item.client and item.client.image
    if type(image) ~= 'string' then return nil end
    return (sgsub(image, '^nui://', 'https://cfx-nui-'))
end

---@param name string
---@param now integer
---@return { label: string?, image: string?, count: integer }[] entries
---@return integer total
local function freshStock(name, now)
    local slots = ox_inventory:Search('slots', name) or EMPTY
    local sorted = {}

    for _, slot in pairs(slots) do
        if isFresh(slot.metadata, now) then sorted[#sorted + 1] = slot end
    end

    table.sort(sorted, function(a, b) return a.slot < b.slot end)

    local entries, total = {}, 0

    for i = 1, #sorted do
        local slot = sorted[i]
        local metadata = slot.metadata or EMPTY
        entries[i] = { label = metadata.label, image = metadata.imageurl, count = slot.count }
        total += slot.count
    end

    return entries, total
end

---@param menu table
local function attachInventory(menu)
    local recipes = menu.recipes
    local owned, stock, images = {}, {}, {}
    local now = GetCloudTimeAsInt()

    for i = 1, #recipes do
        local recipe = recipes[i]
        local outputs, materials = recipe.outputs, recipe.materials

        for j = 1, #outputs do
            local name = outputs[j].name
            images[name] = images[name] or itemImage(name)
        end

        for j = 1, #materials do
            local name = materials[j].name
            images[name] = images[name] or itemImage(name)

            if owned[name] == nil then
                if recipe.package then
                    stock[name], owned[name] = freshStock(name, now)
                else
                    owned[name] = ox_inventory:GetItemCount(name) or 0
                end
            end
        end
    end

    menu.owned = owned
    menu.stock = stock
    menu.images = images
end

local function closeUI()
    if not uiOpen then return end

    uiOpen = false
    pendingPayload = nil
    interface.focus(false, false)

    SetTimeout(50, function()
        if uiOpen or not frameMounted then return end

        frameMounted = false
        frameReady = false
        interface.hide()
    end)
end

---@param payload table
local function openUI(payload)
    pendingPayload = payload
    uiOpen = true

    if not frameMounted then
        frameReady = false
        frameMounted = true
        interface.show()
    elseif frameReady then
        interface.send({ action = 'open', data = payload })
        interface.focus(true, true)
        pendingPayload = nil
    end
end

---@param tableName string
local function openCrafting(tableName)
    if uiOpen or busy then return end

    if IsPedArmed(cache.ped, 7) then
        return notify('Simpan senjata dulu sebelum crafting.')
    end

    local menu = lib.callback.await('sm_crafting:getMenu', false, tableName)
    if not menu then return end

    attachInventory(menu)
    currentTable = tableName
    openUI(menu)
end

---@param tableName string
---@param recipeKey string
---@param amount integer
local function craft(tableName, recipeKey, amount)
    if busy then return end

    local job = lib.callback.await('sm_crafting:startCraft', false, tableName, recipeKey, amount)
    if not job then return end

    busy = true

    local finished = lib.progressCircle({
        duration = job.duration,
        label = ('Membuat %s'):format(job.label),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true, sprint = true },
        anim = { dict = job.anim.dict, clip = job.anim.anim, flag = 1 },
    })

    busy = false

    if finished then
        TriggerTokenEvent('sm_crafting:finishCraft')
    else
        TriggerServerEvent('sm_crafting:cancelCraft')
        notify('Crafting dibatalkan.')
    end
end

interface.callback('ready', function(_, cb)
    frameReady = true

    if pendingPayload then
        interface.send({ action = 'open', data = pendingPayload })
        interface.focus(true, true)
        pendingPayload = nil
    end

    cb('ok')
end)

interface.callback('exit', function(_, cb)
    cb('ok')
    closeUI()
end)

interface.callback('craft', function(data, cb)
    cb('ok')

    local tableName = currentTable
    closeUI()

    if not tableName or type(data) ~= 'table' or type(data.recipe) ~= 'string' then return end

    CreateThread(function()
        craft(tableName, data.recipe, data.amount)
    end)
end)

interface.callback('saveCustom', function(data, cb)
    if not currentTable or type(data) ~= 'table' then
        return cb({ success = false, message = 'Data tidak valid.' })
    end

    cb(lib.callback.await('sm_crafting:saveCustom', false, currentTable, data.recipe, data.label, data.image))
end)

interface.callback('resetCustom', function(data, cb)
    if not currentTable or type(data) ~= 'table' then
        return cb({ success = false, message = 'Data tidak valid.' })
    end

    cb(lib.callback.await('sm_crafting:resetCustom', false, currentTable, data.recipe))
end)

exports('openPackage', function(_, slot)
    if type(slot) ~= 'table' or type(slot.slot) ~= 'number' then return end
    TriggerTokenEvent('sm_crafting:openPackage', slot.slot)
end)

---@param name string
---@param bench CraftingTable
---@return table[]
local function targetOptions(name, bench)
    return {
        {
            name = 'sm_crafting:' .. name,
            label = bench.title,
            icon = bench.icon or DefaultIcon,
            distance = TargetDistance,
            canInteract = function()
                return not busy and canUseTable(bench, QBPlayerData.job)
            end,
            onSelect = function()
                openCrafting(name)
            end,
        },
    }
end

---@param name string
---@param bench CraftingTable
local function createBench(name, bench)
    local options = targetOptions(name, bench)
    local locations = bench.locations
    local spawns = bench.spawnTable

    if locations then
        for i = 1, #locations do
            ox_target:addBoxZone({ coords = locations[i], size = ZoneSize, options = options })
        end
    end

    if spawns then
        for i = 1, #spawns do
            local spawn = spawns[i]
            local coords = spawn.coords
            local loaded, model = pcall(lib.requestModel, spawn.prop)

            if loaded and model then
                local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)
                SetEntityHeading(entity, coords.w)

                if not spawn.skipPlaceObjectOnGroundProperly then
                    PlaceObjectOnGroundProperly(entity)
                end

                FreezeEntityPosition(entity, true)
                SetModelAsNoLongerNeeded(model)
                entities[#entities + 1] = entity
                ox_target:addLocalEntity(entity, options)
            end
        end
    end
end

CreateThread(function()
    for name, bench in pairs(Tables) do
        createBench(name, bench)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if uiOpen then
        SetNuiFocus(false, false)
    end

    for i = 1, #entities do
        local entity = entities[i]
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end)
