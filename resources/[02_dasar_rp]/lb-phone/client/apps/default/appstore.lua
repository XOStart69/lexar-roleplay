RegisterNUICallback("AppStore", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("AppStore:" .. (action or ""))
    if action == "buyApp" then
        TriggerCallback("appstore:buyApp", cb, data.price)
    end
end)
