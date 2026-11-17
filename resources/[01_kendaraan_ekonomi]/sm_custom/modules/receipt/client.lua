local REASONS <const> = {
    receipt = 'receipt.invalid',
    denied = 'receipt.denied',
    far = 'receipt.far',
    working = 'receipt.working',
    damaged = 'receipt.damaged',
    changed = 'receipt.changed',
    locked = 'receipt.locked',
    spot = 'receipt.spot',
}

---@class ReceiptStaged
---@field netId integer
---@field shop string
---@field label string
---@field plate string

---@class ReceiptClient
local receipt = {}

---@type { id: string, netId: integer }?
local current
---@type ReceiptStaged?
local staged
local busy = false

---@param plate string
---@return string
local function trim(plate)
    return plate:match('^%s*(.-)%s*$')
end

---@param data { plate: string, model: integer, distance: number }
---@return number?
local function nearest(data)
    local origin = GetEntityCoords(cache.ped)
    local found, best

    for _, entry in ipairs(lib.getNearbyVehicles(origin, data.distance, true)) do
        local vehicle = entry.vehicle

        if GetEntityModel(vehicle) == data.model and trim(GetVehicleNumberPlateText(vehicle)) == data.plate then
            local distance = #(entry.coords - origin)

            if not best or distance < best then found, best = vehicle, distance end
        end
    end

    return found
end

local function close()
    if not current then return end

    current = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'receipt', data = false })
end

RegisterNetEvent('sm_custom:client:receiptUse', function(data)
    if source == '' or type(data) ~= 'table' or type(data.id) ~= 'string' then return end
    if busy or current or IsNuiFocused() then return end

    local vehicle = nearest(data)

    if not vehicle then
        return lib.notify({ type = 'error', description = locale('receipt.far', data.plate) })
    end

    busy = true

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local result = lib.callback.await('sm_custom:server:receiptCheck', false, data.id, netId)

    busy = false

    if type(result) ~= 'table' or type(result.view) ~= 'table' then
        local reason = type(result) == 'table' and REASONS[result.error] or REASONS.receipt

        return lib.notify({ type = 'error', description = locale(reason, data.plate) })
    end

    current = { id = data.id, netId = netId }
    SendNUIMessage({ action = 'receipt', data = result.view })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('receiptCustomers', function(_, cb)
    if not current then return cb({}) end

    cb(lib.callback.await('sm_custom:server:receiptCustomers', false) or {})
end)

RegisterNUICallback('receiptPay', function(data, cb)
    if not current or busy or type(data) ~= 'table' then return cb({ ok = false, reason = 'invalid' }) end

    busy = true

    local result = lib.callback.await(
        'sm_custom:server:receiptPay',
        false,
        current.id,
        current.netId,
        data.method,
        tonumber(data.customer)
    )

    busy = false

    if type(result) ~= 'table' then result = { ok = false, reason = 'timeout' } end

    cb(result)

    if not result.ok then return end

    close()
    lib.notify({ type = 'success', description = locale(result.staged and 'receipt.staged' or 'receipt.applied') })
end)

RegisterNUICallback('receiptClose', function(_, cb)
    cb(1)

    if not busy then close() end
end)

RegisterNetEvent('sm_custom:client:receiptApply', function(netId, patch)
    if source == '' or math.type(netId) ~= 'integer' or type(patch) ~= 'table' then return end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    modules.install.apply(NetToVeh(netId), patch)
end)

RegisterNetEvent('sm_custom:client:staged', function(data)
    if source == '' then return end

    staged = type(data) == 'table' and math.type(data.netId) == 'integer' and data or nil
    modules.install.stage(staged)
end)

---@param zone CustomZone
---@return integer?
function receipt.pending(zone)
    if not staged or zone.key ~= staged.shop or not zone.install then return end
    if not cache.vehicle or cache.seat ~= -1 or not NetworkGetEntityIsNetworked(cache.vehicle) then return end
    if NetworkGetNetworkIdFromEntity(cache.vehicle) ~= staged.netId then return end

    return staged.netId
end

---@param netId integer
---@param zone CustomZone
function receipt.register(netId, zone)
    if busy then return end

    busy = true

    local result = lib.callback.await('sm_custom:server:receiptRegister', false, netId, zone.id)

    busy = false

    if type(result) == 'table' and result.ok then
        return lib.notify({ type = 'success', description = locale('receipt.registered') })
    end

    local reason = type(result) == 'table' and REASONS[result.reason] or REASONS.receipt

    lib.notify({ type = 'error', description = locale(reason, staged and staged.plate or '') })
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then close() end
end)

return receipt
