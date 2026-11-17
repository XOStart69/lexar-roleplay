---@class BillingClient
local invoice = {}

---@type integer?
local current
---@type fun(): boolean
local busy = function() return false end

local function hide()
    current = nil
    SendNUIMessage({ action = 'bill', data = false })

    if not busy() then SetNuiFocus(false, false) end
end

RegisterNetEvent('sm_custom:client:bill', function(bill)
    if source == '' or type(bill) ~= 'table' or math.type(bill.id) ~= 'integer' then return end

    current = bill.id

    SendNUIMessage({ action = 'bill', data = bill })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('sm_custom:client:billClosed', function(id)
    if source == '' or id ~= current then return end

    hide()
    lib.notify({ type = 'error', description = locale('bill.expired') })
end)

RegisterNUICallback('billReply', function(data, cb)
    cb(1)

    local id = current
    if not id then return end

    local choice = type(data) == 'table' and data.choice
    local reply = (choice == 'cash' or choice == 'bank') and choice or 'decline'

    hide()
    TriggerServerEvent('sm_custom:server:billReply', id, reply)
end)

---@param handler fun(): boolean
function invoice.start(handler)
    busy = handler
end

return invoice
