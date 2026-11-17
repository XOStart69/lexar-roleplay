local config = localmodule 'config.shared'
local ox_inventory = exports.ox_inventory
local spawnedNPCs = {}
local isProcessing = false

local function loadModel(model)
    local hash = GetHashKey(model)
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(100)
    end
    
    return hash
end

local function spawnNPC(npcData)
    local hash = loadModel(npcData.model)
    
    local ped = CreatePed(
        4, hash,
        npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w,
        false, true
    )
    
    SetEntityHeading(ped, npcData.coords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    if npcData.scenario then
        TaskStartScenarioInPlace(ped, npcData.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'exchange_items',
            label = 'Berbicara..',
            icon = 'fas fa-exchange-alt',
            onSelect = function()
                openExchangeMenu()
            end
        }
    })

    return ped
end

function openExchangeMenu()
    local options = {}

    for i, exchange in ipairs(config.exchanges) do
        local itemsList = {}
        for _, req in ipairs(exchange.requiredItems) do
            table.insert(itemsList, string.format('%dx %s', req.amount, req.label))
        end
        
        local description = exchange.description .. '\n\nMembutuhkan:\n' .. table.concat(itemsList, '\n')

        table.insert(options, {
            title = exchange.label,
            description = description,
            icon = 'box',
            onSelect = function()
                if not isProcessing then
                    TriggerTokenEvent('voucherspa:server:attemptExchange', i)
                end
            end
        })
    end

    lib.registerContext({
        id = 'exchange_menu',
        title = config.menuTitle,
        options = options
    })

    lib.showContext('exchange_menu')
end

CreateThread(function()
    for _, npcData in ipairs(config.npcs) do
        local ped = spawnNPC(npcData)
        table.insert(spawnedNPCs, ped)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, ped in ipairs(spawnedNPCs) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)

RegisterNetEvent('voucherspa:client:startProgress', function(exchangeId)
    local exchange = config.exchanges[exchangeId]
    if not exchange or isProcessing then return end

    isProcessing = true

    if lib.progressBar({
        duration = exchange.progressDuration,
        label = exchange.progressLabel,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    }) then
        TriggerTokenEvent('voucherspa:server:completeExchange', exchangeId)
    else
        lib.notify({
            title = 'Dibatalkan',
            description = config.messages.exchangeCancelled,
            type = 'error'
        })
    end

    isProcessing = false
end)