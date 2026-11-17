local Config = localmodule 'config.shared'
local QBCore = exports['qb-core']:GetCoreObject()
local ox_inv = exports.ox_inventory

local maxWeight = Config.Settings.defaultWeight
local upgradeLevel = 0
local npcEntity = nil

-- Helpers

local function FormatMoney(amount)
    local s = tostring(amount):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return '$' .. s
end

local function GetItemCount(itemName)
    return ox_inv:GetItemCount(itemName) or 0
end

local function SyncData()
    local data = lib.callback.await('sm_invupgrade:getData', false)
    if data then
        maxWeight = data.maxWeight
        upgradeLevel = data.upgradeLevel
    end
end


local function OpenUpgradeMenu()
    local sorted = {}
    for weight, cfg in pairs(Config.Upgrades) do
        sorted[#sorted + 1] = { weight = weight, cfg = cfg }
    end
    table.sort(sorted, function(a, b) return a.weight < b.weight end)

    local options = {}
    for _, entry in ipairs(sorted) do
        local weight, cfg = entry.weight, entry.cfg
        local lines = { cfg.description, '', ('Biaya: %s'):format(FormatMoney(cfg.cost.money)) }

        if #cfg.cost.items > 0 then
            lines[#lines + 1] = ''
            lines[#lines + 1] = 'Material yang dibutuhkan:'
            for _, req in pairs(cfg.cost.items) do
                local have = GetItemCount(req.item)
                lines[#lines + 1] = ('- %s (%d/%d)'):format(req.label or req.item, have, req.amount)
            end
        end

        local disabled = false
        lines[#lines + 1] = ''

        if maxWeight >= weight then
            lines[#lines + 1] = '✅ Upgrade ini sudah dimiliki'
            disabled = true
        elseif (cfg.requiredUpgrade or 0) > 0 and maxWeight < cfg.requiredUpgrade then
            lines[#lines + 1] = ('❌ %s'):format(Config.Messages.requiresPreviousUpgrade:format(cfg.requiredUpgrade / 1000))
            disabled = true
        else
            local affordable = true
            local playerMoney = GetItemCount('money')
            if playerMoney < cfg.cost.money then affordable = false end
            for _, req in pairs(cfg.cost.items) do
                if GetItemCount(req.item) < req.amount then affordable = false end
            end

            if not affordable then
                lines[#lines + 1] = '❌ Biaya/material tidak mencukupi'
                disabled = true
            else
                lines[#lines + 1] = '✅ Siap untuk upgrade'
            end
        end

        options[#options + 1] = {
            title = cfg.label,
            description = table.concat(lines, '\n'),
            disabled = disabled,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Konfirmasi Upgrade',
                    content = ('Upgrade tas ke %dkg dengan biaya %s?\nUpgrade ini tidak bisa dibatalkan.'):format(weight / 1000, FormatMoney(cfg.cost.money)),
                    centered = true,
                    cancel = true,
                    labels = { confirm = 'Ya, Upgrade', cancel = 'Batal' },
                })
                if confirm ~= 'confirm' then return end

                local ok, result = lib.callback.await('sm_invupgrade:upgradeInventory', false, weight)
                if ok then
                    maxWeight = result.maxWeight
                    upgradeLevel = result.upgradeLevel
                    lib.notify({ description = Config.Messages.upgradeSuccess:format(maxWeight / 1000), type = 'success' })
                else
                    lib.notify({ description = result, type = 'error' })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'invupgrade_upgrade',
        title = Config.Messages.menuTitle,
        menu = 'invupgrade_main',
        options = options,
    })
    lib.showContext('invupgrade_upgrade')
end


local function OpenCraftingMenu()
    local options = {}

    for key, recipe in pairs(Config.CraftingRecipes) do
        local lines = { recipe.description, '', 'Bahan yang dibutuhkan:' }
        local canCraft = true

        for _, ing in pairs(recipe.ingredients) do
            local have = GetItemCount(ing.item)
            lines[#lines + 1] = ('- %s (%d/%d)'):format(ing.label or ing.item, have, ing.amount)
            if have < ing.amount then canCraft = false end
        end

        lines[#lines + 1] = ''
        lines[#lines + 1] = ('Hasil: %s x%d'):format(recipe.output.item, recipe.output.amount)
        lines[#lines + 1] = ''
        lines[#lines + 1] = canCraft and '✅ Siap untuk dibuat' or '❌ Bahan tidak cukup'

        options[#options + 1] = {
            title = recipe.label,
            description = table.concat(lines, '\n'),
            disabled = not canCraft,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Konfirmasi Crafting',
                    content = ('Apakah kamu yakin ingin membuat %s?'):format(recipe.label),
                    centered = true,
                    cancel = true,
                    labels = { confirm = 'Ya, Buat', cancel = 'Batal' },
                })
                if confirm ~= 'confirm' then return end

                local ok, msg = lib.callback.await('sm_invupgrade:craftItem', false, key)
                if ok then
                    lib.notify({ description = Config.Messages.craftSuccess:format(msg), type = 'success' })
                    Wait(300)
                    OpenCraftingMenu()
                else
                    lib.notify({ description = msg, type = 'error' })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'invupgrade_craft',
        title = Config.Messages.craftingMenuTitle,
        menu = 'invupgrade_main',
        options = options,
    })
    lib.showContext('invupgrade_craft')
end

local function OpenMainMenu()
    local status = maxWeight > Config.Settings.defaultWeight and 'Upgraded' or 'Standard'

    lib.registerContext({
        id = 'invupgrade_main',
        title = Config.NPC.name,
        options = {
            {
                title = Config.Messages.checkCapacityTitle,
                description = ('Kapasitas: %dkg | Level: %d | Status: %s'):format(maxWeight / 1000, upgradeLevel, status),
                onSelect = function()
                    lib.notify({ description = Config.Messages.currentCapacity:format(maxWeight / 1000), type = 'inform' })
                end,
            },
            {
                title = Config.Messages.craftingMenuTitle,
                description = Config.Messages.craftingMenuDesc,
                icon = 'box',
                onSelect = OpenCraftingMenu,
            },
            {
                title = Config.Messages.menuTitle,
                description = 'Upgrade kapasitas tas kamu',
                icon = 'arrow-up',
                onSelect = OpenUpgradeMenu,
            },
        },
    })
    lib.showContext('invupgrade_main')
end

-- NPC spawn

CreateThread(function()
    local model = Config.NPC.model
    lib.requestModel(model)

    local c = Config.NPC.coords
    npcEntity = CreatePed(4, model, c.x, c.y, c.z, c.w, false, true)
    SetEntityInvincible(npcEntity, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    FreezeEntityPosition(npcEntity, true)

    if Config.Settings.enableNPCAnimation and Config.NPC.scenario then
        TaskStartScenarioInPlace(npcEntity, Config.NPC.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(npcEntity, {
        {
            name = 'sm_invupgrade',
            icon = Config.Settings.targetIcon,
            label = Config.Settings.targetLabel,
            distance = Config.Settings.targetDistance,
            onSelect = function()
                SyncData()
                OpenMainMenu()
            end,
        },
    })
end)

-- Menus

-- Events

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(3000)
    SyncData()
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if QBCore.Functions.GetPlayerData().citizenid then
        SyncData()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if npcEntity and DoesEntityExist(npcEntity) then
        DeleteEntity(npcEntity)
    end
end)

-- Exports

exports('GetCurrentMaxWeight', function() return maxWeight end)
exports('GetCurrentUpgradeLevel', function() return upgradeLevel end)
exports('OpenMainMenu', OpenMainMenu)
exports('OpenUpgradeMenu', OpenUpgradeMenu)
exports('OpenCraftingMenu', OpenCraftingMenu)

print('[sm_invupgrade] Client loaded')