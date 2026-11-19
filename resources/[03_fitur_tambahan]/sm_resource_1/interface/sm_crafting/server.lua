--[[
    sm_crafting :: server
    Menu dari data/, konsumsi & hasil lewat modules/transaction.lua.
    Jarak, job/grade, waktu, dan kuota semua dicek di sini.
]]

local config = localmodule 'config'
local transaction = localmodule 'modules.transaction'

local DATASET = {}
local CUSTOM = 'sm_crafting_custom'

local DEFAULT_TIME = config.defaultCraftingTime or 1000
local DEFAULT_MAX = config.defaultMaxCraft or 10
local DEFAULT_ICON = config.defaultIcon or 'fas fa-tools'
local DEFAULT_ANIM = config.defaultAnimation or {}
local INTERACT = config.interactDistance or 5.0
local TOLERANCE = config.timeTolerance or 1500
local EDITORS = (config.customMenu and config.customMenu.editors) or {}
local LABEL_LEN = (config.customMenu and config.customMenu.labelLength) or { min = 3, max = 32 }
local HOSTS = (config.customMenu and config.customMenu.imageHosts) or {}
local EXTENSIONS = (config.customMenu and config.customMenu.imageExtensions) or {}
local SAVE_COOLDOWN = (config.customMenu and config.customMenu.saveCooldown) or 3000

local pending = {}
local savedAt = {}

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function buildDataset()
    for i = 1, #(config.data or {}) do
        local name = config.data[i]
        local ok, mod = pcall(localmodule, 'data.' .. name)
        if ok and type(mod) == 'table' then
            for key, tbl in pairs(mod.tables or {}) do
                tbl.key = key
                DATASET[key] = tbl
            end

            for key, recipe in pairs(mod.recipes or {}) do
                recipe.key = key
                local outputs = recipe.outputs or {}
                recipe.output = recipe.output or (outputs[1] and outputs[1].name)
                DATASET['#' .. key] = recipe
            end
        else
            print(('^1[sm_crafting] data/%s gagal dimuat^7'):format(name))
        end
    end
end

local function gradeAllowed(job, grade, rule)
    if not rule then return false end

    if type(rule) == 'table' then
        for i = 1, #rule do
            if grade == rule[i] then return true end
        end
        return false
    end

    return grade >= rule
end

local function tableAllowed(tbl, player)
    if tbl.publicAccess then return true end
    if not tbl.jobs then return false end
    return gradeAllowed(player.PlayerData.job.name, player.PlayerData.job.grade.level or 0, tbl.jobs[player.PlayerData.job.name])
end

local function recipeAllowed(recipe, player)
    if not recipe.jobs then return true end
    return gradeAllowed(player.PlayerData.job.name, player.PlayerData.job.grade.level or 0, recipe.jobs[player.PlayerData.job.name])
end

local function pointsOf(tbl)
    local list = {}

    for i = 1, #(tbl.locations or {}) do list[#list + 1] = tbl.locations[i] end
    for i = 1, #(tbl.spawnTable or {}) do
        if tbl.spawnTable[i].coords then list[#list + 1] = vec3(tbl.spawnTable[i].coords.x, tbl.spawnTable[i].coords.y, tbl.spawnTable[i].coords.z) end
    end

    return list
end

local function near(src, tbl)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local coords = GetEntityCoords(ped)

    for _, point in ipairs(pointsOf(tbl)) do
        if #(coords - point) <= INTERACT then return true end
    end

    return false
end

local function overridesOf(tableName)
    local rows = MySQL.query.await('SELECT recipe, label, image FROM ' .. CUSTOM .. ' WHERE `table` = ?', { tableName }) or {}
    local map = {}

    for i = 1, #rows do map[rows[i].recipe] = rows[i] end

    return map
end

lib.callback.register('sm_crafting:getMenu', function(src, tableName)
    local player = playerOf(src)
    if not player then return nil end

    local tbl = DATASET[tableName]
    if not tbl or not tbl.title then return nil end
    if not tableAllowed(tbl, player) then return nil end
    if not near(src, tbl) then return nil end

    local overrides = overridesOf(tableName)
    local out = { title = tbl.title, icon = tbl.icon or DEFAULT_ICON, recipes = {} }

    for key, recipe in pairs(DATASET) do
        if key:sub(1, 1) == '#' then
            local allowed = false
            for i = 1, #(recipe.tables or {}) do
                if recipe.tables[i] == tableName then allowed = true break end
            end

            if allowed and recipeAllowed(recipe, player) then
                local override = overrides[recipe.key]

                out.recipes[#out.recipes + 1] = {
                    key = recipe.key,
                    label = (override and override.label) or recipe.label or recipe.output,
                    image = (override and override.image) or recipe.icon,
                    time = recipe.craftingTime or DEFAULT_TIME,
                    max = recipe.maxCraft or DEFAULT_MAX,
                    package = recipe.package or nil,
                    outputs = recipe.outputs,
                    materials = recipe.materials,
                }
            end
        end
    end

    return out
end)

local function amountOf(entry, amount)
    local count = entry.count
    local qty

    if type(count) == 'table' then
        qty = math.random(count[1] or 1, count[2] or count[1] or 1)
    else
        qty = count or 1
    end

    return qty * amount
end

local function buildAdditions(recipe, amount)
    local list = {}

    for i = 1, #(recipe.outputs or {}) do
        local entry = recipe.outputs[i]
        list[#list + 1] = { entry.name, amountOf(entry, amount), recipe.toItemsMeta and recipe.toItemsMeta[entry.name] or nil }
    end

    return list
end

local function buildRemovals(recipe, amount)
    local list = {}

    for i = 1, #(recipe.materials or {}) do
        local entry = recipe.materials[i]
        list[#list + 1] = { entry.name, amountOf(entry, amount) }
    end

    return list
end

lib.callback.register('sm_crafting:startCraft', function(src, tableName, recipeKey, amount)
    local player = playerOf(src)
    if not player then return nil end
    if pending[src] then return nil end

    local tbl = DATASET[tableName]
    local recipe = DATASET['#' .. tostring(recipeKey)]
    if not tbl or not recipe then return nil end

    if not tableAllowed(tbl, player) or not recipeAllowed(recipe, player) then return nil end
    if not near(src, tbl) then return nil end

    amount = math.floor(tonumber(amount) or 1)
    amount = math.max(math.min(amount, recipe.maxCraft or DEFAULT_MAX), 1)

    local removals = buildRemovals(recipe, amount)

    if not transaction(src, removals, {}, { reason = 'craft-start', recipe = recipe.key }) then
        notify(src, 'Bahan tidak cukup.')
        return nil
    end

    local duration = (recipe.craftingTime or DEFAULT_TIME) * amount

    pending[src] = {
        table = tableName,
        recipe = recipe,
        amount = amount,
        removals = removals,
        additions = buildAdditions(recipe, amount),
        startedAt = GetGameTimer(),
        duration = duration,
    }

    return {
        duration = duration,
        label = recipe.label or recipe.output,
        anim = recipe.animation or tbl.animation or DEFAULT_ANIM,
    }
end)

RegisterNetEvent('sm_crafting:finishCraft', function()
    local src = source
    local job = pending[src]
    if not job then return end

    pending[src] = nil

    local elapsed = GetGameTimer() - job.startedAt
    if elapsed + TOLERANCE < job.duration then
        transaction(src, {}, job.removals, { reason = 'craft-refund' })
        return notify(src, 'Terlalu cepat, bahan dikembalikan.')
    end

    if not transaction(src, {}, job.additions, { reason = 'craft-done', recipe = job.recipe.key }) then
        transaction(src, {}, job.removals, { reason = 'craft-refund' })
        return notify(src, 'Tas penuh, bahan dikembalikan.')
    end

    notify(src, ('%s selesai.'):format(job.recipe.label or job.recipe.output), 'success')
end)

RegisterNetEvent('sm_crafting:cancelCraft', function()
    local src = source
    local job = pending[src]
    if not job then return end

    pending[src] = nil
    transaction(src, {}, job.removals, { reason = 'craft-cancel' })
end)

RegisterNetEvent('sm_crafting:openPackage', function(slot)
    local src = source
    local player = playerOf(src)
    if not player then return end

    local entry = ox_inventory:GetSlot(src, tonumber(slot) or 0)
    if not entry or not entry.metadata or not entry.metadata.contents then return end

    local additions = {}

    for i = 1, #entry.metadata.contents do
        local part = entry.metadata.contents[i]
        additions[#additions + 1] = { part.item, part.count, part.meta }
    end

    if not transaction(src, { { entry.name, 1 } }, additions, { reason = 'package-open' }) then
        return notify(src, 'Tas penuh.')
    end
end)

local function editorAllowed(player, tableName)
    local rule = EDITORS[tableName]
    if not rule then return false end
    return gradeAllowed(player.PlayerData.job.name, player.PlayerData.job.grade.level or 0, rule)
end

local function validImage(url)
    local host, extension = tostring(url or ''):match('^https://([^/]+)/.+%.([%w]+)$')
    if not host or not extension then return false end

    local hostOk, extOk = false, false
    for i = 1, #HOSTS do if HOSTS[i] == host then hostOk = true break end end
    for i = 1, #EXTENSIONS do if EXTENSIONS[i] == extension:lower() then extOk = true break end end

    return hostOk and extOk
end

lib.callback.register('sm_crafting:saveCustom', function(src, tableName, recipeKey, label, image)
    local player = playerOf(src)
    if not player then return { success = false, message = 'Data pemain tidak siap.' } end
    if not editorAllowed(player, tableName) then return { success = false, message = 'Tidak punya izin.' } end

    local recipe = DATASET['#' .. tostring(recipeKey)]
    if not recipe then return { success = false, message = 'Resep tidak dikenal.' } end

    local stamp = GetGameTimer()
    if savedAt[src] and stamp - savedAt[src] < SAVE_COOLDOWN then
        return { success = false, message = 'Tunggu sebentar.' }
    end

    label = tostring(label or '')
    if #label < LABEL_LEN.min or #label > LABEL_LEN.max then
        return { success = false, message = ('Label %d-%d karakter.'):format(LABEL_LEN.min, LABEL_LEN.max) }
    end

    if image and image ~= '' and not validImage(image) then
        return { success = false, message = 'Host atau ekstensi gambar tidak diizinkan.' }
    end

    savedAt[src] = stamp

    MySQL.insert(
        ('INSERT INTO %s (`table`, recipe, label, image, updated) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE label = VALUES(label), image = VALUES(image), updated = VALUES(updated)'):format(CUSTOM),
        { tableName, recipeKey, label, image ~= '' and image or nil, os.time() }
    )

    return { success = true, message = 'Menu disimpan.' }
end)

lib.callback.register('sm_crafting:resetCustom', function(src, tableName, recipeKey)
    local player = playerOf(src)
    if not player then return { success = false, message = 'Data pemain tidak siap.' } end
    if not editorAllowed(player, tableName) then return { success = false, message = 'Tidak punya izin.' } end

    MySQL.update('DELETE FROM ' .. CUSTOM .. ' WHERE `table` = ? AND recipe = ?', { tableName, tostring(recipeKey) })

    return { success = true, message = 'Menu direset.' }
end)

CreateThread(function()
    buildDataset()

    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `table` varchar(48) NOT NULL,
        `recipe` varchar(64) NOT NULL,
        `label` varchar(64) DEFAULT NULL,
        `image` varchar(512) DEFAULT NULL,
        `updated` int(11) NOT NULL,
        PRIMARY KEY (`table`, `recipe`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(CUSTOM))
end)

AddEventHandler('playerDropped', function()
    local job = pending[source]
    if job then
        pending[source] = nil
        transaction(source, {}, job.removals, { reason = 'craft-drop' })
    end
    savedAt[source] = nil
end)

print('^2[sm_crafting] server siap^7')