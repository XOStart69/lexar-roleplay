local isOpen = false

---@param state boolean
local function setOpen(state)
    isOpen = state
    SetNuiFocus(state, state)
end

RegisterNetEvent('rhd_casino_manage:client:open', function(data)
    if source == '' or isOpen then return end

    SendNUIMessage({ action = 'manage:open', data = data })
    setOpen(true)
end)

RegisterNUICallback('rhd_casino_manage:close', function(_, cb)
    cb('ok')
    setOpen(false)
end)

AddEventHandler('rhd_casino:client:forceLeave', function()
    if not isOpen then return end

    setOpen(false)
    SendNUIMessage({ action = 'manage:close' })
end)
