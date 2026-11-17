local config = localmodule 'config'
local Nui = localmodule 'modules.nui'
local Catalog = localmodule 'modules.catalog'
local locale = localmodule 'modules.locale'
local exportWrapper = require 'export_wrapper'

local anim = config.anims.card

local shownUntil = 0

---@param duration integer
local function present(duration)
    local active = shownUntil > GetGameTimer()

    shownUntil = GetGameTimer() + duration

    if active then return end

    CreateThread(function()
        local focused = false

        while shownUntil > GetGameTimer() do
            if Nui.view() then
                focused = false
            else
                if not focused then
                    Nui.focus(true)
                    focused = true
                end

                DisablePlayerFiring(cache.playerId, true)
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 200, true)
                DisableControlAction(2, 199, true)
                DisableControlAction(2, 200, true)

                if IsDisabledControlJustReleased(0, 200) then
                    SetPauseMenuActive(false)
                    shownUntil = 0
                    Nui.send('dismiss')
                end
            end

            Wait(0)
        end

        if focused and not Nui.view() then Nui.unfocus() end
    end)
end

---@param reason? string
---@return table
local function fail(reason)
    if reason then lib.notify({ description = locale(reason), type = 'error' }) end

    return { ok = false }
end

---@param slot integer
local function view(slot)
    if Nui.view() then return end
    if not Catalog.sync() then return fail('catalog_unavailable') end

    local result, reason = lib.callback.await('sm_tcgcards:card:view', 500, slot)

    if not result then return fail(reason) end

    lib.playAnim(cache.ped, anim.dict, anim.clip, 3.0, 3.0, -1, anim.flag)
    Nui.open('card', result, function()
        StopAnimTask(cache.ped, anim.dict, anim.clip, 2.0)
    end)
end

exportWrapper('sm_tcgcards', 'card', function(_, slot)
    CreateThread(function()
        view(slot.slot)
    end)
end)

Nui.on('card:sleeve', function(data)
    local ok, copy, sleeves = lib.callback.await('sm_tcgcards:card:sleeve', false, data.serial)

    if not ok then return fail(copy) end

    lib.notify({ description = locale('sleeve_done'), type = 'success' })

    return { ok = true, copy = copy, sleeves = sleeves }
end)

Nui.on('card:unsleeve', function(data)
    local ok, copy, sleeves = lib.callback.await('sm_tcgcards:card:unsleeve', false, data.serial)

    if not ok then return fail(copy) end

    lib.notify({ description = locale('sleeve_removed'), type = 'success' })

    return { ok = true, copy = copy, sleeves = sleeves }
end)

Nui.on('card:show', function(data)
    local ok, result = lib.callback.await('sm_tcgcards:card:show', false, data.serial)

    if not ok then return fail(result) end

    lib.notify({ description = locale('show_done', result), type = 'success' })

    return { ok = true, count = result }
end)

Nui.on('card:give', function(data)
    local player = lib.getClosestPlayer(GetEntityCoords(cache.ped), config.give.distance)

    if not player then return fail('give_nobody') end

    local ok, result = lib.callback.await('sm_tcgcards:card:give', false, data.serial, GetPlayerServerId(player))

    if not ok then return fail(result) end

    lib.notify({ description = locale('give_done', result), type = 'success' })
    Nui.close()

    return { ok = true }
end)

RegisterNetEvent('sm_tcgcards:card:shown', function(data)
    if source == '' then return end
    if type(data) ~= 'table' or not Catalog.sync() then return end

    Nui.send('shown', data)

    local duration = math.tointeger(data.duration)

    if duration and duration > 0 then present(duration) end
end)

Nui.on('shown:closed', function()
    shownUntil = 0
end)
