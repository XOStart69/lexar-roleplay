local config = require 'resource.illegal_activity.atmrobbery.shared'

local atmZones = {}
local policeTrackerBlip = nil
local isStealingAtm = false
local ropes = {}

local function waitForNetId(netId)
    if not netId then return false end
    local timeout = GetGameTimer() + 10000
    while GetGameTimer() < timeout do
        if NetworkDoesEntityExistWithNetworkId(netId) then return true end
        Wait(0)
    end
    return false
end

local function faceEntity(entity)
    local p1 = GetEntityCoords(cache.ped, true)
    local p2 = GetEntityCoords(entity, true)
    SetEntityHeading(cache.ped, GetHeadingFromVector_2d(p2.x - p1.x, p2.y - p1.y))
end

local function progressBar(label, duration)
    return lib.progressCircle({
        label = label,
        duration = duration,
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })
end

local function loadRope(coords, enablePhysics)
    RopeLoadTextures()

    local timeout = GetGameTimer() + 5000
    while not RopeAreTexturesLoaded() and GetGameTimer() < timeout do Wait(10) end

    local rope = AddRope(
        coords.x + 0.0, coords.y + 0.0, coords.z + 0.0,
        0.0, 0.0, 0.0,
        10.0,
        4,
        10.0,
        1.0,
        1.0,
        false, true, false,
        1.0,
        false,
        0
    )

    if not rope or rope == 0 then return end

    timeout = GetGameTimer() + 5000
    while not DoesRopeExist(rope) and GetGameTimer() < timeout do Wait(10) end
    if not DoesRopeExist(rope) then return end

    if enablePhysics then ActivatePhysics(rope) end

    return rope
end

local function deleteRope(rope)
    if not rope then return end
    RopeUnloadTextures()
    DeleteRope(rope)
end

local function deleteEntity(entity)
    if DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, false, true)
        DeleteObject(entity)
    end
end

local function getAtm(coords, model)
    local objects = GetGamePool('CObject')
    if #objects == 0 then return end
    local nearby = {}
    for i = 1, #objects do
        local entity = objects[i]
        if GetEntityModel(entity) == model and DoesEntityExist(entity) and not NetworkGetEntityIsNetworked(entity) then
            nearby[#nearby + 1] = { entity = entity, distance = #(coords - GetEntityCoords(entity)) }
        end
    end
    if #nearby > 1 then table.sort(nearby, function(a, b) return a.distance < b.distance end) end
    return nearby[1] and nearby[1].distance < 2 and nearby[1].entity
end

local function stateBagWrapper(keyFilter, cb)
    return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)
        local loaded = waitForNetId(netId)
        local entity = loaded and NetworkGetEntityFromNetworkId(netId)
        if entity then cb(netId, entity, value) end
    end)
end

local function calculateDamage(vehicle)
    local damage = config.damage.base
    local modelMult = config.damage.vehicle_multiplier[GetEntityModel(vehicle)]
    if modelMult then damage = damage * modelMult end
    local classMult = config.damage.class_multiplier[GetVehicleClass(vehicle) + 1]
    if classMult then damage = damage * classMult end
    return damage
end

local function setProgressText(percent)
    percent = percent > 100 and 100 or percent
    lib.showTextUI(('-- Menarik ATM --  \nProgress: %s%%'):format(percent), { position = 'left-center' })
end

local function enterRemovedAtm(self)
    local atm = getAtm(self.coords, self.model)
    if atm then deleteEntity(atm) end
end

local function isValidAtmModel(model)
    if config.model[model] then return true end
    for _, spawnedModel in pairs(config.model) do
        if model == spawnedModel then return true end
    end
    return false
end

local function drawTargetSphere(coords, RGB)
    if not coords then return end

    DrawMarker(28,
        coords.x + 0.0, coords.y + 0.0, coords.z + 0.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.25, 0.25, 0.25,
        RGB[1], RGB[2], RGB[3], 150,
        false, false, 2, false, nil, nil, false
    )
end

local function raycastFromPed(flags, distance)
    local camRot = GetFinalRenderedCamRot(2)
    local pitch, yaw = math.rad(camRot.x), math.rad(camRot.z)
    local cosPitch = math.abs(math.cos(pitch))
    local dir = vec3(-math.sin(yaw) * cosPitch, math.cos(yaw) * cosPitch, math.sin(pitch))
    local start = GetEntityCoords(cache.ped) + vec3(0.0, 0.0, 0.6)
    local destination = start + dir * distance
    local hit, entityHit, endCoords = lib.raycast.fromCoords(start, destination, flags, 4)
    return hit, entityHit, endCoords or destination, dir
end

local function findAtmInFront(dir, maxDist, minDot)
    local pedCoords = GetEntityCoords(cache.ped)
    local objects = GetGamePool('CObject')
    local best, bestDist

    for i = 1, #objects do
        local entity = objects[i]
        if DoesEntityExist(entity) and isValidAtmModel(GetEntityModel(entity)) then
            local offset = GetEntityCoords(entity) - pedCoords
            local dist = #(offset)

            if dist > 0.1 and dist < maxDist and (not bestDist or dist < bestDist) then
                local forward = offset / dist
                if forward.x * dir.x + forward.y * dir.y >= minDot then
                    best, bestDist = entity, dist
                end
            end
        end
    end

    return best
end

local isPulling = false

local function pullOffAtm()
    if isPulling then return end

    local vehicle = cache.vehicle
    if not vehicle then return end

    local state = Entity(vehicle).state
    local atmNetId = state.atm_rob
    local rope = atmNetId and ropes[atmNetId]

    if not rope then return end

    isPulling = true

    local lastHit = GetGameTimer() - 1000
    local ripDamage = calculateDamage(vehicle)
    local shown

    while cache.seat == -1 and cache.vehicle == vehicle do
        local percent = state.atm_percent
        if not percent or not state.atm_rob then break end

        local display = math.floor(percent)
        if display ~= shown then
            shown = display
            setProgressText(display)
        end

        if GetGameTimer() - lastHit > 1000
            and RopeGetDistanceBetweenEnds(rope) >= 10
            and not IsControlJustPressed(0, 72)
            and not GetVehicleHandbrake(vehicle)
            and GetEntitySpeed(vehicle) > 0.2
        then
            local rpm = GetVehicleCurrentRpm(vehicle)
            if rpm > 0.45 and rpm < 0.65 then
                TriggerServerEvent('sm_atmrobbery:pullTick', ripDamage)
                lastHit = GetGameTimer()
            end
        end

        Wait(100)
    end

    if lib.isTextUIOpen() then lib.hideTextUI() end
    isPulling = false
end

local function stealAtm(entity)
    if isStealingAtm then
        return lib.notify({ type = 'error', description = 'Sedang berinteraksi dengan ATM lain' })
    end

    if not DoesEntityExist(entity) then
        return lib.notify({ type = 'error', description = 'ATM tidak ditemukan' })
    end

    local state = Entity(entity).state
    if not state or not state.atm_canrob then
        return lib.notify({ type = 'error', description = config.lang.not_ready })
    end

    isStealingAtm = true
    faceEntity(entity)

    lib.requestAnimDict('mini@repair')
    lib.requestAnimDict('amb@medic@standing@kneel@base')
    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(cache.ped, 'mini@repair', 'fixing_a_player', 1.0, 1.0, -1, 48, 0, false, false, false)

    local success = lib.progressCircle({
        label = 'Mengambil uang dari ATM...',
        duration = math.random(40000, 50000),
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 48 },
    })

    ClearPedTasks(cache.ped)
    RemoveAnimDict('mini@repair')
    RemoveAnimDict('amb@medic@standing@kneel@base')

    if success and DoesEntityExist(entity) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        if netId and netId ~= 0 then
            if #(GetEntityCoords(cache.ped) - GetEntityCoords(entity)) <= 3.0 then
                TriggerServerEvent('sm_atmrobbery:breakAtm', netId)
            else
                lib.notify({ type = 'error', description = config.lang.too_far })
            end
        end
    end

    isStealingAtm = false
end

local function playHotwireAnim(label, duration)
    lib.requestAnimDict('anim@gangops@facility@servers@')
    TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@', 'hotwire', 8.0, 8.0, -1, 1, 0, false, false, false)
    local success = progressBar(label, duration)
    StopAnimTask(cache.ped, 'anim@gangops@facility@servers@', 'hotwire', 1.0)
    RemoveAnimDict('anim@gangops@facility@servers@')
    return success
end

AddEventHandler('sm_atmrobbery:useRope', function()
    local canUse, reason = lib.callback.await('sm_atmrobbery:checkServiceStatus', false)
    if not canUse then
        return lib.notify({ type = 'error', description = reason or config.lang.service_unavailable })
    end

    local vehicle, atm, vehicleCoords, atmCoords, vehOffset
    local cancelKey = config.keys.cancel
    local interactKey = config.keys.place_rope

    lib.showTextUI(config.lang.place_rope, { position = 'left-center' })

    while not vehicle do
        local hit, entityHit, endCoords = lib.raycast.cam(4294967295, 4, 10)
        local RGB = { 255, 0, 0 }

        if hit and entityHit and GetEntityType(entityHit) == 2 then
            local minDim = GetModelDimensions(GetEntityModel(entityHit))
            local dist = #(endCoords - GetOffsetFromEntityInWorldCoords(entityHit, 0.0, minDim.y - 1.0, 0.0))

            if dist < 3.0 then
                local class = GetVehicleClass(entityHit) + 1
                if config.damage.class_multiplier[class] > 0 and #(endCoords - GetEntityCoords(cache.ped)) < 1.0 then
                    RGB = { 0, 255, 0 }

                    if IsControlJustPressed(0, interactKey) then
                        faceEntity(entityHit)
                        if playHotwireAnim('Memasang tali ke kendaraan...', math.random(40000, 50000)) then
                            vehicle = entityHit
                            vehicleCoords = endCoords
                            vehOffset = GetOffsetFromEntityGivenWorldCoords(vehicle, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
                            TriggerServerEvent('sm_atmrobbery:triggerDispatch')
                        end
                    end
                end
            end
        end

        if IsControlJustReleased(0, cancelKey) then
            return lib.hideTextUI()
        end

        drawTargetSphere(endCoords, RGB)
    end

    local rope = loadRope(vehicleCoords, true)

    lib.showTextUI(config.lang.attach_atm, { position = 'left-center' })

    while not atm do
        local hit, entityHit, endCoords, dir = raycastFromPed(16, 6.0)
        local RGB = { 255, 0, 0 }
        local target, targetCoords

        if hit and entityHit and entityHit ~= 0 and DoesEntityExist(entityHit)
            and isValidAtmModel(GetEntityModel(entityHit))
        then
            target, targetCoords = entityHit, endCoords
        else
            local nearby = findAtmInFront(dir, 4.0, 0.76)
            if nearby then
                target = nearby
                targetCoords = GetOffsetFromEntityInWorldCoords(nearby, 0.0, -0.3, 0.35)
            end
        end

        if target and targetCoords then
            local atmOrigin = GetEntityCoords(target)
            local distToPlayer = #(atmOrigin - GetEntityCoords(cache.ped))
            local distToVeh = #(atmOrigin - vehicleCoords)

            if distToVeh < 12.0 and distToPlayer < 4.0 then
                RGB = { 0, 255, 0 }

                if IsControlJustPressed(0, interactKey) then
                    local onCooldown, remaining = lib.callback.await('sm_atmrobbery:checkCooldown', false)
                    if onCooldown then
                        local mins = math.floor(remaining / 60)
                        local secs = remaining % 60
                        lib.notify({
                            type = 'error',
                            description = config.lang.cooldown .. ('%dm %ds'):format(mins, secs),
                        })
                        deleteRope(rope)
                        return lib.hideTextUI()
                    end

                    faceEntity(target)
                    if playHotwireAnim('Memasang tali ke ATM...', math.random(40000, 50000)) then
                        atm = target
                        atmCoords = targetCoords
                    end
                end
            end
        end

        if IsControlJustReleased(0, cancelKey) then
            deleteRope(rope)
            return lib.hideTextUI()
        end

        local marker = targetCoords or endCoords
        drawTargetSphere(marker, RGB)
    end

    if atm and vehicle then
        TriggerServerEvent('sm_atmrobbery:pullAtm', VehToNet(vehicle), GetEntityModel(atm), GetOffsetFromEntityInWorldCoords(atm, 0.0, 0.0, 0.34), GetEntityHeading(atm), atmCoords, vehOffset)
    end

    lib.hideTextUI()
    deleteRope(rope)
end)

RegisterNetEvent('sm_atmrobbery:useAtm', function()
    if GetInvokingResource() then return end

    if lib.skillCheck({ 'easy', 'easy', { areaSize = 60, speedMultiplier = 2 }, 'hard' }, { 'q', 'w', 'e', 'r' }) then
        TriggerServerEvent('sm_atmrobbery:crackedAtm')
    end
end)

RegisterNetEvent('sm_atmrobbery:removeAtm', function(coords, model)
    atmZones[#atmZones + 1] = lib.points.new({
        coords = coords,
        model = model,
        distance = 50,
        onEnter = enterRemovedAtm,
    })
end)

RegisterNetEvent('sm_atmrobbery:enablePhysics', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and DoesEntityExist(entity) then
        ActivatePhysics(entity)
        SetObjectPhysicsParams(entity, 300.0, 2.5, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 0.0, -1.0, -1.0)
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(entity, true)
    end
end)

RegisterNetEvent('sm_atmrobbery:client:trackerUpdate', function(coords)
    if GetInvokingResource() then return end
    if policeTrackerBlip then RemoveBlip(policeTrackerBlip) end
    policeTrackerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(policeTrackerBlip, 161)
    SetBlipDisplay(policeTrackerBlip, 4)
    SetBlipScale(policeTrackerBlip, 1.0)
    SetBlipColour(policeTrackerBlip, 1)
    PulseBlip(policeTrackerBlip)
    SetBlipAsShortRange(policeTrackerBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('ATM TRACKER')
    EndTextCommandSetBlipName(policeTrackerBlip)
end)

RegisterNetEvent('sm_atmrobbery:client:trackerRemove', function()
    if GetInvokingResource() then return end
    if policeTrackerBlip then
        RemoveBlip(policeTrackerBlip)
        policeTrackerBlip = nil
    end
end)

stateBagWrapper('atm_rob', function(_, veh, value)
    if not value then return end
    if veh == cache.vehicle and cache.seat == -1 then pullOffAtm() end
end)

stateBagWrapper('rope_attach', function(netId, atm, value)
    if not value or type(value) ~= 'table' then
        local rope = ropes[netId]
        if rope then
            deleteRope(rope)
            ropes[netId] = nil
        end
        return
    end

    local vehNetId = value.vehNetId
    local vehOffset = value.vehOffset

    if waitForNetId(vehNetId) then
        local veh = NetworkGetEntityFromNetworkId(vehNetId)
        local atmCoords = GetOffsetFromEntityInWorldCoords(atm, 0.0, 0.0, 0.6)
        local vehCoords = GetOffsetFromEntityInWorldCoords(veh, vehOffset.x, vehOffset.y, vehOffset.z)
        local rope = loadRope(vehCoords, false)
        if not rope then return end

        SetObjectPhysicsParams(atm, 300.0, 2.5, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 0.0, -1.0, -1.0)
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(atm, true)

        ropes[netId] = rope
        AttachEntitiesToRope(rope, veh, atm, vehCoords.x, vehCoords.y, vehCoords.z, atmCoords.x, atmCoords.y, atmCoords.z, 10.0, false, false, '', '')
    end
end)

lib.onCache('seat', function(seat)
    if seat == -1 then
        local state = Entity(cache.vehicle).state
        if state.atm_rob and state.atm_percent then
            SetTimeout(0, pullOffAtm)
        end
    end
end)

local function addAtmTarget(model)
    exports.ox_target:addModel(model, {
        {
            name = 'sm_atmrobbery:stealAtm',
            icon = 'fa-solid fa-hand',
            label = config.lang.steal,
            distance = 3.0,
            onSelect = function(data) stealAtm(data.entity) end,
            canInteract = function(entity)
                return not cache.vehicle and Entity(entity).state.atm_canrob and not isStealingAtm
            end,
        },
    })
end

for originalModel, spawnedModel in pairs(config.model) do
    addAtmTarget(originalModel)
    addAtmTarget(spawnedModel)
end

CreateThread(function()
    local removedAtms = lib.callback.await('sm_atmrobbery:removedAtms')
    if removedAtms and #removedAtms > 0 then
        for _, atm in pairs(removedAtms) do
            atmZones[#atmZones + 1] = lib.points.new({
                coords = atm.coords,
                model = atm.model,
                distance = 50,
                onEnter = enterRemovedAtm,
            })
        end
    end

    while true do
        for netId, rope in pairs(ropes) do
            if not NetworkDoesEntityExistWithNetworkId(netId) then
                deleteRope(rope)
                ropes[netId] = nil
            end
        end
        Wait(2500)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource ~= resourceName then return end
    if policeTrackerBlip then
        RemoveBlip(policeTrackerBlip)
        policeTrackerBlip = nil
    end
    for _, v in pairs(atmZones) do v:remove() end
    if lib.isTextUIOpen() then lib.hideTextUI() end
end)