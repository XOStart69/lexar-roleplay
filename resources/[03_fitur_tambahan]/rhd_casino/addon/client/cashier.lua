local cacheEntities = {}
local cashier = require 'addon.config.cashier'

local curentCashier

local ctx_cashierMenu = {
    id = 'ctx_cashierMenu',
    title = 'Kasir',
    onClose = function ()
        curentCashier = nil
    end,
    options = {
        {
            title = 'Tukar chip',
            icon = 'fa-solid fa-coins',
            description = 'Tukar chip untuk mendapatkan uang',
            onSelect = function ()
                SendNUIMessage({
                    action = 'showExchangeChipModal',
                    data = {
                        totalChip = ox_inventory:GetItemCount(shared.chipItemName) or 0
                    }
                })
                SetNuiFocus(true, true)
            end
        },
        {
            title = 'Beli VIP',
            icon = 'fa-solid fa-crown',
            description = 'Beli VIP untuk mendapatkan keuntungan lebih',
            onSelect = function ()
                SendNUIMessage({
                    action = 'showBuyVipModal',
                    data = {
                        plans = cashier.vip.plans,
                        activeUntil = lib.callback.await('rhd_casino_cashier:getVipStatus', false),
                    }
                })
                SetNuiFocus(true, true)
            end
        }
    }
}

CreateThread(function (threadId)
    lib.registerContext(ctx_cashierMenu)
end)

local function loadCashier()
    for i=1, #cashier.locations do
        local location = cashier.locations[i]
        lib.requestModel(location.model, 1500)
        cacheEntities.cashier = CreatePed(
            4, joaat(location.model), location.coords.x, location.coords.y, location.coords.z -1, location.coords.w, false, false
        )
        
        FreezeEntityPosition(cacheEntities.cashier, true)
        SetEntityCanBeDamaged(cacheEntities.cashier, false)
        SetPedAsEnemy(cacheEntities.cashier, false)
        SetBlockingOfNonTemporaryEvents(cacheEntities.cashier, true)
        SetPedResetFlag(cacheEntities.cashier, 249, true)
        SetPedConfigFlag(cacheEntities.cashier, 185, true)
        SetPedConfigFlag(cacheEntities.cashier, 108, true)
        Citizen.InvokeNative(0x352E2B5CF420BF3B, cacheEntities.cashier, 1)
        SetPedCanEvasiveDive(cacheEntities.cashier, false)
        Citizen.InvokeNative(0x2F3C3D9F50681DE4, cacheEntities.cashier, 1)
        SetPedCanRagdollFromPlayerImpact(cacheEntities.cashier, false)
        SetPedConfigFlag(cacheEntities.cashier, 208, true)

        local targetOffset = GetObjectOffsetFromCoords(
            location.coords.x, location.coords.y, location.coords.z, location.coords.w, 0.0, 0.2, 0.5
        )

        target:addSphereZone({
            coords = targetOffset.xyz,
            radius = 1.0,
            options = {
                {
                    label = 'Bicara kepada kasir',
                    icon = 'fa-solid fa-cash-register',
                    distance = 1.5,
                    onSelect = function ()
                        curentCashier = i
                        lib.showContext('ctx_cashierMenu')
                    end
                }
            }
        })
    end
end

local function unloadCashier()
    for _, v in pairs(cacheEntities) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
end

-- RegisterNUICallback('rhd_casino_cashier:buyChip', function (data, cb)
--     cb('ok')

--     SetNuiFocus(false, false)
--     if not (curentCashier and data.amount) then
--         return
--     end

--     TriggerServerEvent('rhd_casino_cashier:buyCheck', { data.amount, curentCashier })
-- end)

RegisterNUICallback('rhd_casino_cashier:exchangeChip', function (data, cb)
    cb('ok')

    SetNuiFocus(false, false)
    if not (curentCashier and data.amount) then
        return
    end

    TriggerServerEvent('rhd_casino_cashier:exchangeCheck', { data.amount, curentCashier })
end)

RegisterNUICallback('rhd_casino_cashier:buyVip', function (data, cb)
    cb('ok')

    SetNuiFocus(false, false)
    if not (curentCashier and data.plan) then
        return
    end

    TriggerServerEvent('rhd_casino_cashier:buyVipCheck', { data.plan, curentCashier })
end)

useAreaHooks(function (entered)
    if entered then
        print('Entered cashier area')
        loadCashier()
    else
        unloadCashier()
    end
end)

AddEventHandler('onResourceStop', function (resourceName)
    if resourceName == GetCurrentResourceName() then
        unloadCashier()
    end
end)