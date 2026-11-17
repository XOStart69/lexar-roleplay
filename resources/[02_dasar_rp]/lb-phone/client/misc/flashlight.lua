flashlightEnabled = false

local function setFlashlight(toggle)
    local was = flashlightEnabled
    flashlightEnabled = toggle == true

    if flashlightEnabled == was then
        return
    end

    TriggerServerEvent("phone:toggleFlashlight", flashlightEnabled)

    if not flashlightEnabled then
        return
    end

    Citizen.CreateThreadNow(function()
        local ped = PlayerPedId()
        while true do
            if not flashlightEnabled then
                break
            end
            if phoneOpen then
                DrawFlashlight(ped)
            else
                Wait(500)
            end
            Wait(0)
        end
    end)
end

RegisterNUICallback("toggleFlashlight", function(data, cb)
    setFlashlight(data.toggled)
    SetTimeout(100, function()
        cb(flashlightEnabled)
    end)
end)

exports("ToggleFlashlight", function(toggle)
    if not phoneOpen then
        return
    end
    setFlashlight(toggle)
    SendNUIAction("toggleFlashlight", flashlightEnabled)
end)

exports("GetFlashlight", function()
    return flashlightEnabled == true
end)

if not Config.SyncFlash then
    return
end

local flashlights = {}

local interval = Interval:new(function()
    for _, coords in pairs(flashlights) do
        DrawFlashlight(coords)
    end
end, 0, false)

interval.onStart = function()
    debugprint("Started drawing flashlights")
end

interval.onStop = function()
    debugprint("Stopped drawing flashlights")
end

AddStateBagChangeHandler("flashlight", nil, function(bagName, key, value)
    local serverId, data = GetPlayerDataFromStateBag(bagName)
    if not serverId or serverId == GetPlayerServerId(PlayerId()) then
        return
    end

    if value then
        flashlights[serverId] = data
    else
        flashlights[serverId] = nil
    end

    interval:toggle(next(flashlights) ~= nil)
end)

RegisterNetEvent("onPlayerDropped", function(source)
    flashlights[source] = nil
    interval:toggle(next(flashlights) ~= nil)
end)
