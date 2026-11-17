local function applyBackup(number, cb)
    if number == currentPhone then
        debugprint("can't apply backup since it's the currently equipped number")
        return cb(false)
    end
    local result = AwaitCallback("backup:applyBackup", number)
    debugprint("phone:backup:applyBackup", number, ":", result)
    cb(result)
    if not result then
        return
    end
    Wait(5000)
    OnDeath()
    Wait(500)
    FetchPhone()
    Wait(500)
    ToggleOpen(true)
end

RegisterNUICallback("Backup", function(data, cb)
    local action = data.action
    debugprint("Backup:" .. (action or ""))
    if action == "create" then
        TriggerCallback("backup:createBackup", cb)
    elseif action == "delete" then
        TriggerCallback("backup:deleteBackup", cb, data.number)
    elseif action == "apply" then
        applyBackup(data.number, cb)
    elseif action == "get" then
        TriggerCallback("backup:getBackups", cb)
    end
end)
