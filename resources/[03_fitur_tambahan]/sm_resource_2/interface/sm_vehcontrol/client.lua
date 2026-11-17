local config = localmodule 'config'
local hasFrame = interface.init(false)

local Wait = Wait
local GetEntityModel = GetEntityModel
local GetVehicleModelNumberOfSeats = GetVehicleModelNumberOfSeats
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetIsDoorValid = GetIsDoorValid
local GetVehicleDoorAngleRatio = GetVehicleDoorAngleRatio
local IsVehicleWindowIntact = IsVehicleWindowIntact
local GetIsVehicleEngineRunning = GetIsVehicleEngineRunning
local GetVehicleIndicatorLights = GetVehicleIndicatorLights
local IsVehicleInteriorLightOn = IsVehicleInteriorLightOn
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local DisableControlAction = DisableControlAction
local DoesEntityExist = DoesEntityExist
local type = type

local REFRESH = config.refreshInterval
local KEEP_DRIVING = config.keepDriving
local BLOCKED_CONTROLS = { 1, 2, 24, 25, 37, 68, 69, 70, 91, 92, 106, 114, 140, 141, 142, 199, 200, 257, 263, 264, 331 }
local BLOCKED_COUNT = #BLOCKED_CONTROLS

local open = false
local mounted = false
local ready = false
local vehicle = nil

---@param description string
local function notify(description)
    lib.notify({ title = 'Kendaraan', description = description, type = 'error' })
end

---@param veh number
---@return table
local function snapshot(veh)
    local ped = cache.ped
    local model = GetEntityModel(veh)

    local seats = {}
    for index = -1, GetVehicleModelNumberOfSeats(model) - 2 do
        local occupant = GetPedInVehicleSeat(veh, index)
        seats[#seats + 1] = { index = index, mine = occupant == ped, taken = occupant ~= 0 and occupant ~= ped }
    end

    local doors = {}
    local windows = {}
    for index = 0, 5 do
        if GetIsDoorValid(veh, index) then
            doors[#doors + 1] = { index = index, open = GetVehicleDoorAngleRatio(veh, index) > 0.0 }
            if index <= 3 then
                windows[#windows + 1] = { index = index, open = not IsVehicleWindowIntact(veh, index) }
            end
        end
    end

    local label = GetLabelText(GetDisplayNameFromVehicleModel(model))
    local keys = SmVehicleKeys

    local popsAvailable, popsOn = false, false
    if HRS_PopsState and cache.seat == -1 then
        popsAvailable, popsOn = HRS_PopsState()
    end

    return {
        name = label ~= 'NULL' and label or GetDisplayNameFromVehicleModel(model),
        plate = GetVehicleNumberPlateText(veh),
        driver = cache.seat == -1,
        hasKeys = keys ~= nil and keys.canUse(veh) or false,
        engine = GetIsVehicleEngineRunning(veh),
        indicators = GetVehicleIndicatorLights(veh),
        interior = IsVehicleInteriorLightOn(veh),
        pops = popsAvailable and popsOn or false,
        popsAvailable = popsAvailable,
        seats = seats,
        doors = doors,
        windows = windows,
    }
end

---@param action string
---@param data? any
local function send(action, data)
    if ready then
        interface.send({ action = action, data = data })
    end
end

local function close()
    if not open then return end
    open = false
    vehicle = nil
    interface.focus(false, false, false)
    SetTimeout(100, function()
        if open or not mounted then return end
        mounted = false
        ready = false
        interface.hide()
    end)
end

local function startLoops()
    CreateThread(function()
        while open do
            local current = cache.vehicle
            if not current or current ~= vehicle or not DoesEntityExist(current) then
                send('close')
                close()
                break
            end
            send('state', snapshot(current))
            Wait(REFRESH)
        end
    end)

    if not KEEP_DRIVING then return end

    CreateThread(function()
        while open do
            for i = 1, BLOCKED_COUNT do
                DisableControlAction(0, BLOCKED_CONTROLS[i], true)
            end
            Wait(0)
        end
    end)
end

local function showMenu()
    send('open', snapshot(vehicle))
    interface.focus(true, true, KEEP_DRIVING)
    startLoops()
end

local function openMenu()
    if not hasFrame or open then return end
    local current = cache.vehicle
    if not current then return end

    open = true
    vehicle = current

    if ready then
        showMenu()
    elseif not mounted then
        mounted = true
        interface.show()
    end
end

---@param veh number
---@param index number
local function setSeat(veh, index)
    if index < -1 or index > GetVehicleModelNumberOfSeats(GetEntityModel(veh)) - 2 then return end
    if not IsVehicleSeatFree(veh, index) then return notify('Kursi sudah terisi.') end

    if index == -1 and GetResourceState('sm_resource_3') == 'started' then
        local allowed, reason = exports.sm_resource_3:CanDriveVehicle(veh)
        if not allowed then return notify(reason or 'Kamu tidak boleh mengemudikan kendaraan ini.') end
    end

    SetPedIntoVehicle(cache.ped, veh, index)
end

---@param veh number
---@param index number
local function toggleDoor(veh, index)
    if index < 0 or index > 5 or not GetIsDoorValid(veh, index) then return end
    if GetVehicleDoorAngleRatio(veh, index) > 0.0 then
        SetVehicleDoorShut(veh, index, false)
    else
        SetVehicleDoorOpen(veh, index, false, false)
    end
end

---@param veh number
---@param index number
local function toggleWindow(veh, index)
    if index < 0 or index > 3 or not GetIsDoorValid(veh, index) then return end
    if IsVehicleWindowIntact(veh, index) then
        RollDownWindow(veh, index)
    else
        RollUpWindow(veh, index)
    end
end

---@param veh number
---@param side string
local function toggleIndicator(veh, side)
    local state = GetVehicleIndicatorLights(veh)
    local left = state == 1 or state == 3
    local right = state == 2 or state == 3

    if side == 'hazard' then
        local value = state ~= 3
        left, right = value, value
    elseif side == 'left' then
        left, right = not left or state == 3, false
    elseif side == 'right' then
        left, right = false, not right or state == 3
    else
        return
    end

    SetVehicleIndicatorLights(veh, 1, left)
    SetVehicleIndicatorLights(veh, 0, right)
end

local ACTIONS = {
    seat = function(veh, value)
        if type(value) == 'number' then setSeat(veh, value) end
    end,
    door = function(veh, value)
        if type(value) == 'number' then toggleDoor(veh, value) end
    end,
    window = function(veh, value)
        if type(value) == 'number' then toggleWindow(veh, value) end
    end,
    indicator = function(veh, value)
        if cache.seat == -1 and type(value) == 'string' then toggleIndicator(veh, value) end
    end,
    interior = function(veh)
        SetVehicleInteriorlight(veh, not IsVehicleInteriorLightOn(veh))
    end,
    engine = function(veh)
        if cache.seat ~= -1 then return notify('Hanya pengemudi yang bisa menyalakan mesin.') end
        if SmVehicleKeys then
            SmVehicleKeys.toggleEngine(veh)
        end
    end,
    closeAll = function(veh)
        SetVehicleDoorsShut(veh, false)
    end,
    pops = function()
        if cache.seat ~= -1 then return notify('Hanya pengemudi yang bisa mengatur Pop & Bang.') end
        if not HRS_TogglePops or not HRS_TogglePops() then
            notify('Kendaraan ini tidak punya Pop & Bang aktif.')
        end
    end,
}

if hasFrame then
    interface.callback('ready', function(_, cb)
        ready = true
        cb({})
        if open and vehicle then
            showMenu()
        end
    end)

    interface.callback('close', function(_, cb)
        cb({})
        close()
    end)

    interface.callback('action', function(data, cb)
        local veh = vehicle
        local handler = type(data) == 'table' and ACTIONS[data.type]
        if not open or not handler or not veh or cache.vehicle ~= veh then
            return cb({ ok = false })
        end

        handler(veh, data.value)
        cb({ ok = true, state = snapshot(veh) })
    end)
end

AddEventHandler('sm_vehcontrol:client:forceClose', function()
    if open then
        send('close')
        close()
    end
end)

RegisterCommand(config.command, function()
    if open then
        send('close')
        return close()
    end
    openMenu()
end, false)

if config.keybind then
    RegisterKeyMapping(config.command, 'Menu kendaraan', 'keyboard', config.keybind)
end
