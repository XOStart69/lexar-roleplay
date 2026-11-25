--[[
    sm_drugfield :: server
    Petik tanaman: start -> (progress di client) -> finish. Jarak, item, dan durasi dicek server.
]]

local config = localmodule 'config'

local FIELDS = {}
for i = 1, #config.fields do FIELDS[config.fields[i].key] = config.fields[i] end

local sessions = {}

local function inventoryCount(src, item)
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

lib.callback.register('sm_drugfield:start', function(src, key)
    local field = FIELDS[tostring(key)]
    if not field then return false, 'Ladang tidak dikenal.' end
    if not qb_ecore:GetPlayer(src) then return false, 'Karakter belum siap.' end

    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - field.coords) > field.radius + 15.0 then
        return false, 'Terlalu jauh dari ladang.'
    end

    if field.requireItem and inventoryCount(src, field.requireItem) < 1 then
        return false, ('Kamu butuh %s!'):format(field.requireItem)
    end

    local current = sessions[src]
    if current and GetGameTimer() - current.at < field.pickupTime then
        return false, 'Masih mengambil.'
    end

    sessions[src] = { key = field.key, at = GetGameTimer() }
    return true
end)

lib.callback.register('sm_drugfield:cancel', function(src)
    sessions[src] = nil
    return true
end)

lib.callback.register('sm_drugfield:finish', function(src, key)
    local session = sessions[src]
    sessions[src] = nil

    local field = FIELDS[tostring(key)]
    if not session or not field or session.key ~= field.key then return false end
    if GetGameTimer() - session.at < field.pickupTime * 0.8 then return false, 'Terlalu cepat.' end

    local amount = math.random(field.rewardMin or 1, field.rewardMax or 1)

    if not exports.ox_inventory:CanCarryItem(src, field.reward, amount) then
        return false, 'Inventory penuh.'
    end

    if not exports.ox_inventory:AddItem(src, field.reward, amount) then
        return false, 'Gagal menambahkan item.'
    end

    return true, ('Mendapatkan %dx %s.'):format(amount, field.rewardLabel or field.reward)
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)
