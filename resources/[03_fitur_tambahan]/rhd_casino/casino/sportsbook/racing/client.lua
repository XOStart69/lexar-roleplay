local tabletOpen = false

---@param state boolean
local function setTabletState(state)
    tabletOpen = state
    SetNuiFocus(state, state)
end

local FORWARDED <const> = {
    'createEvent',
    'updateEvent',
    'setEventStatus',
    'setLineClosed',
    'settleEvent',
    'deleteEvent',
    'deleteRecap',
    'placeBet',
    'lookupBet',
    'markPaid',
}

local HEAVY <const> = {
    'getState',
    'getRecap',
}

local prefix <const> = 'rhd_casino_racing'
local HEAVY_TIMEOUT <const> = 30000

RegisterNetEvent(('%s:client:openTablet'):format(prefix), function(role)
    if source == '' then return end
    if tabletOpen then return end

    SendNUIMessage({
        action = 'racing:open',
        data = { role = role },
    })
    setTabletState(true)
end)

RegisterNUICallback(('%s:close'):format(prefix), function(_, cb)
    cb('ok')
    setTabletState(false)
end)

RegisterNUICallback(('%s:getNearbyPlayers'):format(prefix), function(_, cb)
    cb({ ok = true, data = shared.getNearbyBettors() })
end)

for i = 1, #FORWARDED do
    local name = ('%s:%s'):format(prefix, FORWARDED[i])

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

local pending = {}
local nextRequestId = 0

RegisterNetEvent(('%s:response'):format(prefix), function(requestId, ok, result)
    if source == '' then return end

    local resolve = pending[requestId]
    if not resolve then return end

    pending[requestId] = nil
    resolve(ok, result)
end)

for i = 1, #HEAVY do
    local action = HEAVY[i]
    local name = ('%s:%s'):format(prefix, action)

    RegisterNUICallback(name, function(data, cb)
        local args = type(data) == 'table' and data.args or nil

        nextRequestId += 1
        local requestId = nextRequestId
        local answered = false

        pending[requestId] = function(ok, result)
            answered = true
            cb({
                ok = ok == true,
                data = ok == true and result or nil,
                error = ok ~= true and result or nil,
            })
        end

        if type(args) == 'table' and #args > 0 then
            TriggerServerEvent(('%s:request'):format(prefix), requestId, action, table.unpack(args, 1, #args))
        else
            TriggerServerEvent(('%s:request'):format(prefix), requestId, action)
        end

        SetTimeout(HEAVY_TIMEOUT, function()
            if answered then return end

            pending[requestId] = nil
            cb({ ok = false, error = 'Server tidak membalas permintaan data.' })
        end)
    end)
end

AddEventHandler('rhd_casino:client:forceLeave', function()
    if not tabletOpen then return end
    setTabletState(false)
    SendNUIMessage({ action = 'racing:close' })
end)
