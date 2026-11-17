local Nui = localmodule 'modules.nui'
local Catalog = localmodule 'modules.catalog'
local Pull = localmodule 'modules.pull'
local locale = localmodule 'modules.locale'
local exportWrapper = require 'export_wrapper'

---@param reason? string
---@return table
local function fail(reason)
    if reason then lib.notify({ description = locale(reason), type = 'error' }) end

    return { ok = false }
end

local function open()
    if Nui.view() then return end
    if not Catalog.sync() then return fail('catalog_unavailable') end

    local result = Pull.await('grading:list')

    if not result then return fail('grading_no_kit') end
    if #result.cards == 0 then return fail('grading_no_card') end

    Nui.open('grading', result)
end

exportWrapper('sm_tcgcards', 'grading', function()
    CreateThread(open)
end)

Nui.on('grading:seal', function(data)
    local ok, grade, quality, kits = lib.callback.await('sm_tcgcards:grading:seal', false, data.serial)

    if not ok then return fail(grade) end

    return { ok = true, grade = grade, quality = quality, kits = kits }
end)
