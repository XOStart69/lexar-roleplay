local GetVehiclePedIsTryingToEnter = GetVehiclePedIsTryingToEnter
local GetSeatPedIsTryingToEnter = GetSeatPedIsTryingToEnter
local GetPedInVehicleSeat = GetPedInVehicleSeat
local IsPedAPlayer = IsPedAPlayer
local IsPedDeadOrDying = IsPedDeadOrDying
local ClearPedTasks = ClearPedTasks
local GetIsTaskActive = GetIsTaskActive
local Wait = Wait

local TASK_SHUFFLE = 165
local SHUFFLE_TIMEOUT = 5000
local IDLE_POLL = 250
local ACTIVE_POLL = 50

local watchingEntry = false
local shuffling = false

lib.onCache('seat', function(seat)
    local ped = cache.ped
    if not ped then return end

    SetPedConfigFlag(ped, 184, true)

    if cache.vehicle and seat then
        SetPedIntoVehicle(ped, cache.vehicle, seat)
    end
end)

RegisterCommand('shuff', function()
    local vehicle = cache.vehicle
    if not vehicle or shuffling then return end

    if exports.sm_policejob:IsHandcuffed() then
        return lib.notify({ title = 'Peringatan', description = 'Anda sedang diborgol!', type = 'error' })
    end

    shuffling = true

    local ped = cache.ped
    local deadline = GetGameTimer() + SHUFFLE_TIMEOUT

    TaskShuffleToNextVehicleSeat(ped, vehicle)

    while GetIsTaskActive(ped, TASK_SHUFFLE) and GetGameTimer() < deadline do
        Wait(0)
    end

    shuffling = false
end, false)

local function watchPlayerJack()
    if watchingEntry then return end

    watchingEntry = true

    while not cache.vehicle do
        local sleep = IDLE_POLL
        local ped = cache.ped
        local vehicle = GetVehiclePedIsTryingToEnter(ped)

        if vehicle ~= 0 then
            sleep = ACTIVE_POLL

            local occupant = GetPedInVehicleSeat(vehicle, GetSeatPedIsTryingToEnter(ped))

            if occupant ~= 0 and occupant ~= ped and IsPedAPlayer(occupant) and not IsPedDeadOrDying(occupant, true) then
                ClearPedTasks(ped)
            end
        end

        Wait(sleep)
    end

    watchingEntry = false
end

lib.onCache('vehicle', function(vehicle)
    local ped = cache.ped
    local inVehicle = vehicle and true or false

    SetPedCanBeDraggedOut(ped, not inVehicle)
    SetPedConfigFlag(ped, 26, inVehicle)
    SetPedConfigFlag(ped, 27, inVehicle)
    SetPedConfigFlag(ped, 350, inVehicle)
    SetPedConfigFlag(ped, 398, inVehicle)

    if not inVehicle then
        SetTimeout(0, watchPlayerJack)
    end
end)

CreateThread(watchPlayerJack)
