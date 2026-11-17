local cfg = localmodule('config.shared')

interface.init(false)

local meterRunning    = false
local isPaused        = false
local fare            = cfg.baseFare
local distance        = 0.0
local lastPos         = nil
local isDriver        = false
local inTaxi          = false
local history         = {}
local meterLoopActive = false
local lastCorrection  = 0
local currentVehicle  = nil
local tripData        = {}
local frameShown      = false
local frameToken      = 0

local function isTaxiModel(vehicle)
    local model = GetEntityModel(vehicle)
    for _, m in ipairs(cfg.taxiModels) do
        if model == GetHashKey(m) then return true end
    end
    return false
end

local function sendUI(data)
    if not frameShown then return end
    interface.send(data)
end

local function openFrame()
    frameToken += 1
    if frameShown then return end

    frameShown = true
    interface.show()
    sendUI({ action = 'updateHistory', history = history })
end

local function closeFrame()
    if not frameShown then return end

    sendUI({ action = 'ui', status = false })
    frameShown = false
    frameToken += 1
    local token = frameToken

    SetTimeout(400, function()
        if token == frameToken and not frameShown then
            interface.hide()
        end
    end)
end

local function setMeterState(vehicle, state)
    Entity(vehicle).state:set('taxiMeter', state, true)
end

local function addToHistory()
    if fare > cfg.baseFare and distance > 0 then
        if #history >= cfg.maxHistory then table.remove(history, 1) end
        table.insert(history, { fare = fare, distance = distance })
        sendUI({ action = 'updateHistory', history = history })
    end
end

local function runMeterLoop()
    if meterLoopActive then return end
    meterLoopActive = true

    CreateThread(function()
        while meterRunning do
            if not isPaused then
                local veh = GetVehiclePedIsIn(cache.ped, false)
                if veh ~= 0 then
                    local pos = GetEntityCoords(veh)
                    if lastPos then
                        local dist = #(pos - lastPos)
                        distance = distance + dist
                        fare     = fare + (dist * cfg.fareRate)
                        sendUI({ action = 'update', fare = fare, distance = distance })
                    end
                    lastPos = pos

                    if isDriver then
                        local now = GetGameTimer()
                        if now - lastCorrection > 10000 then
                            lastCorrection = now
                            Entity(veh).state:set('taxiMeterData', {
                                fare     = fare,
                                distance = distance
                            }, true)
                        end
                    end
                end
            end
            Wait(1000)
        end
        meterLoopActive = false
    end)
end

local function applyMeterState(state)
    if not state then
        if meterRunning then addToHistory() end
        meterRunning = false
        isPaused     = false
        fare         = cfg.baseFare
        distance     = 0.0
        lastPos      = nil
        sendUI({ action = 'update', fare = fare, distance = distance })
        sendUI({ action = 'setActive', button = '' })
        return
    end

    if state.cmd == 'start' then
        meterRunning = true
        isPaused     = false
        fare         = cfg.baseFare
        distance     = 0.0
        local veh    = GetVehiclePedIsIn(cache.ped, false)
        lastPos      = veh ~= 0 and GetEntityCoords(veh) or nil
        sendUI({ action = 'update', fare = fare, distance = distance })
        sendUI({ action = 'setActive', button = 'start' })
        runMeterLoop()
    elseif state.cmd == 'pause' then
        isPaused = true
        lastPos  = nil
        sendUI({ action = 'setActive', button = 'pause' })
    elseif state.cmd == 'resume' then
        isPaused = false
        local veh = GetVehiclePedIsIn(cache.ped, false)
        lastPos   = veh ~= 0 and GetEntityCoords(veh) or nil
        sendUI({ action = 'setActive', button = 'start' })
    end
end

local function clearLocalState()
    meterRunning = false
    isPaused     = false
    fare         = cfg.baseFare
    distance     = 0.0
    lastPos      = nil
end

AddStateBagChangeHandler('taxiMeter', nil, function(bagName, _, value)
    if isDriver then return end

    local veh = GetVehiclePedIsIn(cache.ped, false)
    if veh == 0 then return end

    local netId = tonumber(bagName:gsub('entity:', ''), 10)
    if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then return end

    if veh ~= NetworkGetEntityFromNetworkId(netId) then return end

    applyMeterState(value)
end)

AddStateBagChangeHandler('taxiMeterData', nil, function(bagName, _, value)
    if isDriver or not value then return end

    local veh = GetVehiclePedIsIn(cache.ped, false)
    if veh == 0 then return end

    local netId = tonumber(bagName:gsub('entity:', ''), 10)
    if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then return end

    if veh ~= NetworkGetEntityFromNetworkId(netId) then return end

    fare     = value.fare
    distance = value.distance
    sendUI({ action = 'update', fare = fare, distance = distance })
end)

local function startMeter()
    if not inTaxi or not isDriver then
        return lib.notify({ description = 'Kamu harus menjadi pengemudi taksi!', type = 'error' })
    end
    if meterRunning then return end

    applyMeterState({ cmd = 'start' })
    setMeterState(currentVehicle, { cmd = 'start' })
    lib.notify({ description = 'Meteran Taksi Dimulai!', type = 'success' })
end

local function togglePause()
    if not meterRunning then return end

    if isPaused then
        applyMeterState({ cmd = 'resume' })
        if currentVehicle ~= 0 then setMeterState(currentVehicle, { cmd = 'resume' }) end
        lib.notify({ description = 'Meteran Dilanjutkan!', type = 'success' })
    else
        applyMeterState({ cmd = 'pause' })
        if currentVehicle ~= 0 then setMeterState(currentVehicle, { cmd = 'pause' }) end
        lib.notify({ description = 'Meteran Dijeda!', type = 'inform' })
    end
end

local function resetMeter()
    applyMeterState(nil)
    if currentVehicle and currentVehicle ~= 0 and isDriver then
        if DoesEntityExist(currentVehicle) then
            Entity(currentVehicle).state:set('taxiMeter', nil, true)
            Entity(currentVehicle).state:set('taxiMeterData', nil, true)
        end
    end
end

local function restoreMeter(vehicle)
    local data = Entity(vehicle).state.taxiMeterData
    if data then
        fare     = data.fare
        distance = data.distance
        sendUI({ action = 'update', fare = fare, distance = distance })
    end

    local state = Entity(vehicle).state.taxiMeter
    if state then
        meterRunning = true
        isPaused     = state.cmd == 'pause'
        lastPos      = not isPaused and GetEntityCoords(vehicle) or nil
        sendUI({ action = 'setActive', button = isPaused and 'pause' or 'start' })
        runMeterLoop()
    end
end

lib.onCache('vehicle', function(vehicle)
    if vehicle and isTaxiModel(vehicle) then
        currentVehicle = vehicle
        inTaxi   = true
        isDriver = GetPedInVehicleSeat(vehicle, -1) == cache.ped
        openFrame()
        sendUI({ action = 'ui', status = true })
        restoreMeter(vehicle)
    else
        if inTaxi and isDriver and meterRunning and currentVehicle then
            if DoesEntityExist(currentVehicle) then
                isPaused = true
                lastPos  = nil
                meterRunning = false
                setMeterState(currentVehicle, { cmd = 'pause' })
                Entity(currentVehicle).state:set('taxiMeterData', {
                    fare     = fare,
                    distance = distance
                }, true)
            end
        else
            clearLocalState()
        end

        currentVehicle = nil
        inTaxi   = false
        isDriver = false
        closeFrame()
    end
end)

AddEventHandler('qb-taxi:startmeter', startMeter)
AddEventHandler('qb-taxi:pausemeter', togglePause)

AddEventHandler('qb-taxi:resetmeter', function()
    if not inTaxi or not isDriver then return end
    resetMeter()
end)

AddEventHandler('qb-taxi:startTaxiRide', function()
    TriggerEvent('sm_taxi:startRide')
end)

local function getNearbyPlayers(radius)
    local origin = GetEntityCoords(cache.ped)
    local result = {}
    for _, player in ipairs(GetActivePlayers()) do
        local target = GetPlayerPed(player)
        if target ~= cache.ped and #(origin - GetEntityCoords(target)) <= radius then
            table.insert(result, {
                label = 'ID: ' .. GetPlayerServerId(player),
                value = tostring(GetPlayerServerId(player))
            })
        end
    end
    return result
end

local function setDestinationBlip(coords)
    if tripData.blip then RemoveBlip(tripData.blip) end
    tripData.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipRoute(tripData.blip, true)
    SetBlipSprite(tripData.blip, 1)
    SetBlipColour(tripData.blip, 2)
    SetBlipScale(tripData.blip, 1.0)
    SetBlipRouteColour(tripData.blip, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Tujuan Taksi')
    EndTextCommandSetBlipName(tripData.blip)
end

AddEventHandler('sm_taxi:startRide', function()
    local veh = GetVehiclePedIsIn(cache.ped, false)

    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= cache.ped or not isTaxiModel(veh) then
        return lib.notify({ description = 'Kamu harus menjadi pengemudi taksi!', type = 'error' })
    end

    local nearby = getNearbyPlayers(5.0)
    if #nearby == 0 then
        return lib.notify({ description = 'Tidak ada penumpang di sekitar!', type = 'error' })
    end

    local input = lib.inputDialog('Pilih Penumpang', {
        { type = 'select', label = 'ID Penumpang', options = nearby }
    })

    if input and input[1] then
        TriggerTokenEvent('sm_taxi:requestRide', tonumber(input[1]))
        lib.notify({ description = 'Permintaan terkirim!', type = 'inform' })
    end
end)

RegisterNetEvent('sm_taxi:receiveRequest', function(driverSrc)
    lib.registerContext({
        id    = 'taxi_offer',
        title = 'Tawaran Taksi',
        options = {
            { title = 'Terima', icon = 'check', event = 'sm_taxi:acceptRide', args = driverSrc },
            { title = 'Tolak',  icon = 'xmark' },
        }
    })
    lib.showContext('taxi_offer')
end)

RegisterNetEvent('sm_taxi:acceptRide', function(driverSrc)
    TriggerServerEvent('sm_taxi:confirmRide', driverSrc)
end)

RegisterNetEvent('sm_taxi:beginRide', function()
    lib.notify({ description = 'Penumpang setuju. Set waypoint ke tujuan!', type = 'inform' })

    CreateThread(function()
        while true do
            Wait(1000)
            local waypoint = GetFirstBlipInfoId(8)
            if DoesBlipExist(waypoint) then
                TriggerTokenEvent('sm_taxi:setDestination', GetBlipCoords(waypoint))
                break
            end
        end
    end)
end)

RegisterNetEvent('sm_taxi:receiveDestination', function(coords)
    local ok, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)
    tripData.dest = ok and vector3(coords.x, coords.y, groundZ) or vector3(coords.x, coords.y, coords.z)

    setDestinationBlip(tripData.dest)
    lib.notify({ description = 'Perjalanan dimulai! Ikuti rute.', type = 'success' })

    CreateThread(function()
        while tripData.dest do
            Wait(1000)
            local pos = GetEntityCoords(cache.ped)
            if #(pos.xy - tripData.dest.xy) < 25.0 then
                TriggerTokenEvent('sm_taxi:completeRide')
                RemoveBlip(tripData.blip)
                tripData = {}
                break
            end
        end
    end)
end)