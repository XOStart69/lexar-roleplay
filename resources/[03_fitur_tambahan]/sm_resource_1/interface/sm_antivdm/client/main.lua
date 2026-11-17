local config = localmodule 'config.shared'

local GetGameTimer = GetGameTimer
local IsEntityAVehicle = IsEntityAVehicle
local IsEntityAPed = IsEntityAPed
local IsPedAPlayer = IsPedAPlayer
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehiclePedIsIn = GetVehiclePedIsIn
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local GetPlayerServerId = GetPlayerServerId
local TriggerServerEvent = TriggerServerEvent

local reportCooldown = config.reportCooldown
local maxWarnings = config.maxWarnings
local warnDuration = config.warnDuration
local finalDuration = config.finalDuration

local vehicleWeapons = {}
for _, name in ipairs({ 'WEAPON_RUN_OVER_BY_CAR', 'WEAPON_RAMMED_BY_CAR' }) do
    local hash = joaat(name)
    local signed = hash > 0x7FFFFFFF and hash - 0x100000000 or hash
    vehicleWeapons[signed] = true
    vehicleWeapons[signed % 0x100000000] = true
end

local lastReport = {}
local payload = { action = 'warn', title = 'You received a VDM warning', max = maxWarnings }
local mounted = false
local frameReady = false
local pending = false
local generation = 0

CreateThread(function()
    while not interface.ready() do
        Wait(100)
    end
    interface.init(false)
end)

interface.callback('ready', function(_, cb)
    cb(true)
    frameReady = true
    if pending then
        pending = false
        interface.send(payload)
    end
end)

---@param count number
local function showWarning(count)
    local final = count >= maxWarnings
    local duration = final and finalDuration or warnDuration

    payload.count = count
    payload.duration = duration
    payload.description = final and 'Limit reached, this violation has been reported to the admins' or 'Do not hit other players with your vehicle'

    generation = generation + 1
    local current = generation

    if frameReady then
        interface.send(payload)
    else
        pending = true
        if not mounted then
            mounted = true
            interface.show()
        end
    end

    SetTimeout(duration + 400, function()
        if current ~= generation then return end
        mounted = false
        frameReady = false
        pending = false
        interface.hide()
    end)
end

RegisterNetEvent('sm_antivdm:client:warn', function(count)
    if type(count) ~= 'number' then return end
    showWarning(count)
end)

---@param attacker number
---@return number?
local function resolveDriver(attacker)
    if IsEntityAVehicle(attacker) then
        return GetPedInVehicleSeat(attacker, -1)
    end

    if IsEntityAPed(attacker) and GetVehiclePedIsIn(attacker, false) ~= 0 then
        return attacker
    end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local ped = cache.ped
    if args[1] ~= ped or cache.vehicle or not vehicleWeapons[args[7]] then return end

    local attacker = args[2]
    if not attacker or attacker == 0 then return end

    local driver = resolveDriver(attacker)
    if not driver or driver == 0 or driver == ped or not IsPedAPlayer(driver) then return end

    local playerIndex = NetworkGetPlayerIndexFromPed(driver)
    if playerIndex == -1 then return end

    local serverId = GetPlayerServerId(playerIndex)
    if serverId <= 0 then return end

    local now = GetGameTimer()
    local last = lastReport[serverId]
    if last and now - last < reportCooldown then return end
    lastReport[serverId] = now

    TriggerServerEvent('sm_antivdm:server:report', serverId)
end)
