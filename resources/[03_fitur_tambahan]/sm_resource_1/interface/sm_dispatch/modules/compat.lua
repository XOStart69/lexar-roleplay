local Compat = {}

local exportWrapper = require 'export_wrapper'

local ctx

---@param message string
---@param code string
---@param priority string
---@param jobs string[]
---@param includeVehicle boolean?
---@param includeWeapon boolean?
---@param includeHeading boolean?
---@return function
local function makeAlert(message, code, priority, jobs, includeVehicle, includeWeapon, includeHeading)
    return function()
        ctx.addCall({
            title = message,
            code = code,
            priority = priority,
            jobs = jobs,
            coords = ctx.cache.coords,
            showLocation = true,
            showGender = true,
            showVehicle = includeVehicle or nil,
            showWeapon = includeWeapon or nil,
            showDirection = includeHeading or nil,
            playSound = true,
            blip = { color = 3, sprite = 110, scale = 1.0, radius = 40.0 },
        })
    end
end

local PS_ALERTS = {
    { 'VehicleTheft', 'VehicleTheft', '10-35', 'Priority 2', { 'leo' }, true },
    { 'Shooting', 'Shooting', '10-11', 'Priority 2', { 'leo' }, true },
    { 'Hunting', 'Hunting', '10-13', 'Priority 2', { 'leo' }, true },
    { 'VehicleShooting', 'Shooting', '10-60', 'Priority 2', { 'leo' }, true, true, true },
    { 'SpeedingVehicle', 'Speeding', '10-11', 'Priority 2', { 'leo' }, true, nil, true },
    { 'Fight', 'Fighting', '10-10', 'Priority 2', { 'leo' } },
    { 'PrisonBreak', 'PrisonBreak', '10-90', 'Priority 2', { 'leo' } },
    { 'StoreRobbery', 'StoreRobbery', '10-90', 'Priority 2', { 'leo' } },
    { 'FleecaBankRobbery', 'BankRobbery', '10-90', 'Priority 2', { 'leo' } },
    { 'PaletoBankRobbery', 'BankRobbery', '10-90', 'Priority 2', { 'leo' } },
    { 'PacificBankRobbery', 'BankRobbery', '10-90', 'Priority 2', { 'leo' } },
    { 'VangelicoRobbery', 'VangelicoRobbery', '10-90', 'Priority 2', { 'leo' } },
    { 'HouseRobbery', 'HouseRobbery', '10-90', 'Priority 2', { 'leo' } },
    { 'YachtHeist', 'YachtHeist', '10-65', 'Priority 2', { 'leo' } },
    { 'DrugSale', 'DrugSale', '10-13', 'Priority 2', { 'leo' } },
    { 'SuspiciousActivity', 'SuspiciousActivity', '10-66', 'Priority 2', { 'leo' } },
    { 'CarJacking', 'CarJacking', '10-35', 'Priority 2', { 'leo' } },
    { 'InjuriedPerson', 'InjuredPerson', '10-69', 'Priority 1', { 'ems' } },
    { 'DeceasedPerson', 'DeceasedPerson', '10-69', 'Priority 1', { 'ems' } },
    { 'OfficerDown', 'OfficerDown', '10-99', 'Priority 1', { 'ems', 'leo' } },
    { 'OfficerBackup', 'OfficerBackup', '10-32', 'Priority 1', { 'ems', 'leo' } },
    { 'OfficerInDistress', 'OfficerInDistress', '10-99', 'Priority 1', { 'ems', 'leo' } },
    { 'EmsDown', 'EMSDown', '10-99', 'Priority 1', { 'ems', 'leo' } },
    { 'Explosion', 'Explosion', '10-80', 'Priority 2', { 'leo' } },
}

---@param data table
local function psCustomAlert(data)
    if not data then return end

    local alert = data.alert

    ctx.addCall({
        title = data.message,
        code = data.code,
        priority = data.priority,
        coords = data.coords or ctx.cache.coords,
        location = data.street,
        gender = data.gender,
        weapon = data.weapon,
        direction = data.heading,
        vehicle = data.vehicle and {
            model = data.vehicle,
            plate = data.plate,
            color = data.color,
        } or nil,
        showTime = data.alertTime,
        jobs = data.jobs,
        blip = alert and {
            sprite = alert.sprite,
            color = alert.color,
            scale = alert.scale,
            flash = alert.flash,
            radius = alert.radius,
        } or nil,
    })
end

---@return table
local function getPlayerInfo()
    local data = ctx.buildPlayerData()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    local speed, heading

    if DoesEntityExist(vehicle) then
        speed = ('%d mph'):format(math.floor(GetEntitySpeed(vehicle) * 2.236936))
        heading = data.direction
    end

    local vehicleData = data.vehicle

    return {
        ped = ped,
        coords = coords,
        street = data.location,
        street_1 = data.location,
        street_2 = data.location,
        sex = data.gender,
        vehicle = vehicle,
        vehicle_label = vehicleData and vehicleData.model,
        vehicle_colour = vehicleData and vehicleData.color,
        vehicle_plate = vehicleData and vehicleData.plate,
        heading = heading,
        speed = speed,
    }
end

---@param context table
function Compat.register(context)
    ctx = context

    exportWrapper('ps-dispatch', 'CustomAlert', psCustomAlert)

    for i = 1, #PS_ALERTS do
        local entry = PS_ALERTS[i]
        exportWrapper('ps-dispatch', entry[1], makeAlert(entry[2], entry[3], entry[4], entry[5], entry[6], entry[7], entry[8]))
    end

    exportWrapper('cd_dispatch', 'GetPlayerInfo', getPlayerInfo)
    exportWrapper('qs-dispatch', 'GetPlayerInfo', getPlayerInfo)
end

return Compat
