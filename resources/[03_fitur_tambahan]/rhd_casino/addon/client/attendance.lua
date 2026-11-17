RegisterNUICallback('rhd_casino_attendance:getData', function(data, cb)
    local week = type(data) == 'table' and data.week or nil
    local ok, result = lib.callback.await('rhd_casino_attendance:getData', false, week)

    cb({
        ok = ok == true,
        data = ok == true and result or nil,
        error = ok ~= true and result or nil,
    })
end)

RegisterNUICallback('rhd_casino_attendance:setTarget', function(data, cb)
    if type(data) ~= 'table' then
        return cb({ ok = false, error = 'Data tidak valid.' })
    end

    local ok, result = lib.callback.await('rhd_casino_attendance:setTarget', false, data.citizenid, data.hours)

    cb({
        ok = ok == true,
        error = ok ~= true and result or nil,
    })
end)
