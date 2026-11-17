local validApps = {
    Twitter = true,
    Instagram = true,
    TikTok = true,
    Mail = true,
    DarkChat = true
}

RegisterNUICallback("AccountSwitcher", function(data, cb)
    debugprint("AccountSwitcher:" .. (data.action or ""))

    if not currentPhone or not validApps[data.app] then
        debugprint("AccountSwitcher: Invalid app / no currentPhone", data.app)
        return cb(false)
    end

    if data.action == "switch" then
        TriggerCallback("accountSwitcher:switchAccount", cb, data.app, data.account)
    elseif data.action == "getAccounts" then
        TriggerCallback("accountSwitcher:getAccounts", function(accounts)
            if not accounts then
                cb(false)
            end
            local usernames = {}
            for i = 1, #accounts do
                usernames[i] = accounts[i].username
            end
            cb(usernames)
        end, data.app)
    end
end)

RegisterNetEvent("phone:logoutFromApp", function(data)
    debugprint("logoutFromApp:", data)

    if data.number and data.number == currentPhone then
        debugprint("Ignoring logoutFromApp event since number matches")
        return
    end

    debugprint(data.app .. ":logout", data.username)
    SendNUIAction(data.app .. ":logout", data.username)
end)
