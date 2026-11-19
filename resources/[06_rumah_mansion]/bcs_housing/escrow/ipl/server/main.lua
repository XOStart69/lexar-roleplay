AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    print('[bcs_housing] customize IPL server siap')
end)