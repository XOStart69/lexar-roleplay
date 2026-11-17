local config = localmodule 'config'
local Nui = localmodule 'modules.nui'
local Catalog = localmodule 'modules.catalog'
local Pull = localmodule 'modules.pull'
local locale = localmodule 'modules.locale'
local exportWrapper = require 'export_wrapper'

local anim = config.anims.album

---@param reason? string
---@return table
local function fail(reason)
    if reason then lib.notify({ description = locale(reason), type = 'error' }) end

    return { ok = false }
end

local function closed()
    StopAnimTask(cache.ped, anim.dict, anim.clip, 2.0)
    TriggerServerEvent('sm_tcgcards:album:close')
end

---@param slot integer
local function open(slot)
    if Nui.view() then return end
    if not Catalog.sync() then return fail('catalog_unavailable') end

    local result = Pull.await('album:open', slot)

    if not result then return fail('album_unknown') end

    lib.playAnim(cache.ped, anim.dict, anim.clip, 3.0, 3.0, -1, anim.flag)
    Nui.open('album', result, closed)
end

---@param slot integer
local function insert(slot)
    local ok, result, name = lib.callback.await('sm_tcgcards:album:insert', false, slot)

    if not ok then
        if result then lib.notify({ description = locale(result, name), type = 'error', position = 'top' }) end

        return
    end

    lib.notify({ description = locale('album_inserted', result, name), type = 'success', position = 'top' })
end

exportWrapper('sm_tcgcards', 'album', function(_, slot)
    CreateThread(function()
        open(slot.slot)
    end)
end)

exportWrapper('sm_tcgcards', 'putInAlbum', function(slot)
    local index = math.tointeger(slot)

    if not index then return end

    CreateThread(function()
        insert(index)
    end)
end)

Nui.on('album:take', function(data)
    local ok, reason = lib.callback.await('sm_tcgcards:album:take', false, math.tointeger(data.card))

    if not ok then return fail(reason) end

    return { ok = true }
end)
