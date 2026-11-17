local exportWrapper = require 'export_wrapper'

local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetPedInVehicleSeat = GetPedInVehicleSeat
local TaskVehicleTempAction = TaskVehicleTempAction
local GetGameTimer = GetGameTimer
local Wait = Wait
local random = math.random

local ANIM_SET = 'move_m@drunk@verydrunk'
local DRIVE_TASKS = { 1, 7, 8, 23, 4, 5 }
local DRIVE_TASK_COUNT = #DRIVE_TASKS
local DRIVE_INTERVAL_MS = 5000
local DEFAULT_SECONDS = 10

local drunkUntil = 0
local active = false

local function applyEffect()
    local ped = cache.ped
    if lib.requestAnimSet(ANIM_SET, 5000) then
        SetPedMovementClipset(ped, ANIM_SET, 1.0)
    end
    ShakeGameplayCam('DRUNK_SHAKE', 1.0)
    SetPedIsDrunk(ped, true)
    SetTransitionTimecycleModifier('spectator5', 10.0)
end

local function clearEffect()
    local ped = cache.ped
    SetTransitionTimecycleModifier('default', 10.0)
    StopGameplayCamShaking(true)
    SetPedIsDrunk(ped, false)
    ResetPedMovementClipset(ped, 1.0)
    RemoveAnimSet(ANIM_SET)
end

local function drunkLoop()
    applyEffect()

    local nextDriveTask = 0
    while active and GetGameTimer() < drunkUntil do
        local now = GetGameTimer()
        if now >= nextDriveTask then
            nextDriveTask = now + DRIVE_INTERVAL_MS
            local ped = cache.ped
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                TaskVehicleTempAction(ped, vehicle, DRIVE_TASKS[random(DRIVE_TASK_COUNT)], 500)
            end
        end
        Wait(1000)
    end

    active = false
    drunkUntil = 0
    clearEffect()
end

---@param seconds? number
local function setDrunk(seconds)
    seconds = tonumber(seconds) or DEFAULT_SECONDS
    if seconds <= 0 then return end

    local now = GetGameTimer()
    drunkUntil = (drunkUntil > now and drunkUntil or now) + seconds * 1000

    if active then return end
    active = true
    CreateThread(drunkLoop)
end

local function resetDrunk()
    if not active then return end
    active = false
    drunkUntil = 0
end

---@param seconds? number
local function removeDrunkTime(seconds)
    if not active then return end
    drunkUntil = drunkUntil - (tonumber(seconds) or 1) * 1000
    if drunkUntil <= GetGameTimer() then
        resetDrunk()
    end
end

exports('setDrunk', setDrunk)
exports('resetDrunk', resetDrunk)
exports('removeDrunkTime', removeDrunkTime)

exportWrapper('sm_utilized', 'setDrunk', setDrunk)
exportWrapper('sm_utilized', 'resetDrunk', resetDrunk)
exportWrapper('sm_utilized', 'removeDrunkTime', removeDrunkTime)
