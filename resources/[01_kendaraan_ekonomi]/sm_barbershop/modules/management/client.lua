local config = Config
local Nui = require 'modules.nui'
local Sync = require 'modules.sync.client'

---@type string?
local currentShop

---@type integer?
local syncBaseline

---@type table<string, integer>
local syncApplied = {}

---@type BarberManagementSync[]
local pendingSync = {}

---@param baseline integer?
local function resetSync(baseline)
    syncBaseline = baseline
    syncApplied = {}
    pendingSync = {}
end

---@param payload BarberManagementSync
---@param baseline integer
---@return BarberManagementSync?
local function freshFields(payload, baseline)
    local revision = payload.revision
    local fresh

    for key, value in pairs(payload) do
        if key ~= 'shopId' and key ~= 'revision' and revision > (syncApplied[key] or baseline) then
            syncApplied[key] = revision
            fresh = fresh or { shopId = payload.shopId }
            fresh[key] = value
        end
    end

    return fresh
end

local function myRole(shopId)
    local shops = LocalPlayer.state.barberShops

    return type(shops) == 'table' and shops[shopId] or nil
end

local function notifyResult(result)
    if result and result.message then
        lib.notify({ type = result.success and 'success' or 'error', description = result.message })
    end
end

local function openTablet(shopId)
    currentShop = shopId
    resetSync(nil)
    Nui.open('management', 'barber:management:open', { shopId = shopId })
end

local function closeTablet()
    currentShop = nil
    Nui.close('management', 'barber:management:close')
end

local function serverAwait(name, ...)
    if not currentShop then return false end

    return lib.callback.await(('sm_barbershop:management:%s'):format(name), false, currentShop, ...)
end

local function toggleDuty(shopId)
    local result = lib.callback.await('sm_barbershop:management:toggleDuty', false, shopId)

    if not result.success then
        return notifyResult(result)
    end

    lib.notify({
        type = 'success',
        description = result.onDuty and 'Shift dimulai.' or 'Shift diakhiri.',
    })
end

local function purchase(shop)
    local state = Sync.shop(shop.id)

    if not state or state.owned or not state.purchesable then return end

    local answer = lib.alertDialog({
        header = state.label,
        content = ('Beli barbershop ini seharga $%s?'):format(lib.math.groupdigits(state.purchasePrice)),
        centered = true,
        cancel = true,
        labels = { cancel = 'Batal', confirm = 'Beli' },
    })

    if answer ~= 'confirm' then return end

    notifyResult(lib.callback.await('sm_barbershop:shop:purchase', false, shop.id))
end

local function nearbyServerIds()
    local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 6.0, false)
    local ids = {}

    for i = 1, #players do
        ids[#ids + 1] = GetPlayerServerId(players[i].id)
    end

    return ids
end

---@type table<string, { handle: number, label: string }>
local blips = {}

---@param blip { handle: number, label: string }
---@param label string
local function nameBlip(blip, label)
    blip.label = label
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip.handle)
end

AddTextEntry(('BLIP_CAT_%d'):format(config.blip.category), config.blip.categoryLabel)

for i = 1, #config.shops do
    local shop = config.shops[i]
    local management = shop.coords.management

    local handle = AddBlipForCoord(management.x, management.y, management.z)

    SetBlipSprite(handle, config.blip.sprite)
    SetBlipColour(handle, config.blip.color)
    SetBlipScale(handle, config.blip.scale)
    SetBlipDisplay(handle, 4)
    SetBlipAsShortRange(handle, true)
    SetBlipCategory(handle, config.blip.category)

    blips[shop.id] = { handle = handle, label = shop.label }
    nameBlip(blips[shop.id], shop.label)

    exports.ox_target:addSphereZone({
        coords = management,
        radius = config.counterRadius,
        options = {
            {
                name = ('sm_barbershop_buy_%s'):format(shop.id),
                label = 'Beli barbershop',
                icon = 'fas fa-store',
                distance = 2.0,
                canInteract = function()
                    local state = Sync.shop(shop.id)

                    return state ~= nil and state.purchesable and not state.owned
                end,
                onSelect = function()
                    purchase(shop)
                end,
            },
            {
                name = ('sm_barbershop_manage_%s'):format(shop.id),
                label = 'Manajemen barbershop',
                icon = 'fas fa-tablet-screen-button',
                distance = 2.0,
                canInteract = function()
                    return myRole(shop.id) ~= nil
                end,
                onSelect = function()
                    openTablet(shop.id)
                end,
            },
            {
                name = ('sm_barbershop_duty_on_%s'):format(shop.id),
                label = 'Mulai shift',
                icon = 'fas fa-clock',
                distance = 2.0,
                canInteract = function()
                    return myRole(shop.id) ~= nil and LocalPlayer.state.barberDuty ~= shop.id
                end,
                onSelect = function()
                    toggleDuty(shop.id)
                end,
            },
            {
                name = ('sm_barbershop_duty_off_%s'):format(shop.id),
                label = 'Akhiri shift',
                icon = 'fas fa-clock',
                distance = 2.0,
                canInteract = function()
                    return LocalPlayer.state.barberDuty == shop.id
                end,
                onSelect = function()
                    toggleDuty(shop.id)
                end,
            },
        },
    })
end

Sync.onShop(function(shopId, state)
    local blip = blips[shopId]

    if blip and state.label ~= blip.label then
        nameBlip(blip, state.label)
    end
end)

Nui.callback('barber:management:close', function()
    closeTablet()

    return true
end)

Nui.callback('barber:management:bootstrap', function()
    local result = serverAwait('bootstrap')

    if type(result) ~= 'table' or type(result.revision) ~= 'number' then return result end

    local pending = pendingSync

    resetSync(result.revision)

    for i = 1, #pending do
        local fresh = freshFields(pending[i], result.revision)

        if fresh then
            fresh.shopId = nil

            for key, value in pairs(fresh) do
                result[key] = value
            end
        end
    end

    return result
end)

Nui.callback('barber:management:getLogs', function(payload)
    return serverAwait('getLogs', payload.page, payload.pageSize, payload.search)
end)

Nui.callback('barber:management:getTransactions', function(payload)
    return serverAwait('getTransactions', payload.page, payload.pageSize, payload.search)
end)

Nui.callback('barber:management:getNearbyPlayers', function()
    return serverAwait('resolvePlayers', nearbyServerIds())
end)

Nui.callback('barber:management:toggleDuty', function()
    return serverAwait('toggleDuty')
end)

Nui.callback('barber:management:hire', function(payload)
    return serverAwait('hire', tonumber(payload.playerId), payload.role)
end)

Nui.callback('barber:management:setRole', function(payload)
    return serverAwait('setRole', payload.citizenId, payload.role)
end)

Nui.callback('barber:management:fire', function(payload)
    return serverAwait('fire', payload.citizenId)
end)

Nui.callback('barber:management:setPrices', function(payload)
    return serverAwait('setPrices', {
        itemPrices = payload.itemPrices,
        commissionRate = payload.commissionRate,
        selfServiceRate = payload.selfServiceRate,
    })
end)

Nui.callback('barber:management:setName', function(payload)
    return serverAwait('setName', payload.name)
end)

Nui.callback('barber:management:saveRole', function(payload)
    return serverAwait('saveRole', payload.key, payload.label, payload.permissions)
end)

Nui.callback('barber:management:deleteRole', function(payload)
    return serverAwait('deleteRole', payload.key)
end)

Nui.callback('barber:management:buySupply', function(payload)
    return serverAwait('buySupply', payload.item, payload.quantity)
end)

Nui.callback('barber:management:deposit', function(payload)
    return serverAwait('deposit', payload.amount)
end)

Nui.callback('barber:management:withdraw', function(payload)
    return serverAwait('withdraw', payload.amount)
end)

RegisterNetEvent('sm_barbershop:management:sync', function(payload)
    if source == '' or type(payload) ~= 'table' or type(payload.revision) ~= 'number' then return end
    if not currentShop or payload.shopId ~= currentShop then return end

    local baseline = syncBaseline

    if not baseline then
        pendingSync[#pendingSync + 1] = payload

        return
    end

    local fresh = freshFields(payload, baseline)

    if fresh then
        SendNUIMessage({ action = 'barber:management:sync', data = fresh })
    end
end)

RegisterNetEvent('sm_barbershop:management:reload', function(shopId)
    if source == '' or not currentShop or shopId ~= currentShop then return end

    resetSync(nil)
    SendNUIMessage({ action = 'barber:management:reload' })
end)

AddStateBagChangeHandler('barberShops', ('player:%s'):format(cache.serverId), function(_, _, value)
    if not currentShop then return end

    if type(value) ~= 'table' or not value[currentShop] then
        closeTablet()
    end
end)
