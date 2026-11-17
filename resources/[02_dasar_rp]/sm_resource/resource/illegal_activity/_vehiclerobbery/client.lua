local HEIST_CAR
local robberyActive = false
local choppingInProgress = false

local stealPoint

local zoneHandle = {}

local blipHandle = {}
local blipModule = require 'modules.blipHandle.client'

local timerDeadline = 0
local timerGeneration = 0
local shared_config = localmodule 'config.shared'

local createTrackerZone, createChoppingZone

local function heistVehicle()
    local v = cache.vehicle
    if not v then return end
    return v == HEIST_CAR and v
end

---@param seconds number
---@return string
local function formatTimeLeft(seconds)
    if seconds <= 0 then return '00 detik' end

    local minutes = seconds // 60
    local rest = seconds % 60

    if minutes > 0 then
        return ('%02d menit %02d detik'):format(minutes, rest)
    end

    return ('%02d detik'):format(rest)
end

---@param seconds number?
local function startHeistTimer(seconds)
    local remaining = seconds or (shared_config.timer.mission * 60)

    timerGeneration = timerGeneration + 1
    local generation = timerGeneration

    timerDeadline = GetGameTimer() + (remaining * 1000)

    CreateThread(function()
        while robberyActive and generation == timerGeneration do
            if choppingInProgress then
                infoUI.remove('vehrob:timer')
                Wait(500)
                goto continue
            end

            local left = (timerDeadline - GetGameTimer()) // 1000

            if left <= 0 then
                local vehicle = HEIST_CAR
                if vehicle and DoesEntityExist(vehicle) then
                    qb_ecore:Notify('Waktu habis! Kendaraan meledak!', 'error')
                    local coords = GetEntityCoords(vehicle)
                    AddExplosion(coords.x, coords.y, coords.z, 0, 10.0, true, false, true)
                end

                infoUI.remove('vehrob:timer')
                TriggerTokenEvent('sm_carheist:server:resetHeist')
                return
            end

            infoUI.show({
                id = 'vehrob:timer',
                title = 'Mission Time',
                icon = 'fa-solid fa-clock',
                description = {
                    ['Waktu tersisa'] = formatTimeLeft(left)
                }
            })

            Wait(500)

            ::continue::
        end

        infoUI.remove('vehrob:timer')
    end)
end

local function stopHeistTimer()
    timerGeneration = timerGeneration + 1
    infoUI.remove('vehrob:timer')
end

---@param seconds number
local function syncHeistTimer(seconds)
    if not robberyActive then return end

    timerDeadline = GetGameTimer() + (seconds * 1000)
end

---@param silent boolean?
local function resetData(silent)
    for k, v in pairs(zoneHandle) do
        if v then pcall(function ()
            v:remove()
        end) zoneHandle[k] = nil end
    end

    for k, v in pairs(blipHandle) do
        if v?.remove then pcall(function ()
            v:remove()
        end) blipHandle[k] = nil end
    end

    stopHeistTimer()

    if robberyActive then
        if not silent then
            qb_ecore:Notify('Carsteal - Kamu kehabisan waktu...', 'error', 10000)
            PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', 1)
        end
        robberyActive = false
    end

    choppingInProgress = false
    HEIST_CAR = nil
    myData = {}

    if garageInteractId then
        exports.rhd_interact:removeCoords(garageInteractId)
        garageInteractId = nil
    end
end

local CHOP_DURATION = 25000

local function breakDoor(vehicle, door)
    SetVehicleDoorOpen(vehicle, door, false, false)
    Wait(500)
    SetVehicleDoorBroken(vehicle, door, true)
end

local function abortChopping(vehicle, message)
    if DoesEntityExist(vehicle) then
        FreezeEntityPosition(vehicle, false)
    end

    choppingInProgress = false
    infoUI.remove('vehrob:chopping')
    qb_ecore:Notify(message, 'error')
end

local function choppingVehicle()
    if choppingInProgress then return end

    local vehicle = heistVehicle()

    if not vehicle or not robberyActive then
        qb_ecore:Notify('Anda harus berada di dalam kendaraan yang dicuri!', 'error')
        return
    end

    local state = Entity(vehicle).state

    if not state.trackerRemoved then
        qb_ecore:Notify('Lepas tracker terlebih dahulu!', 'error')
        return
    end

    choppingInProgress = true

    if not lib.callback.await('sm_carheist:server:beginChop', false) then
        choppingInProgress = false
        qb_ecore:Notify('Tidak bisa memulai chopping saat ini.', 'error')
        return
    end

    stopHeistTimer()

    FreezeEntityPosition(vehicle, true)

    local chopping = true

    CreateThread(function()
        local function step(delay)
            Wait(delay)
            return chopping
        end

        for door = 0, 3 do
            if not step(4000) then return end
            breakDoor(vehicle, door)
        end

        if not step(3000) then return end
        breakDoor(vehicle, 4)
        Wait(1000)
        SetVehicleEngineOn(vehicle, false, true, true)

        for tyre = 0, 3 do
            if not step(2000) then return end
            SetVehicleTyreBurst(vehicle, tyre, true, 1000.0)
        end
    end)

    local success = lib.progressCircle({
        duration = CHOP_DURATION,
        position = 'bottom',
        label = 'Memotong kendaraan...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, mouse = false, combat = true, },
    })

    chopping = false

    if not success then
        abortChopping(vehicle, 'Chopping dibatalkan.')
        TriggerTokenEvent('sm_carheist:server:abortChop')
        startHeistTimer((timerDeadline - GetGameTimer()) // 1000)
        return
    end

    Wait(2000)
    TaskLeaveVehicle(cache.ped, vehicle, 1)

    local timeout = 0
    while GetVehiclePedIsIn(cache.ped, false) == vehicle and timeout < 40 do
        Wait(100)
        timeout = timeout + 1
    end

    local netid = NetworkGetNetworkIdFromEntity(vehicle)
    local ok = lib.callback.await('sm_carheist:server:finishHeist', false, netid)

    infoUI.remove('vehrob:chopping')

    if not ok then
        abortChopping(vehicle, 'Chopping gagal diproses, coba lagi.')
        startHeistTimer((timerDeadline - GetGameTimer()) // 1000)
        return
    end

    stopHeistTimer()

    robberyActive = false
    choppingInProgress = false
end

createChoppingZone = function(coords)
    zoneHandle.chopping = lib.zones.box({
        coords = coords,
        size = vector3(12, 12, 12),
        rotation = coords.w or 0,
        inside = function()
            if choppingInProgress then return end

            if IsControlJustReleased(0, 38) then
                choppingVehicle()
            end
        end,
        onEnter = function()
            if choppingInProgress then return end

            infoUI.show({
                id = 'vehrob:chopping',
                title = 'Lokasi Chopping',
                icon = 'fa-solid fa-screwdriver-wrench',
                description = 'Tekan [kbd]E[/kbd] untuk mulai memotong kendaraan.',
            })
        end,
        onExit = function()
            infoUI.remove('vehrob:chopping')
        end,
    })
end

---@param coords vector4
local function setChoppingStage(coords)
    if zoneHandle.tracker then
        zoneHandle.tracker:remove()
        zoneHandle.tracker = nil
    end

    infoUI.remove('vehrob:tracker')

    blipHandle.mission:setCoords(coords.xyz)
    blipHandle.mission:setLabel('CarSteal | Lokasi Chopping')
    blipHandle.mission:setSprite(315)
    blipHandle.mission:setColor(1)
    blipHandle.mission:setAlpha(200)

    createChoppingZone(coords)
end

createTrackerZone = function(coords)
    zoneHandle.tracker = lib.zones.box({
        coords = coords,
        size = vector3(8, 8, 8),
        rotation = coords.w or 0,
    })

    function zoneHandle.tracker:onEnter()
        infoUI.show({
            id = 'vehrob:tracker',
            title = 'Lepas Tracker',
            icon = 'fa-solid fa-tracker',
            description = 'Tekan [kbd]E[/kbd] untuk melepas tracker.',
        })
    end

    function zoneHandle.tracker:onExit()
        infoUI.remove('vehrob:tracker')
    end

    local removingTracker = false

    function zoneHandle.tracker:inside()
        if removingTracker then return end

        if IsControlJustReleased(0, 38) then
            local vehicle = heistVehicle()

            if not vehicle or not robberyActive then
                qb_ecore:Notify('Anda harus berada di dalam kendaraan yang dicuri!', 'error')
                return
            end

            local state = Entity(vehicle).state

            if state.trackerRemoved then
                qb_ecore:Notify('Tracker sudah dilepas!', 'error')
                return
            end

            removingTracker = true

            local success = lib.progressCircle({
                duration = 15000,
                position = 'bottom',
                label = 'Melepas tracker...',
                useWhileDead = false,
                canCancel = true,
                disable = { move = true, car = true, mouse = false, combat = true, },
            })

            if not success then
                removingTracker = false
                return
            end

            qb_ecore:Notify('Tracker berhasil dilepas! Pergi ke chopping location!', 'success')

            local choppingLoc = shared_config.locations.chopping[myData.choppingIndex]

            setChoppingStage(choppingLoc)
            SetNewWaypoint(choppingLoc.x, choppingLoc.y)

            TriggerTokenEvent('sm_carheist:server:trackerRemoved')
        end
    end
end

RegisterNetEvent('sm_carheist:client:resetHeist', function(silent)
    if source == '' then return end resetData(silent)
end)

RegisterNetEvent('sm_carheist:client:trackerUpdate', function(coords)
    if source == '' then return end

    if blipHandle.policeTracker then
        blipHandle.policeTracker:setCoords(coords)
    else
        blipHandle.policeTracker = blipModule:new({
            coords = coords,
            sprite = 161,
            scale = 1.0,
            color = 1,
            shortRange = false,
            label = 'Car Heist',
        })
    end
end)

RegisterNetEvent('sm_carheist:client:removePoliceTracker', function()
    if source == '' then return end

    if blipHandle.policeTracker then
        blipHandle.policeTracker:remove()
        blipHandle.policeTracker = nil
    end
end)

local function sendDispatch()
    local coords = GetEntityCoords(HEIST_CAR)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)

    local locationText = street2name and (street1name .. " and " .. street2name) or street1name

    local vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(HEIST_CAR))
    local vehicleLabel = GetLabelText(vehicleModel)
    local vehiclePlate = GetVehicleNumberPlateText(HEIST_CAR)

    local policeDispatch = {
        title = 'Car Theft in Progress',
        code = '10-35',
        priority = 'Priority 2',
        message = 'Suspected vehicle theft of a ' .. vehicleLabel .. ' (Plate: ' .. vehiclePlate .. ') at ' .. locationText,
        coords = coords,
        removeTime = 1000 * 60 * 10,
        showTime = 10000,
        jobs = {'police'},
    }

    TriggerTokenEvent('police_alert_carheist:triggerDispatch', policeDispatch)
end

---@param netid number
---@return number? entity
local function awaitHeistCar(netid)
    if not netid or netid == 0 then return end

    local ok, result = pcall(lib.waitFor, function()
        if NetworkDoesEntityExistWithNetworkId(netid) then
            local veh = NetToVeh(netid)
            if veh and veh ~= 0 and DoesEntityExist(veh) then
                return veh
            end
        end
    end, 'Could not load entity in time.', 15000)

    if not ok then return end

    return result
end

---@param netid number
---@param seconds number?
local function initVehicle(netid, seconds)
    HEIST_CAR = awaitHeistCar(netid)

    if not HEIST_CAR then
        qb_ecore:Notify('Gagal memuat kendaraan, coba lagi.', 'error')
        TriggerTokenEvent('sm_carheist:server:resetHeist')
        return
    end

    SetEntityAsMissionEntity(HEIST_CAR, true, true)
    SetVehicleColours(HEIST_CAR, math.random(160), math.random(160))
    SetVehicleDoorsLocked(HEIST_CAR, 1)

    pcall(function ()
        sm_fuel.set(HEIST_CAR, 100)
    end)

    robberyActive = true
    startHeistTimer(seconds)

    qb_ecore:Notify(('Anda menemukan kendaraan yang tepat. Lepas tracker terlebih dahulu! Waktu terbatas: %d menit!'):format(shared_config.timer.mission), 'success', 8000)

    local removeTrackerCoords = shared_config.locations.removeTracker[myData.trackerIndex]

    blipHandle.mission:setCoords(removeTrackerCoords.xyz)
    blipHandle.mission:setLabel('CarSteal | Lepas Tracker')
    blipHandle.mission:setSprite(354)
    blipHandle.mission:setColor(3)
    blipHandle.mission:setAlpha(200)

    SetNewWaypoint(removeTrackerCoords.x, removeTrackerCoords.y)
    createTrackerZone(removeTrackerCoords)
end

---@return boolean
local function preloadHeistModel()
    local model = myData and myData.model
    if not model then return false end

    local hash = type(model) == 'number' and model or joaat(model)

    if HasModelLoaded(hash) then return true end

    if not IsModelValid(hash) and not IsModelInCdimage(hash) then
        qb_ecore:Notify('Kendaraan target tidak tersedia di server, hubungi admin.', 'error')
        return false
    end

    infoUI.show({
        id = 'vehrob:loading',
        title = 'Memuat Kendaraan',
        icon = 'fa-solid fa-spinner',
        description = 'Mohon tunggu, kendaraan sedang dimuat...',
    })

    local waited = 0
    while not HasModelLoaded(hash) and waited < 30000 do
        RequestModel(hash)
        Wait(100)
        waited = waited + 100
    end

    infoUI.remove('vehrob:loading')

    if not HasModelLoaded(hash) then
        qb_ecore:Notify('Kendaraan gagal dimuat (PC/koneksi lambat), coba lagi.', 'error')
        return false
    end

    return true
end

local function enterGarage(coords)
    if garageInteractId then
        exports.rhd_interact:removeCoords(garageInteractId)
        garageInteractId = nil
    end

    if not preloadHeistModel() then
        stealPoint()
        return
    end

    SetEntityHeading(cache.ped, coords.w)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z-1.0)
    Wait(100)

    local offset = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, -1.1, -0.95)
    SetEntityCoords(cache.ped, offset.x, offset.y, offset.z)

    lib.requestAnimDict('anim@apt_trans@garage')
    TaskPlayAnim(cache.ped, 'anim@apt_trans@garage', 'gar_open_1_left', 8.0, -8.0, -1, 02, 0, 0, 0, 0)
    RemoveAnimDict('anim@apt_trans@garage')
    Wait(2000)

    DoScreenFadeOut(500)
    local soundId = GetSoundId()
    PlaySoundFrontend(soundId, 'GARAGE_DOOR_SCRIPTED_OPEN', 0, true)
    ReleaseSoundId(soundId)
    Wait(1000)

    ClearPedTasksImmediately(cache.ped)
    Wait(100)

    local faded = false
    local function fadeInOnce()
        if faded then return end
        faded = true
        DoScreenFadeIn(1000)
    end

    CreateThread(function()
        local waited = 0
        while not faded and waited < 25000 do
            Wait(250)
            waited = waited + 250
        end
        if not faded and IsScreenFadedOut() then
            fadeInOnce()
        end
    end)

    local ok, err = pcall(function()
        local netid, seconds = lib.callback.await('sm_carheist:server:createVehicle', false)

        if not netid then
            qb_ecore:Notify('Gagal memunculkan kendaraan, coba lagi.', 'error')
            TriggerTokenEvent('sm_carheist:server:resetHeist')
            return
        end

        initVehicle(netid, seconds)
        Wait(1000)
        fadeInOnce()

        if HEIST_CAR and DoesEntityExist(HEIST_CAR) then
            sendDispatch()
        end
    end)

    fadeInOnce()

    if not ok then
        print(('^1[vehiclerobbery] enterGarage failed: %s^7'):format(err))
        qb_ecore:Notify('Terjadi kesalahan saat mengambil kendaraan.', 'error')
        TriggerTokenEvent('sm_carheist:server:resetHeist')
    end
end

stealPoint = function()
    if not myData then
        return
    end

    local model,
          vehicleIndex,
          locationIndex in myData

    local label = GetLabelText(GetDisplayNameFromVehicleModel(model))

    local location = shared_config.locations.pickup[locationIndex].enter
    local coords = vector4(location.x, location.y, location.z, location.w or 0)

    if blipHandle.mission then
        blipHandle.mission:remove()
    end

    blipHandle.mission = blipModule:new({
        coords = coords.xyz,
        sprite = 66,
        scale = 0.8,
        color = 5,
        shortRange = true,
        label = 'CarSteal | Ambil Kendaraan',
    })

    PlaySoundFrontend(-1, 'Text_Arrive_Tone', 'Phone_SoundSet_Default', 1)
    local vehicleTypeText = vehicleIndex == 1 and 'mobil' or 'motor'
    qb_ecore:Notify(('Anda perlu mengambil %s (%s). Itu telah ditandai di GPS Anda.'):format(label, vehicleTypeText), 'success')

    SetNewWaypoint(coords.x, coords.y)
    garageInteractId = exports.rhd_interact:addCoords({
        coords = coords.xyz,
        options = {
            {
                label = 'Enter Garage',
                icon = 'fa-solid fa-circle',
                name = 'garage_enter',
                distance = 2.5,
                onSelect = function(data)
                    enterGarage(coords)
                end,
            }
        }
    })
end

local pedModule = require 'modules.pedHandle.client'

CreateThread(function ()
    local ped_data = shared_config.ped

    ped_data.target = {
        {
            label = 'Mulai Carheist',
            icon = 'fa-solid fa-square-check',
            distance = 1.3,
            onSelect = function(data)
                local START_PED = data.entity
                TaskStartScenarioInPlace(START_PED, 'WORLD_HUMAN_STAND_MOBILE', 0, true)

                if lib.progressBar({
                    duration = 3000,
                    label = 'Berbicara dengan kontak...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                    },
                    anim = {
                        dict = 'mp_common',
                        clip = 'givetake1_a'
                    },
                }) then

                    ClearPedTasksImmediately(START_PED)
                    TaskStartScenarioInPlace(START_PED, 'WORLD_HUMAN_SMOKING_POT', 0, true)

                    local vehData = lib.callback.await('sm_carheist:attemptjob', false)

                    if not (vehData and type(vehData) == "table") then
                        return
                    end

                    myData = vehData
                    stealPoint()
                else
                    ClearPedTasksImmediately(START_PED)
                    TaskStartScenarioInPlace(START_PED, 'WORLD_HUMAN_SMOKING_POT', 0, true)
                end
            end
        }
    }

    pedModule:new(ped_data)
end)

RegisterNetEvent('sm_carheist:client:syncTimer', function(seconds)
    if source == '' then return end
    if type(seconds) ~= 'number' then return end

    syncHeistTimer(seconds)
end)
