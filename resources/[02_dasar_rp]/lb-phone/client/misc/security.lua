local cachedPin = nil
local cachedFace = nil
local cachedIdentifier = nil

function ResetSecurity(skipNui)
    debugprint("ResetSecurity triggered")
    cachedPin = nil
    cachedFace = nil
    cachedIdentifier = nil
    if not skipNui then
        SendNUIAction("resetSecurity")
    end
end

function GetIdentifier()
    if not cachedIdentifier then
        cachedIdentifier = AwaitCallback("security:getIdentifier")
        debugprint("getIdentifier:", cachedIdentifier)
    end
    return cachedIdentifier or "unknown"
end

local function validatePin(pin)
    if pin and type(pin) == "string" then
        if #pin ~= 4 then
            debugprint("invalid data.pin: invalid length", pin)
            return false
        elseif not tonumber(pin) then
            debugprint("invalid data.pin: failed to convert to number", pin)
            return false
        end
        return true
    end
    return false
end

RegisterNUICallback("Security", function(data, cb)
    local action = data.action
    debugprint("Security:" .. (action or ""), data)
    if action == "setPin" then
        if data.pin == cachedPin then
            debugprint("Failed to set pin: new pin is the same as the old pin")
            return cb(false)
        end
        if not validatePin(data.pin) then
            debugprint("Failed to set pin: invalid pin")
            return cb(false)
        end
        local success = AwaitCallback("security:setPin", data.pin, cachedPin)
        if success then
            debugprint("Successfully set pin to", data.pin)
            cachedPin = data.pin
        else
            debugprint("Failed to set pin")
        end
        cb(success)
    elseif action == "removePin" then
        local success = AwaitCallback("security:removePin", cachedPin)
        if success then
            ResetSecurity()
        end
        cb(success)
    elseif action == "verifyPin" then
        if cachedPin then
            debugprint("Has cached pin", cachedPin, data.pin)
            return cb(cachedPin == data.pin)
        end
        if not validatePin(data.pin) then
            debugprint("Failed to verify pin: invalid pin")
            return cb(false)
        end
        local success = AwaitCallback("security:verifyPin", data.pin)
        debugprint("security:verifyPin returned:", success)
        if success then
            debugprint("Correct pin, caching it", data.pin)
            cachedPin = data.pin
        end
        cb(success)
    end
    if action == "setFaceId" then
        if not cachedPin or cachedPin ~= data.pin then
            debugprint("Failed to enable Face Unlock: incorrect pin")
            debugprint(cachedPin, data.pin)
            return cb(false)
        end
        debugprint("Correct pin, triggering enableFaceUnlock")
        TriggerCallback("security:enableFaceUnlock", cb, data.pin)
    elseif action == "removeFaceId" then
        if not cachedPin or cachedPin ~= data.pin then
            debugprint("Failed to disable Face Unlock: incorrect pin")
            return cb(false)
        end
        debugprint("Correct pin, triggering disableFaceUnlock")
        TriggerCallback("security:disableFaceUnlock", cb, data.pin)
    elseif action == "verifyFace" then
        if IsFaceObstructed() then
            debugprint("Face is obstructed")
            return cb(false)
        end
        if not cachedIdentifier then
            GetIdentifier()
        end
        if cachedFace then
            debugprint("Has cached face, returning:", cachedFace == cachedIdentifier)
            return cb(cachedFace == cachedIdentifier)
        end
        local success = AwaitCallback("security:verifyFace")
        debugprint("security:verifyFace returned:", success)
        if success then
            cachedFace = cachedIdentifier
        end
        cb(success)
    end
    if action == "factoryReset" then
        TriggerServerEvent("phone:factoryReset")
    end
end)

RegisterNetEvent("phone:factoryReset", function()
    OnDeath()
    ResetSecurity()
    FetchPhone()
end)

RegisterNetEvent("phone:security:reset", function(phone)
    if phone == currentPhone then
        ResetSecurity()
        Wait(500)
        FetchPhone()
    end
end)
