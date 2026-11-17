local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'
local infoui = exports.rhd_infoui

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetEntityModel = GetEntityModel
local GetVehicleClass = GetVehicleClass
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetVehicleDoorLockStatus = GetVehicleDoorLockStatus
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetVehiclePedIsTryingToEnter = GetVehiclePedIsTryingToEnter
local GetVehicleModelNumberOfSeats = GetVehicleModelNumberOfSeats
local GetIsVehicleEngineRunning = GetIsVehicleEngineRunning
local GetEntityPlayerIsFreeAimingAt = GetEntityPlayerIsFreeAimingAt
local GetCurrentPedWeapon = GetCurrentPedWeapon
local GetWeapontypeGroup = GetWeapontypeGroup
local GetPlayerServerId = GetPlayerServerId
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local SetVehicleEngineOn = SetVehicleEngineOn
local DisableControlAction = DisableControlAction
local IsThisModelAHeli = IsThisModelAHeli
local IsThisModelAPlane = IsThisModelAPlane
local DoesEntityExist = DoesEntityExist
local IsEntityAPed = IsEntityAPed
local IsEntityDead = IsEntityDead
local IsPedAPlayer = IsPedAPlayer
local IsPedInAnyVehicle = IsPedInAnyVehicle
local PlayerId = PlayerId
local VehToNet = VehToNet
local Entity = Entity
local type = type
local tostring = tostring
local random = math.random
local smatch = string.match
local supper = string.upper

local LOCK_DISTANCE = config.lockDistance
local GIVE_DISTANCE = config.giveDistance
local LOCK_ANIM = config.lockAnim
local PICK = config.lockpick
local CARJACK = config.carjack
local NO_LOCK_CLASSES = config.noLockClasses
local INFO_ID = 'sm_vehiclekeys:hotwire'
local HOTWIRE_ANIM = { dict = 'veh@break_in@0h@p_m_one@', clip = 'low_force_entry_ds', flag = 16 }

---@type table<string, true>
local keys = {}
local guardVehicle = nil
local hotwireActive = false
local pickBusy = false
local carjackBusy = false
local nextCarjackAt = 0

local immune = {}
for i = 1, #config.immuneModels do
    immune[joaat(config.immuneModels[i])] = true
end

local noLock = {}
for i = 1, #config.noLockModels do
    noLock[joaat(config.noLockModels[i])] = true
end

local blockedWeapons = {}
for i = 1, #CARJACK.blockedWeapons do
    blockedWeapons[joaat(CARJACK.blockedWeapons[i])] = true
end

local sharedModels = {}
for job, data in pairs(config.sharedKeys) do
    local models = {}
    for i = 1, #data.models do
        models[joaat(data.models[i])] = true
    end
    sharedModels[job] = { requireOnduty = data.requireOnduty, models = models }
end

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = 'Kunci Kendaraan', description = description, type = kind or 'error' })
end

---@param plate any
---@return string?
local function trimPlate(plate)
    if type(plate) ~= 'string' then return end
    plate = smatch(plate, '^%s*(.-)%s*$')
    if plate == '' then return end
    return supper(plate)
end

---@param vehicle number
---@return string?
local function plateOf(vehicle)
    return trimPlate(GetVehicleNumberPlateText(vehicle))
end

---@param plate any
---@return boolean
local function hasKeys(plate)
    plate = trimPlate(plate)
    return plate ~= nil and keys[plate] == true
end

---@param vehicle number
---@return boolean
local function ignoresLocks(vehicle)
    return NO_LOCK_CLASSES[GetVehicleClass(vehicle)] == true or noLock[GetEntityModel(vehicle)] == true or Entity(vehicle).state.ignoreLocks == true
end

---@param vehicle number
---@return boolean
local function isShared(vehicle)
    local job = QBPlayerData.job
    local shared = job and sharedModels[job.name]
    if not shared or (shared.requireOnduty and not job.onduty) then return false end
    return shared.models[GetEntityModel(vehicle)] == true
end

---@param vehicle number
---@return boolean
local function canUse(vehicle)
    return not NetworkGetEntityIsNetworked(vehicle) or ignoresLocks(vehicle) or hasKeys(plateOf(vehicle)) or isShared(vehicle)
end

---@return boolean
local function isDown()
    local meta = QBPlayerData.metadata
    return meta ~= nil and (meta.isdead or meta.inlaststand) or false
end

---@param vehicle number
---@return number?
local function netIdOf(vehicle)
    if vehicle and DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle) then
        return VehToNet(vehicle)
    end
end

---@param distance number
---@return number?
local function nearbyVehicle(distance)
    if cache.vehicle then return cache.vehicle end
    return lib.getClosestVehicle(GetEntityCoords(cache.ped), distance, false)
end

---@param vehicle number
---@return boolean
local function toggleEngine(vehicle)
    if not canUse(vehicle) then
        notify('Kamu tidak punya kunci kendaraan ini.')
        return false
    end
    SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
    return true
end

SmVehicleKeys = {
    canUse = canUse,
    hasKeys = hasKeys,
    toggleEngine = toggleEngine,
}

local hotwireBind

local function stopGuard()
    if not guardVehicle then return end
    guardVehicle = nil
    hotwireBind:disable(true)
    infoui:remove(INFO_ID)
end

---@param vehicle number
local function startGuard(vehicle)
    if guardVehicle == vehicle then return end
    guardVehicle = vehicle
    hotwireBind:disable(false)
    infoui:show({
        id = INFO_ID,
        title = 'Tidak ada kunci',
        icon = 'fa-solid fa-key',
        description = ('[kbd]%s[/kbd] Cari kunci'):format(config.hotwireKey),
    })

    local model = GetEntityModel(vehicle)
    if IsThisModelAHeli(model) or IsThisModelAPlane(model) then
        CreateThread(function()
            while guardVehicle == vehicle do
                DisableControlAction(0, 87, true)
                DisableControlAction(0, 88, true)
                Wait(0)
            end
        end)
    end

    CreateThread(function()
        while guardVehicle == vehicle do
            if DoesEntityExist(vehicle) and canUse(vehicle) then
                stopGuard()
                SetVehicleEngineOn(vehicle, true, false, true)
            elseif not hotwireActive and DoesEntityExist(vehicle) and GetIsVehicleEngineRunning(vehicle) then
                SetVehicleEngineOn(vehicle, false, true, true)
            end
            Wait(250)
        end
    end)
end

local function refreshDriverState()
    local vehicle = cache.vehicle
    if vehicle and cache.seat == -1 and not canUse(vehicle) then
        startGuard(vehicle)
    else
        stopGuard()
    end
end

local function startHotwire()
    local vehicle = guardVehicle
    if not vehicle or hotwireActive or isDown() then return end

    local netId = netIdOf(vehicle)
    if not netId then return end

    hotwireActive = true
    CreateThread(function()
        local duration, reason = lib.callback.await('sm_vehiclekeys:hotwireStart', false, netId)
        if not duration then
            hotwireActive = false
            if reason == 'blocked' then
                notify('Kendaraan ini tidak bisa dibobol, harus diberi kunci.')
            end
            return
        end

        SetVehicleAlarm(vehicle, true)
        SetVehicleAlarmTimeLeft(vehicle, duration)

        local done = lib.progressBar({
            duration = duration,
            label = 'Mencari kunci kendaraan...',
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = HOTWIRE_ANIM,
        })

        local success = lib.callback.await('sm_vehiclekeys:hotwireFinish', false, not done)
        if done then
            TriggerTokenEvent('sm_hud:server:addStress', random(1, 4))
            if not success then
                notify('Kamu gagal menemukan kunci.')
            end
        end
        hotwireActive = false
    end)
end

hotwireBind = lib.addKeybind({
    name = 'hotwire',
    description = 'Cari kunci kendaraan',
    defaultKey = config.hotwireKey,
    disabled = true,
    onPressed = startHotwire,
})

local function refreshKeys()
    local list = lib.callback.await('sm_vehiclekeys:list', false)
    keys = type(list) == 'table' and list or {}
    refreshDriverState()
end

---@param plate string
---@return number?
local function findVehicleByPlate(plate)
    local current = cache.vehicle
    if current and plateOf(current) == plate then return current end

    local coords = GetEntityCoords(cache.ped)
    local pool = GetGamePool('CVehicle')
    local best, bestDistance = nil, math.huge
    for i = 1, #pool do
        local vehicle = pool[i]
        if plateOf(vehicle) == plate then
            local distance = #(coords - GetEntityCoords(vehicle))
            if distance < bestDistance then
                best, bestDistance = vehicle, distance
            end
        end
    end
    return best
end

RegisterNetEvent('sm_vehiclekeys:client:setVehicleOwner', function(plate)
    plate = trimPlate(plate)
    if not plate or keys[plate] then return end

    for _ = 1, 15 do
        local netId = netIdOf(findVehicleByPlate(plate))
        if netId then
            return TriggerTokenEvent('sm_vehiclekeys:server:claim', netId, plate)
        end
        Wait(200)
    end
end)

RegisterNetEvent('sm_vehiclekeys:client:AddKeys', function(plate)
    plate = trimPlate(plate)
    if not plate then return end
    keys[plate] = true

    local vehicle = guardVehicle
    if vehicle and plateOf(vehicle) == plate then
        stopGuard()
        SetVehicleEngineOn(vehicle, true, false, true)
    end
end)

RegisterNetEvent('sm_vehiclekeys:client:RemoveKeys', function(plate)
    plate = trimPlate(plate)
    if not plate then return end
    keys[plate] = nil
    refreshDriverState()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(refreshKeys)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    keys = {}
    stopGuard()
end)

CreateThread(function()
    if LocalPlayer.state.isLoggedIn then
        refreshKeys()
    end
end)

lib.onCache('seat', function()
    SetTimeout(0, refreshDriverState)
end)

lib.onCache('vehicle', function()
    SetTimeout(0, refreshDriverState)
end)

---@return number
local function attachFob()
    if not pcall(lib.requestModel, LOCK_ANIM.prop, 1000) then return 0 end
    local ped = cache.ped
    local object = CreateObject(joaat(LOCK_ANIM.prop), 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(joaat(LOCK_ANIM.prop))
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, LOCK_ANIM.bone), 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    return object
end

---@param vehicle number
local function flashLights(vehicle)
    StartVehicleHorn(vehicle, 150, `HELDDOWN`, false)
    SetVehicleLights(vehicle, 2)
    Wait(250)
    SetVehicleLights(vehicle, 1)
    Wait(200)
    SetVehicleLights(vehicle, 0)
end

RegisterKeyMapping('togglelocks', 'Kunci / buka kendaraan', 'keyboard', config.lockKey)
RegisterCommand('togglelocks', function()
    if isDown() then return end

    local vehicle = nearbyVehicle(LOCK_DISTANCE)
    if not vehicle or ignoresLocks(vehicle) then return end

    local netId = netIdOf(vehicle)
    if not netId then return end

    CreateThread(function()
        local ped = cache.ped
        local onFoot = not cache.vehicle and canUse(vehicle)
        local fob = 0

        local startedAt = GetGameTimer()
        if onFoot and pcall(lib.requestAnimDict, LOCK_ANIM.dict, 1000) then
            fob = attachFob()
            TaskPlayAnim(ped, LOCK_ANIM.dict, LOCK_ANIM.clip, 3.0, 3.0, -1, 48, 0, false, false, false)
            RemoveAnimDict(LOCK_ANIM.dict)
        end

        local wanted = GetVehicleDoorLockStatus(vehicle) >= 2 and 1 or 2
        local state = lib.callback.await('sm_vehiclekeys:toggleLock', false, netId, wanted)

        if state == 1 or state == 2 then
            SetVehicleDoorsLocked(vehicle, state)
            if state == 1 then
                SetVehicleNeedsToBeHotwired(vehicle, false)
            end
        end

        if onFoot then
            local remaining = LOCK_ANIM.duration - (GetGameTimer() - startedAt)
            if remaining > 0 then
                Wait(remaining)
            end
            if fob ~= 0 and DoesEntityExist(fob) then
                DeleteEntity(fob)
            end
        end

        if state == 2 then
            notify('Kendaraan dikunci.', 'inform')
            flashLights(vehicle)
        elseif state == 1 then
            notify('Kendaraan dibuka.', 'success')
            flashLights(vehicle)
        else
            notify('Kamu tidak punya kunci kendaraan ini.')
        end
    end)
end, false)

RegisterKeyMapping('engine', 'Nyalakan / matikan mesin', 'keyboard', config.engineKey)
RegisterCommand('engine', function()
    local vehicle = cache.vehicle
    if not vehicle or cache.seat ~= -1 or isDown() then return end
    toggleEngine(vehicle)
end, false)

RegisterNetEvent('sm_vehiclekeys:client:give', function(target)
    if source == '' then return end

    local vehicle = nearbyVehicle(LOCK_DISTANCE)
    local netId = vehicle and netIdOf(vehicle)
    if not netId then return notify('Tidak ada kendaraan di dekatmu.') end
    if not hasKeys(plateOf(vehicle)) then return notify('Kamu tidak punya kunci kendaraan ini.') end

    local targets = {}
    if type(target) == 'number' then
        targets[1] = target
    elseif cache.vehicle then
        local ped = cache.ped
        for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
            local other = GetPedInVehicleSeat(vehicle, seat)
            if other ~= 0 and other ~= ped and IsPedAPlayer(other) then
                targets[#targets + 1] = GetPlayerServerId(NetworkGetPlayerIndexFromPed(other))
            end
        end
    else
        local player = lib.getClosestPlayer(GetEntityCoords(cache.ped), GIVE_DISTANCE, false)
        if player then
            targets[1] = GetPlayerServerId(player)
        end
    end

    if #targets == 0 then return notify('Tidak ada orang di dekatmu untuk diberi kunci.') end
    TriggerTokenEvent('sm_vehiclekeys:server:give', netId, targets)
end)

RegisterNetEvent('lockpicks:UseLockpick', function()
    if source == '' or pickBusy or isDown() then return end

    local vehicle
    if cache.vehicle and cache.seat == -1 then
        vehicle = not canUse(cache.vehicle) and cache.vehicle or nil
    else
        vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), PICK.distance, false)
        if vehicle and GetVehicleDoorLockStatus(vehicle) < 2 then
            vehicle = nil
        end
    end

    local netId = vehicle and netIdOf(vehicle)
    if not netId then return end

    pickBusy = true
    local ped = cache.ped
    local animLoaded = lib.requestAnimDict(HOTWIRE_ANIM.dict, 1000)
    if animLoaded then
        TaskPlayAnim(ped, HOTWIRE_ANIM.dict, HOTWIRE_ANIM.clip, 8.0, -8.0, -1, HOTWIRE_ANIM.flag, 0, false, false, false)
    end

    local success = true
    for _ = 1, random(PICK.reps[1], PICK.reps[2]) do
        if not lib.skillCheck({ 'easy' }, { 'w', 'a', 's', 'd' }) then
            success = false
            break
        end
        Wait(500)
    end

    if animLoaded then
        StopAnimTask(ped, HOTWIRE_ANIM.dict, HOTWIRE_ANIM.clip, 1.0)
        RemoveAnimDict(HOTWIRE_ANIM.dict)
    end

    local unlocked = lib.callback.await('sm_vehiclekeys:lockpick', false, netId, success)
    TriggerTokenEvent('sm_hud:server:addStress', random(1, 4))

    if success and unlocked then
        notify('Kunci berhasil dibobol!', 'success')
    else
        notify('Gagal membobol kunci.')
    end
    pickBusy = false
end)

---@param ped number
local function makeFlee(ped)
    SetPedFleeAttributes(ped, 0, false)
    TaskReactAndFleePed(ped, cache.ped)
end

---@param vehicle number
---@return number[]
local function npcOccupants(vehicle)
    local list = {}
    for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped ~= 0 and not IsPedAPlayer(ped) then
            list[#list + 1] = ped
        end
    end
    return list
end

---@param target number
---@param vehicle number
local function carjack(target, vehicle)
    local netId = netIdOf(vehicle)
    if not netId then return end

    carjackBusy = true
    CreateThread(function()
        if not lib.callback.await('sm_vehiclekeys:carjackStart', false, netId) then
            nextCarjackAt = GetGameTimer() + 2000
            carjackBusy = false
            return
        end

        local occupants = npcOccupants(vehicle)
        local animLoaded = lib.requestAnimDict('mp_am_hold_up', 1000)
        for i = 1, #occupants do
            local ped = occupants[i]
            if animLoaded then
                TaskPlayAnim(ped, 'mp_am_hold_up', 'holdup_victim_20s', 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            PlayPain(ped, 6, 0)
        end
        FreezeEntityPosition(vehicle, true)
        SetVehicleUndriveable(vehicle, true)

        local watching = true
        CreateThread(function()
            local maxDistance = CARJACK.distance + 2.5
            while watching do
                if not DoesEntityExist(target) or IsEntityDead(target) or #(GetEntityCoords(cache.ped) - GetEntityCoords(target)) > maxDistance then
                    lib.cancelProgress()
                    break
                end
                Wait(100)
            end
        end)

        local done = lib.progressBar({
            duration = CARJACK.duration,
            label = 'Merampas kendaraan...',
            canCancel = true,
            disable = { car = true },
        })
        watching = false

        local hasWeapon, weapon = GetCurrentPedWeapon(cache.ped, true)
        local group = hasWeapon and tostring(GetWeapontypeGroup(weapon)) or nil
        local success = lib.callback.await('sm_vehiclekeys:carjackFinish', false, group, not done or not hasWeapon)

        FreezeEntityPosition(vehicle, false)
        SetVehicleUndriveable(vehicle, false)
        if animLoaded then
            RemoveAnimDict('mp_am_hold_up')
        end

        if success then
            for i = 1, #occupants do
                local ped = occupants[i]
                CreateThread(function()
                    TaskLeaveVehicle(ped, vehicle, 0)
                    PlayPain(ped, 6, 0)
                    Wait(1250)
                    ClearPedTasksImmediately(ped)
                    PlayPain(ped, random(7, 8), 0)
                    makeFlee(ped)
                end)
            end
            TriggerTokenEvent('sm_hud:server:addStress', random(1, 4))
        else
            if done then
                notify('Perampasan gagal!')
                TriggerTokenEvent('sm_hud:server:addStress', random(1, 4))
            end
            if DoesEntityExist(target) then
                makeFlee(target)
            end
        end

        nextCarjackAt = GetGameTimer() + CARJACK.cooldown
        carjackBusy = false
    end)
end

---@param vehicle number
local function onEntering(vehicle)
    if ignoresLocks(vehicle) then return end
    if canUse(vehicle) then
        SetVehicleNeedsToBeHotwired(vehicle, false)
        return
    end

    local netId = netIdOf(vehicle)
    if not netId then return end

    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver ~= 0 then
        if IsPedAPlayer(driver) then return end
        if IsEntityDead(driver) and not immune[GetEntityModel(vehicle)] then
            CreateThread(function()
                local done = lib.progressBar({
                    duration = config.takeKeysDuration,
                    label = 'Mengambil kunci dari tubuh...',
                    canCancel = true,
                    disable = { car = true, combat = true },
                })
                if done then
                    lib.callback.await('sm_vehiclekeys:takeKeys', false, netId)
                end
            end)
            return
        end
    end

    TriggerTokenEvent('sm_vehiclekeys:server:npcLock', netId)
end

---@return number?, number?
local function carjackTarget()
    local aiming, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if not aiming or not target or target == 0 or not IsEntityAPed(target) then return end
    if IsPedAPlayer(target) or IsEntityDead(target) or not IsPedInAnyVehicle(target, false) then return end

    local vehicle = GetVehiclePedIsIn(target, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= target or immune[GetEntityModel(vehicle)] then return end
    if #(GetEntityCoords(cache.ped) - GetEntityCoords(target)) > CARJACK.distance then return end
    return target, vehicle
end

CreateThread(function()
    local lastEntering = 0
    local playerState = LocalPlayer.state

    while true do
        local sleep = 1000

        if playerState.isLoggedIn and not cache.vehicle then
            sleep = 200

            local entering = GetVehiclePedIsTryingToEnter(cache.ped)
            if entering ~= lastEntering then
                lastEntering = entering
                if entering ~= 0 then
                    onEntering(entering)
                end
            end

            local weapon = cache.weapon
            if CARJACK.enabled and weapon and not blockedWeapons[weapon] and not carjackBusy and GetGameTimer() >= nextCarjackAt then
                sleep = 100
                local target, vehicle = carjackTarget()
                if target then
                    carjack(target, vehicle)
                end
            end
        end

        Wait(sleep)
    end
end)

exportWrapper('sm_vehiclekeys', 'HasKeys', hasKeys)

exportWrapper('sm_vehiclekeys', 'addNoLockVehicles', function(model)
    if type(model) == 'string' then
        noLock[joaat(model)] = true
    end
end)

exportWrapper('sm_vehiclekeys', 'removeNoLockVehicles', function(model)
    if type(model) == 'string' then
        noLock[joaat(model)] = nil
    end
end)
