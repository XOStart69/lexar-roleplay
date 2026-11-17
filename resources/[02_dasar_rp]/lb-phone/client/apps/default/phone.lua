InExportCall = false

local isVideoCall = false
local inCall = false
local callNumber = nil
local customNumbers = {}
local activeCustomCall = nil
local customCallStart = 0
local customCallAnswered = false
local dynamicNumbers = {}
local dynamicNumberId = 0

local function endCustomCall()
    debugprint("EndCustomCall triggered")
    if activeCustomCall then
        local duration = math.floor((GetGameTimer() - customCallStart) / 1000 + 0.5)
        debugprint("Custom call to", activeCustomCall.number, "ended after", duration, "seconds", "answered:", customCallAnswered)
        TriggerServerEvent("phone:logCall", activeCustomCall.number, duration)
    end
    inCall = false
    activeCustomCall = nil
    callNumber = nil
    customCallStart = 0
    customCallAnswered = false
    SetPhoneAction("default")
    SendNUIAction("call:endCall")
    if not phoneOpen then
        PlayCloseAnim()
    end
end

local function CreateCustomCall(number)
    local data = customNumbers[number]
    if not data then
        for id, dynamic in pairs(dynamicNumbers) do
            local ok, result = pcall(function()
                return dynamic.isValid(number)
            end)
            if ok and result then
                data = dynamic.customNumber
                break
            elseif not ok then
                local trace = Citizen.InvokeNative(3607903178, nil, 0, Citizen.ResultAsString())
                print(([[
^1SCRIPT ERROR: Dynamic number validator (id %i, by resource '%s') failed: %s^7
%s]]):format(id, dynamic.resource, result or "", trace or ""))
            end
        end
    end
    if not data then
        return false
    end
    local callId = "CUSTOM_NUMBER_" .. math.random(9999999)
    inCall = true
    callNumber = callId
    activeCustomCall = data
    customCallStart = GetGameTimer()
    customCallAnswered = false
    Citizen.CreateThreadNow(function()
        data.onCall({
            id = callId,
            number = number,
            accept = function()
                if not (not customCallAnswered and callNumber == callId) then
                    return
                end
                customCallAnswered = true
                SetPhoneAction("call")
                SendNUIAction("call:connected")
            end,
            deny = function()
                if callNumber == callId then
                    endCustomCall()
                end
            end,
            setName = function(name)
                if callNumber == callId then
                    SendNUIAction("call:setContactData", { name = name })
                end
            end,
            hasEnded = function()
                return callNumber ~= callId
            end
        })
    end)
    return true
end

local function handleCustomCallAction(action)
    if not activeCustomCall then
        return
    end
    if "end" == action then
        if activeCustomCall.onEnd then
            Citizen.CreateThreadNow(activeCustomCall.onEnd)
        end
        endCustomCall()
        return
    end
    if action:find("keypad_") then
        if not activeCustomCall.onKeypad then
            return
        end
        local key = action:sub(8)
        if not key then
            return
        end
        Citizen.CreateThreadNow(function()
            activeCustomCall.onKeypad(key)
        end)
        return
    end
    if activeCustomCall.onAction then
        activeCustomCall.onAction(action)
    end
end

RegisterNUICallback("Phone", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("Phone:" .. (action or ""))
    if "getContacts" == action then
        TriggerCallback("getContacts", function(contacts)
            if Config.Companies.Enabled then
                for company, info in pairs(Config.Companies.Contacts) do
                    contacts[#contacts + 1] = {
                        firstname = info.name,
                        avatar = info.photo,
                        company = company
                    }
                end
            end
            cb(contacts)
        end)
    elseif "toggleFavourite" == action then
        TriggerCallback("toggleFavourite", cb, data.number, data.favourite)
    elseif "toggleBlock" == action then
        TriggerCallback("toggleBlock", cb, data.number, data.blocked)
    elseif "removeContact" == action then
        TriggerCallback("removeContact", cb, data.number)
    elseif "updateContact" == action then
        TriggerCallback("updateContact", cb, data.data)
    elseif "saveContact" == action then
        TriggerCallback("saveContact", cb, data.data)
    elseif "getRecent" == action then
        TriggerCallback("getRecentCalls", cb, data.missed == true, data.lastId)
    elseif "getBlockedNumbers" == action then
        TriggerCallback("getBlockedNumbers", function(blocked)
            local numbers = {}
            for key, value in pairs(blocked) do
                numbers[key] = value.number
            end
            cb(numbers)
        end)
    elseif "toggleMute" == action then
        if not callNumber then
            return cb(false)
        elseif activeCustomCall then
            handleCustomCallAction(data.toggle and "mute" or "unmute")
            return cb(data.toggle)
        end
        SetCallMuted(data.toggle, callNumber)
        cb(data.toggle)
    elseif "toggleSpeaker" == action then
        if not callNumber then
            return cb(false)
        elseif activeCustomCall then
            handleCustomCallAction(data.toggle and "enable_speaker" or "disable_speaker")
            return cb(data.toggle)
        end
        TriggerServerEvent("phone:phone:toggleSpeaker", data.toggle)
        ToggleSpeaker(data.toggle)
        cb(data.toggle)
    elseif "sendVoicemail" == action then
        TriggerCallback("sendVoicemail", cb, data.data)
    elseif "getVoiceMails" == action then
        TriggerCallback("getRecentVoicemails", cb, data.page)
    elseif "deleteVoiceMail" == action then
        TriggerCallback("deleteVoiceMail", cb, data.id)
    elseif "keypad" == action then
        cb("ok")
        if activeCustomCall then
            handleCustomCallAction("keypad_" .. data.key)
        end
    end

    if "call" == action then
        if data.company then
            if not (Config.Companies.Enabled and not data.videoCall) then
                return cb(false)
            end
            if not Config.Companies.Contacts[data.company] then
                local valid = false
                for i = 1, #Config.Companies.Services do
                    if Config.Companies.Services[i].job == data.company then
                        valid = true
                        break
                    end
                end
                if not valid then
                    return cb(false)
                end
            end
        end
        isVideoCall = data.videoCall
        local result = AwaitCallback("call", data)
        if "unknown_number" == result then
            if CreateCustomCall(data.number) then
                return cb("CUSTOM_NUMBER")
            end
            SendNUIAction("call:userUnavailable")
            return cb(false)
        end
        return cb(result)
    elseif "answerCall" == action then
        if IsInCall() then
            debugprint("answerCall: Already in call")
            return
        end
        if IsLive() then
            debugprint("answerCall: Ending live")
            TriggerCallback("instagram:endLive")
        elseif IsWatchingLive() then
            debugprint("answerCall: Leaving live")
            SendNUIAction("instagram:liveEnded", IsWatchingLive())
        end
        debugprint("Answering call", data.callId)
        TriggerServerEvent("phone:sound:stopSound")
        TriggerCallback("answerCall", cb, data.callId)
        cb("ok")
    elseif "endCall" == action then
        EndCall()
        cb("ok")
    elseif "flipCamera" == action then
        ToggleSelfieCam(not IsSelfieCam())
    elseif "requestVideoCall" == action then
        TriggerCallback("requestVideoCall", cb, data.callId, data.peerId)
    elseif "answerVideoRequest" == action then
        TriggerCallback("answerVideoRequest", cb, data.callId, data.accept)
        if data.accept then
            isVideoCall = true
            EnableWalkableCam()
        end
    elseif "stopVideoCall" == action then
        TriggerCallback("stopVideoCall", cb, data.callId)
    elseif "stopRingtone" == action then
        StopPhoneSound()
    end
end)

function EndCall()
    TriggerServerEvent("phone:sound:stopSound")
    TriggerServerEvent("phone:endCall")
    if activeCustomCall then
        handleCustomCallAction("end")
    end
end

RegisterNetEvent("phone:phone:setCall", function(data)
    if not HasPhoneItem(currentPhone) then
        debugprint("no phone, not showing call")
        return
    end
    if phoneDisabled then
        debugprint("phone is disabled, not showing call")
        return
    end
    if IsPhoneDead() then
        debugprint("phone is dead, not showing call")
        return
    end
    if activeCustomCall or inCall then
        debugprint("in a (custom?) call", tostring(activeCustomCall), tostring(inCall))
        return
    end
    if IsPedDeadOrDying(PlayerPedId(), false) then
        debugprint("player is dead, not showing call")
        return
    elseif CanOpenPhone and not CanOpenPhone() then
        debugprint("can't open phone, not showing call")
        return
    end
    isVideoCall = data.videoCall
    local ringtone
    if not data.hideCallerId and settings and settings.sound and settings.sound.ringtones and data.number then
        ringtone = settings.sound.ringtones[data.number]
    end
    PlayPhoneSound("ringtone", ringtone)
    SendNUIAction("incomingCall", data)
end)

RegisterNetEvent("phone:phone:enableExportCall", function()
    InExportCall = true
end)

RegisterNetEvent("phone:phone:connectCall", function(number, silent)
    debugprint("phone:phone:connectCall", number, silent)
    inCall = true
    callNumber = number
    AddToCall(number)
    if silent then
        return
    end
    StopPhoneSound()
    SetPhoneAction("call")
    SendNUIAction("call:connected")
    if isVideoCall then
        EnableWalkableCam()
    end
end)

RegisterNetEvent("phone:phone:endCall", function()
    debugprint("phone:phone:endCall")
    local wasInCall = inCall
    inCall = false
    isVideoCall = false
    SetPhoneAction("default")
    DisableWalkableCam()
    if not phoneOpen and wasInCall then
        debugprint("close anim")
        PlayCloseAnim()
    end
    StopPhoneSound()
    RemoveFromCall(callNumber)
    callNumber = nil
    InExportCall = false
    TriggerServerEvent("phone:sound:stopSound")
    SendNUIAction("call:endCall")
end)

RegisterNetEvent("phone:phone:userUnavailable", function()
    debugprint("phone:phone:userUnavailable")
    SendNUIAction("call:userUnavailable")
end)

RegisterNetEvent("phone:phone:userBusy", function()
    debugprint("phone:phone:userBusy")
    SendNUIAction("call:userBusy")
end)

function IsInCall()
    return inCall
end

exports("IsInCall", IsInCall)

exports("AddContact", function(contact)
    assert(type(contact) == "table", "contact must be a table")
    assert(type(contact.number) == "string", "contact.number must be a string")
    assert(type(contact.firstname) == "string", "contact.firstname must be a string")
    local result = AwaitCallback("saveContact", contact)
    if result then
        SendNUIAction("phone:contactAdded", contact)
    end
    return result
end)

exports("UpdateContact", function(contact)
    assert(type(contact) == "table", "contact must be a table")
    assert(type(contact.number) == "string", "contact.number must be a string")
    assert(type(contact.firstname) == "string", "contact.firstname must be a string")
    local clone = table.clone(contact)
    clone.oldNumber = clone.oldNumber or clone.number
    TriggerCallback("updateContact", nil, clone)
    SendNUIAction("phone:contactUpdated", contact)
    return true
end)

exports("RemoveContact", function(phoneNumber)
    assert(type(phoneNumber) == "string", "phoneNumber must be a string")
    TriggerCallback("removeContact", nil, phoneNumber)
    SendNUIAction("phone:contactRemoved", phoneNumber)
    return true
end)

RegisterNetEvent("phone:phone:videoRequested", function(data)
    debugprint("phone:phone:videoRequested", data)
    SendNUIAction("call:videoRequested", data)
end)

RegisterNetEvent("phone:phone:videoRequestAnswered", function(accept)
    debugprint("phone:phone:videoRequestAnswered", accept)
    SendNUIAction("call:videoRequestAnswered", accept)
    if accept then
        isVideoCall = true
        EnableWalkableCam()
    end
end)

RegisterNetEvent("phone:phone:stopVideoCall", function()
    debugprint("phone:phone:stopVideoCall")
    SendNUIAction("call:stopVideoCall")
    isVideoCall = false
    DisableWalkableCam()
end)

RegisterNetEvent("phone:phone:contactAdded", function(contact)
    debugprint("phone:phone:contactAdded", contact)
    SendNUIAction("phone:contactAdded", contact)
end)

function CreateCall(options)
    assert(type(options) == "table", "options must be a table")
    assert(options.number or options.company, "options must contain either a number or company")
    if not currentPhone then
        return debugprint("no phone")
    end
    if options.hideNumber == nil then
        if (settings and settings.phone and settings.phone.showCallerId) == false then
            options.hideNumber = true
        end
    end
    if options.company then
        if not Config.Companies.Enabled then
            return debugprint("company calls are disabled in config")
        end
        local valid = false
        local label = options.company
        if Config.Companies.Contacts[options.company] then
            label = Config.Companies.Contacts[options.company].name
            valid = true
        else
            for i = 1, #Config.Companies.Services do
                if Config.Companies.Services[i].job == options.company then
                    valid = true
                    label = Config.Companies.Services[i].name
                    break
                end
            end
        end
        if not valid then
            return debugprint("invalid company")
        end
        debugprint("CreateCall: company", options)
        SendNUIAction("call", {
            company = options.company,
            companylabel = label,
            hideCallerId = options.hideNumber == true
        })
    else
        debugprint("CreateCall: number", options)
        SendNUIAction("call", {
            number = options.number,
            videoCall = options.videoCall == true,
            hideCallerId = options.hideNumber == true
        })
    end
end

exports("CreateCall", CreateCall)

exports("CreateCustomNumber", function(number, data)
    local resource = GetInvokingResource()
    assert(type(number) == "string", "number must be a string")
    assert(type(data) == "table", "data must be a table")
    assert(type(data.onCall) == "function", "data.onCall must be a function")
    if customNumbers[number] then
        return false, "Number already exists"
    end
    customNumbers[number] = {
        resource = resource,
        number = number,
        onCall = data.onCall,
        onEnd = data.onEnd,
        onAction = data.onAction,
        onKeypad = data.onKeypad
    }
    return true
end)

exports("RemoveCustomNumber", function(number)
    local resource = GetInvokingResource()
    assert(type(number) == "string", "number must be a string")
    if not customNumbers[number] then
        return false, "Number does not exist"
    end
    if customNumbers[number].resource ~= resource then
        return false, "Number was not created by " .. resource
    end
    customNumbers[number] = nil
    return true
end)

exports("EndCustomCall", function()
    if activeCustomCall then
        endCustomCall()
        return true
    end
    return false
end)

exports("CreateDynamicCustomNumber", function(validator, data)
    local resource = GetInvokingResource()
    assert(type(validator) == "function", "validator must be a function")
    assert(type(data) == "table", "data must be a table")
    assert(type(data.onCall) == "function", "data.onCall must be a function")
    dynamicNumberId = dynamicNumberId + 1
    dynamicNumbers[dynamicNumberId] = {
        isValid = validator,
        customNumber = data,
        resource = resource
    }
    return dynamicNumberId
end)

exports("RemoveDynamicCustomNumber", function(id)
    local resource = GetInvokingResource()
    assert(type(id) == "number", "id must be a number")
    local entry = dynamicNumbers[id]
    if not entry then
        return false, "Dynamic number does not exist"
    end
    if entry.resource ~= resource then
        return false, "Dynamic number was not created by " .. resource
    end
    dynamicNumbers[id] = nil
    return true
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        return
    end
    for number, data in pairs(customNumbers) do
        if data.resource == resourceName then
            debugprint("Removed custom number", number, "due to resource stopping")
            if activeCustomCall == data then
                handleCustomCallAction("end")
            end
            customNumbers[number] = nil
        end
    end
    for id, data in pairs(dynamicNumbers) do
        if data.resource == resourceName then
            debugprint("Removed dynamic custom number id", id, "due to resource stopping")
            dynamicNumbers[id] = nil
        end
    end
end)
