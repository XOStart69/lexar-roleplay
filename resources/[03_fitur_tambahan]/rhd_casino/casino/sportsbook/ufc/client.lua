local config = require 'casino.sportsbook.config'

local tabletOpen = false

local function setTabletState(state)
    tabletOpen = state
    SetNuiFocus(state, state)
end

RegisterNetEvent('rhd_casino_ufc:client:openTablet', function(role)
    if source == '' then return end
    if tabletOpen then return end

    SendNUIMessage({
        action = 'ufc:open',
        data = { role = role },
    })
    setTabletState(true)
end)

RegisterNUICallback('rhd_casino_ufc:close', function(_, cb)
    cb('ok')
    setTabletState(false)
end)

RegisterNUICallback('rhd_casino_ufc:getNearbyPlayers', function(_, cb)
    cb({ ok = true, data = shared.getNearbyBettors() })
end)

local forwarded = {
    'getState',
    'createFight',
    'updateFight',
    'setFightStatus',
    'settleFight',
    'deleteFight',
    'deleteRecap',
    'placeBet',
    'lookupBet',
    'markPaid',
    'getRecap',
}

for i = 1, #forwarded do
    local name = ('rhd_casino_ufc:%s'):format(forwarded[i])

    RegisterNUICallback(name, function(data, cb)
        local args = type(data) == 'table' and data.args or nil
        local ok, result

        if type(args) == 'table' and #args > 0 then
            ok, result = lib.callback.await(name, false, table.unpack(args, 1, #args))
        else
            ok, result = lib.callback.await(name, false)
        end

        cb({
            ok = ok == true,
            data = ok == true and result or nil,
            error = ok ~= true and result or nil,
        })
    end)
end

AddEventHandler('rhd_casino:client:forceLeave', function()
    if tabletOpen then
        setTabletState(false)
        SendNUIMessage({ action = 'ufc:close' })
    end
end)
