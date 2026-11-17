local battery = 100
local charging = false

local function setBattery(value)
    if not Config.Battery.Enabled then
        return
    end

    assert(type(value) == "number", "setBattery: battery must be a number")
    assert(value >= 0 and value <= 100, "setBattery: battery must be between 0 and 100")

    battery = value

    if value == 0 then
        OnDeath()
        TriggerEvent("lb-phone:phoneDied")
    end

    TriggerServerEvent("phone:battery:setBattery", value)
end

RegisterNUICallback("setBattery", function(data, cb)
    setBattery(data)
    cb("ok")
end)

exports("SetBattery", function(value)
    setBattery(value)
    SendNUIAction("battery:setBattery", value)
end)

exports("GetBattery", function()
    return battery
end)

---@param value number
function SyncBatteryValue(value)
    if not Config.Battery.Enabled then
        return
    end

    if type(value) ~= "number" or value < 0 or value > 100 then
        return
    end

    battery = value
end

function ToggleCharging(toggle)
    assert(type(toggle) == "boolean", "ToggleCharging: toggle must be a boolean")

    if charging == toggle then
        debugprint("ToggleCharging: charging is already set to", toggle)
        return
    end

    charging = toggle
    SendNUIAction("battery:toggleCharging", toggle)
end

exports("ToggleCharging", ToggleCharging)

exports("IsCharging", function()
    return charging
end)

function IsPhoneDead()
    if not Config.Battery.Enabled then
        return false
    end
    return battery == 0
end

exports("IsPhoneDead", IsPhoneDead)
