local function emit(target, ...)
    TriggerClientEvent('xsound:play', target, ...)
end

exports('PlayUrl', function(id, url, volume)
    emit(-1, id, url, volume)
end)

exports('PlayUrlPos', function(id, url, volume, coords, range)
    emit(-1, id, url, volume, coords, range)
end)

exports('PlayLocalUrl', function(id, url, volume)
    emit(-1, id, url, volume)
end)

exports('PlayUrlPos', function(id, url, volume, coords, range)
    emit(-1, id, url, volume, coords, range)
end)

exports('Destroy', function(id)
    TriggerClientEvent('xsound:destroy', -1, id)
end)

exports('DestroyAll', function()
    TriggerClientEvent('xsound:destroyAll', -1)
end)
