local animDict = 'anim@mp_point'
local SetTaskMoveNetworkSignalFloat =SetTaskMoveNetworkSignalFloat
local GetGameplayCamRelativePitch = GetGameplayCamRelativePitch
local GetGameplayCamRelativeHeading = GetGameplayCamRelativeHeading

local pointactive = false

local function disabled ()
    local ped = cache.ped
    RequestTaskMoveNetworkStateTransition(ped, 'Stop')
    ClearPedSecondaryTask(ped)
    RemoveAnimDict(animDict)
    pointactive = false
end

local function PointingLoop(ped)
    while pointactive do
        if PState.isdead or cache.weapon or cache.vehicle then return disabled() end
        SetTaskMoveNetworkSignalFloat(ped, 'Pitch', (GetGameplayCamRelativePitch() + 70) / 110)
        SetTaskMoveNetworkSignalFloat(ped, 'Heading', (GetGameplayCamRelativeHeading() + 180) / 360 * -1.0 + 1.0)
        Wait(15)
    end
end

local keybind = lib.addKeybind({
    name = 'pointing',
    description = 'Menunjuk',
    defaultKey = 'B',
    onPressed = function(self)
        local ped = cache.ped
        lib.requestAnimDict(animDict)

        if not pointactive then
            pointactive = not pointactive
            TaskMoveNetworkByName(ped, 'task_mp_pointing', 0.5, 0, animDict, 24)
            PointingLoop(ped)
        else
            RequestTaskMoveNetworkStateTransition(ped, 'Stop')
            ClearPedSecondaryTask(ped)
            RemoveAnimDict(animDict)
            pointactive = not pointactive
        end
    end,
})

lib.onCache('weapon', function(v) keybind:disable(v and true or false) end)

_ENV.pointing = {
    enable = function ()
        local ped = cache.ped
        lib.requestAnimDict(animDict)

        if not pointactive then
            pointactive = not pointactive
            TaskMoveNetworkByName(ped, 'task_mp_pointing', 0.5, 0, animDict, 24)
            PointingLoop(ped)
        else
            RequestTaskMoveNetworkStateTransition(ped, 'Stop')
            ClearPedSecondaryTask(ped)
            RemoveAnimDict(animDict)
            pointactive = not pointactive
        end
    end
}