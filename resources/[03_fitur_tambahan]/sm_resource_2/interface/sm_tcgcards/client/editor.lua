local Nui = localmodule 'modules.nui'
local Catalog = localmodule 'modules.catalog'
local locale = localmodule 'modules.locale'

RegisterNetEvent('sm_tcgcards:editor:open', function()
    if source == '' then return end
    if Nui.view() then return end
    if not Catalog.sync() then return lib.notify({ description = locale('catalog_unavailable'), type = 'error' }) end

    Nui.open('editor', {})
end)

---@param field string
---@param ok boolean
---@param result any
---@return table
local function reply(field, ok, result)
    if not ok then return { ok = false, reason = result } end

    return { ok = true, [field] = result }
end

Nui.on('editor:division', function(data)
    return reply('division', lib.callback.await('sm_tcgcards:editor:division', false, data))
end)

Nui.on('editor:divisionEnabled', function(data)
    return reply('division', lib.callback.await('sm_tcgcards:editor:divisionEnabled', false, data.id, data.enabled))
end)

Nui.on('editor:divisionDelete', function(data)
    return reply('done', lib.callback.await('sm_tcgcards:editor:divisionDelete', false, data.id))
end)

Nui.on('editor:card', function(data)
    return reply('card', lib.callback.await('sm_tcgcards:editor:card', false, data))
end)

Nui.on('editor:cardDelete', function(data)
    return reply('done', lib.callback.await('sm_tcgcards:editor:cardDelete', false, data.id))
end)

Nui.on('editor:cardGive', function(data)
    return reply('done', lib.callback.await('sm_tcgcards:editor:cardGive', false, data.id, data.quality))
end)

Nui.on('editor:booster', function(data)
    return reply('division', lib.callback.await('sm_tcgcards:editor:booster', false, data.id, data.booster))
end)

Nui.on('editor:boosterReset', function(data)
    return reply('division', lib.callback.await('sm_tcgcards:editor:boosterReset', false, data.id))
end)

Nui.on('editor:quality', function(data)
    return reply('division', lib.callback.await('sm_tcgcards:editor:quality', false, data.id, data.quality))
end)

Nui.on('editor:qualityReset', function(data)
    return reply('division', lib.callback.await('sm_tcgcards:editor:qualityReset', false, data.id))
end)
