exports('Pause', function(id)
    TriggerClientEvent('xsound:pause', -1, id)
end)

exports('Resume', function(id)
    TriggerClientEvent('xsound:resume', -1, id)
end)

exports('SetVolume', function(id, volume)
    TriggerClientEvent('xsound:volume', -1, id, volume)
end)

exports('SetTimeStamp', function(id, timestamp)
    TriggerClientEvent('xsound:timestamp', -1, id, timestamp)
end)

exports('SetDistance', function(id, distance)
    TriggerClientEvent('xsound:distance', -1, id, distance)
end)

exports('SetMaxDistance', function(id, distance)
    TriggerClientEvent('xsound:maxDistance', -1, id, distance)
end)
