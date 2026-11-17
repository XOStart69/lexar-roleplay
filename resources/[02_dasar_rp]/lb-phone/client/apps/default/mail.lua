local currentMail = nil

local function parseMail(mail)
    if not mail then
        return false
    end
    if not mail.attachments then
        mail.attachments = {}
    else
        mail.attachments = json.decode(mail.attachments)
    end
    if not mail.actions then
        mail.actions = {}
    else
        mail.actions = json.decode(mail.actions)
    end
    return mail
end

RegisterNUICallback("Mail", function(data, cb)
    local action = data.action
    debugprint("Mail:", action or "")
    if action == "isLoggedIn" then
        TriggerCallback("mail:isLoggedIn", cb)
    elseif action == "createMail" then
        TriggerCallback("mail:createAccount", cb, data.data.email, data.data.password)
    elseif action == "changePassword" then
        TriggerCallback("mail:changePassword", cb, data.oldPassword, data.newPassword)
    elseif action == "deleteAccount" then
        TriggerCallback("mail:deleteAccount", cb, data.password)
    elseif action == "login" then
        TriggerCallback("mail:login", cb, data.data.email, data.data.password)
    elseif action == "logout" then
        TriggerCallback("mail:logout", cb)
    elseif action == "getMails" then
        TriggerCallback("mail:getMails", cb, { lastId = data.lastId })
    elseif action == "getMail" then
        TriggerCallback("mail:getMail", function(mail)
            currentMail = parseMail(mail)
            cb(currentMail)
        end, data.id)
    elseif action == "search" then
        TriggerCallback("mail:getMails", cb, { search = data.query, lastId = data.lastId })
    elseif action == "sendMail" then
        TriggerCallback("mail:sendMail", cb, data.data)
    elseif action == "deleteMail" then
        TriggerCallback("mail:deleteMail", cb, data.id)
    elseif action == "action" then
        if currentMail.id ~= data.id then
            return debugprint("wrong mail id for action")
        end
        local actionIndex = (data.actionId or 0) + 1
        local mailAction = currentMail.actions[actionIndex]
        if mailAction then
            mailAction = mailAction.data
        end
        if not mailAction then
            return debugprint("no action found", actionIndex)
        end
        if mailAction.data and mailAction.data.qbMail then
            TriggerEvent(mailAction.event, mailAction.data.data)
            return cb("ok")
        end
        if mailAction.isServer then
            TriggerServerEvent(mailAction.event, data.id, mailAction.data)
        else
            TriggerEvent(mailAction.event, data.id, mailAction.data)
        end
        cb("ok")
    end
end)

RegisterNetEvent("phone:mail:newMail", function(data)
    SendNUIAction("mail:newMail", data)
end)

RegisterNetEvent("phone:mail:mailDeleted", function(data)
    SendNUIAction("mail:deleteMail", data)
end)
