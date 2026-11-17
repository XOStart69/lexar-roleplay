local Config = localmodule 'config'

---@type table<string, CraftingTable>
local tables = {}
---@type table<string, CraftingRecipe>
local recipes = {}
---@type table<string, string[]>
local byTable = {}
---@type table<string, CraftingRecipe>
local packagesByBox = {}
---@type table<string, table<string, string>>
local menuItems = {}

local dataFiles = Config.data

for i = 1, #dataFiles do
    local data = localmodule('data.' .. dataFiles[i])

    for name, bench in pairs(data.tables) do
        tables[name] = bench
    end

    for key, recipe in pairs(data.recipes) do
        recipes[key] = recipe
    end
end

local defaultCraftingTime = Config.defaultCraftingTime
local defaultMaxCraft = Config.defaultMaxCraft

for key, recipe in pairs(recipes) do
    recipe.key = key
    recipe.craftingTime = recipe.craftingTime or defaultCraftingTime
    recipe.maxCraft = recipe.maxCraft or defaultMaxCraft

    local output, outputs = nil, 0

    for item in pairs(recipe.toItems) do
        output = item
        outputs = outputs + 1
    end

    recipe.output = outputs == 1 and output or nil

    if recipe.package and recipe.output then
        packagesByBox[recipe.output] = recipe
    elseif recipe.output and recipe.jobs then
        for jobName in pairs(recipe.jobs) do
            local items = menuItems[jobName]

            if not items then
                items = {}
                menuItems[jobName] = items
            end

            items[recipe.output] = key
        end
    end

    local benches = recipe.tables

    for i = 1, #benches do
        local name = benches[i]

        if tables[name] then
            local list = byTable[name]

            if not list then
                list = {}
                byTable[name] = list
            end

            list[#list + 1] = key
        end
    end
end

for _, list in pairs(byTable) do
    table.sort(list)
end

local editors = Config.customMenu.editors
local checkGroup = qbLib.checkGroup

---@param bench CraftingTable
---@param job table?
---@return boolean
local function canUseTable(bench, job)
    if bench.publicAccess or not bench.jobs then return true end
    return checkGroup(job, bench.jobs)
end

---@param recipe CraftingRecipe
---@param job table?
---@return boolean
local function canUseRecipe(recipe, job)
    if not recipe.jobs then return true end
    return checkGroup(job, recipe.jobs)
end

---@param job table?
---@return boolean
local function canEditMenu(job)
    return checkGroup(job, editors)
end

---@param recipe CraftingRecipe
---@param jobName string?
---@return boolean
local function isCustomizable(recipe, jobName)
    return recipe.output ~= nil and jobName ~= nil and editors[jobName] ~= nil and recipe.jobs ~= nil and recipe.jobs[jobName] ~= nil
end

return {
    tables = tables,
    recipes = recipes,
    byTable = byTable,
    packagesByBox = packagesByBox,
    menuItems = menuItems,
    canUseTable = canUseTable,
    canUseRecipe = canUseRecipe,
    canEditMenu = canEditMenu,
    isCustomizable = isCustomizable,
}
