RegisterNUICallback("Clock", function(data, cb)
    local action = data.action
    debugprint("Clock:" .. (action or ""))
    if action == "getAlarms" then
        TriggerCallback("clock:getAlarms", cb)
    elseif action == "createAlarm" then
        TriggerCallback("clock:createAlarm", cb, data.label, data.hours, data.minutes)
    elseif action == "deleteAlarm" then
        TriggerCallback("clock:deleteAlarm", cb, data.id)
    elseif action == "toggleAlarm" then
        TriggerCallback("clock:toggleAlarm", cb, data.id, data.enabled)
    elseif action == "updateAlarm" then
        TriggerCallback("clock:updateAlarm", cb, data.id, data.label, data.hours, data.minutes)
    end
end)
