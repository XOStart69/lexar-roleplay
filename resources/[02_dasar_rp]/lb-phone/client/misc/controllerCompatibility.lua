local cursorX = 0.5
local cursorY = 0.5
local sensitivity = 0.005
local keyboardOpen = false

local function isUsingController()
    return IsUsingKeyboard(0) == false
end

local function getAxis(control)
    local value = GetDisabledControlNormal(0, control)
    if value < -0.1 or value > 0.1 then
        return value
    end
    return 0.0
end

RegisterNUICallback("toggleInput", function(data)
    if not isUsingController() then
        return
    end
    keyboardOpen = data == true
    if not data then
        Wait(250)
        if keyboardOpen then
            return
        end
    end
    SendNUIAction("controller:toggleKeyboard", keyboardOpen)
end)

local function processController()
    local axisX = getAxis(1)
    local axisY = getAxis(2)
    local axisScroll = getAxis(31)
    cursorX = cursorX + axisX * sensitivity
    cursorY = cursorY + axisY * sensitivity
    cursorX = math.min(0.99999, math.max(0, cursorX))
    cursorY = math.min(1.0, math.max(0, cursorY))
    if IsDisabledControlJustPressed(0, 18) then
        SendNUIAction("controller:press", { x = cursorX, y = cursorY })
    elseif IsDisabledControlJustReleased(0, 18) then
        SendNUIAction("controller:release", { x = cursorX, y = cursorY })
    elseif IsDisabledControlJustReleased(0, 199) or IsDisabledControlJustReleased(0, 177) then
        ToggleOpen(false)
    end
    if axisX ~= 0.0 or axisY ~= 0.0 then
        SetCursorLocation(cursorX, cursorY)
    end
    if axisScroll ~= 0.0 then
        SendNUIAction("controller:scroll", { amount = math.floor(axisScroll * 25), x = cursorX, y = cursorY })
    end
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    InvalidateIdleCam()
end

function ControllerThread()
    while phoneOpen do
        Wait(0)
        if isUsingController() then
            if IsNuiFocused() then
                processController()
            end
        else
            Wait(500)
        end
    end
    cursorX = 0.5
    cursorY = 0.5
    if isUsingController() then
        SetCursorLocation(cursorX, cursorY)
    end
end
