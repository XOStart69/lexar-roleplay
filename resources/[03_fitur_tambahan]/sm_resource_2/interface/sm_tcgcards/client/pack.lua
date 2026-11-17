local config = localmodule 'config'
local Nui = localmodule 'modules.nui'
local Catalog = localmodule 'modules.catalog'
local locale = localmodule 'modules.locale'
local exportWrapper = require 'export_wrapper'

local anim = config.anims.pack

---@class OpenedPack
---@field claimed? boolean

---@type OpenedPack?
local opened

---@param reason? string
---@return table
local function fail(reason)
    if reason then lib.notify({ description = locale(reason), type = 'error' }) end

    return { ok = false }
end

---@param pack OpenedPack
local function claim(pack)
    if pack.claimed then return end

    pack.claimed = true

    local ok, reason = lib.callback.await('sm_tcgcards:pack:claim', false)

    if ok then return end

    pack.claimed = false
    fail(reason)
end

---@param slot integer
local function openPack(slot)
    if Nui.view() then return end
    if not Catalog.sync() then return fail('catalog_unavailable') end

    local result, reason = lib.callback.await('sm_tcgcards:pack:open', 500, slot)

    if not result then return fail(reason) end

    local pack = {}

    opened = pack
    lib.playAnim(cache.ped, anim.dict, anim.clip, 3.0, 3.0, -1, anim.flag)
    Nui.open('pack', result, function()
        opened = nil
        StopAnimTask(cache.ped, anim.dict, anim.clip, 2.0)
        CreateThread(function()
            claim(pack)
        end)
    end)
end

Nui.on('pack:tear', function()
    if not opened then return fail() end

    local cards = lib.callback.await('sm_tcgcards:pack:reveal', false)

    if not cards then return fail() end

    return { ok = true, cards = cards }
end)

Nui.on('pack:done', function()
    local pack = opened

    if not pack then return fail() end

    claim(pack)

    return { ok = true }
end)

---@param slot integer
local function openBox(slot)
    local ok, result = lib.callback.await('sm_tcgcards:box:open', 500, slot)

    if not ok then return fail(result) end

    lib.notify({ description = locale('box_opened', result), type = 'success' })
end

exportWrapper('sm_tcgcards', 'pack', function(_, slot)
    CreateThread(function()
        openPack(slot.slot)
    end)
end)

exportWrapper('sm_tcgcards', 'box', function(_, slot)
    CreateThread(function()
        openBox(slot.slot)
    end)
end)
