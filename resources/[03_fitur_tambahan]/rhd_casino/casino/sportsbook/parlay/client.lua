local FORWARDED <const> = {
    'placeParlay',
    'lookupParlay',
    'markPaid',
}

local HEAVY <const> = {
    'getParlays',
}

local prefix <const> = 'rhd_casino_parlay'
local HEAVY_TIMEOUT <const> = 30000

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
