RegisterNUICallback("logError", function(data, cb)
    if GetResourceMetadata(GetCurrentResourceName(), "ui_page", 0) == "ui/dist/index.html" then
        local errorMessage = data.error or "No error message"
        local stack = data.stack or "No stack"
        local componentStack = data.componentStack or "No component stack"
        TriggerServerEvent("phone:logError", errorMessage, stack, componentStack)
    end
    local wasOpen = phoneOpen
    OnDeath()
    if wasOpen then
        debugprint("Opening phone due to error")
        ToggleOpen(true)
    end
    Wait(5000)
    TriggerEvent("phone:sendNotification", {
        app = "Settings",
        title = "System Crash",
        content = "Your phone crashed. Press F8 for more info."
    })
    cb("ok")
end)
