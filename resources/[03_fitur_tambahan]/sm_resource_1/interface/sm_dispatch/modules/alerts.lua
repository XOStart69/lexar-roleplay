local Config = localmodule 'config'
local Util = localmodule 'config.util'

local L = Util.L

local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local GetVehiclePedIsIn = GetVehiclePedIsIn
local IsPedCurrentWeaponSilenced = IsPedCurrentWeaponSilenced
local GetSelectedPedWeapon = GetSelectedPedWeapon
local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local mrandom = math.random
local mabs = math.abs

local Alerts = {}

local ctx

local blacklisted = Config.BlacklistedWeapons
local alertConfig = Config.Alerts

---@param dict string
---@return boolean
local function loadDict(dict)
    if HasAnimDictLoaded(dict) then return true end

    RequestAnimDict(dict)

    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end

    return true
end

---@param model number
---@return boolean
local function loadModel(model)
    if HasModelLoaded(model) then return true end

    RequestModel(model)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end

    return true
end

---@return boolean
local function shouldSkipAlert()
    local list = Config.SkipAlertResources

    for i = 1, #list do
        local entry = list[i]

        if GetResourceState(entry.resource) == 'started' then
            local ok, result = pcall(function()
                return exports[entry.resource][entry.export](nil)
            end)

            if ok and result then return true end
        end
    end

    return false
end

local lastAlertTime = {}

---@param key string
---@param cooldown number
---@return boolean
local function passCooldown(key, cooldown)
    local now = GetGameTimer()
    local last = lastAlertTime[key]

    if last and (now - last) < cooldown then
        return false
    end

    lastAlertTime[key] = now
    return true
end

---@param chance number?
---@return boolean
local function passChance(chance)
    if not chance then return true end
    return mrandom(1, 100) <= chance
end

---@param config table
---@return boolean
local function isIgnoredJob(config)
    local ignored = config.ignoredJobs
    if not ignored then return false end

    local job = ctx.getJobName()
    return job and ignored[job] or false
end

---@return number? closest
---@return number? witness
local function findNearbyPeds()
    local playerPed = ctx.cache.ped
    local playerCoords = ctx.cache.coords

    if not playerPed or not playerCoords then return nil, nil end

    local pool = GetGamePool('CPed')
    local minDistance = math.huge
    local closest, witness

    for i = 1, #pool do
        local ped = pool[i]

        if not IsPedDeadOrDying(ped) and not IsPedAPlayer(ped) and GetPedType(ped) ~= 28 then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(pedCoords - playerCoords)

            if distance < minDistance then
                minDistance = distance
                closest = ped
            end

            if not witness
                and HasEntityClearLosToEntity(playerPed, ped, 49)
                and IsPedFacingPed(ped, playerPed, 100.0)
                and not IsPedInAnyVehicle(ped, false)
                and mabs(pedCoords.z - playerCoords.z) < 3.0
            then
                witness = ped
            end
        end
    end

    return closest, witness
end

---@param pedConfig table?
---@return boolean
local function hasWitness(pedConfig)
    if not pedConfig or not pedConfig.enable then return true end

    local target = pedConfig.needLos and ctx.cache.witnessPed or ctx.cache.closestPed
    if not target or not DoesEntityExist(target) then return false end

    local distance = #(GetEntityCoords(target) - ctx.cache.coords)
    if distance > pedConfig.dist then return false end

    if pedConfig.needLos then
        return HasEntityClearLosToEntity(ctx.cache.ped, target, 49)
    end

    return true
end

---@param pedConfig table?
local function playWitnessAnim(pedConfig)
    if not pedConfig or not pedConfig.enable or not pedConfig.anim then return end

    local target = pedConfig.needLos and ctx.cache.witnessPed or ctx.cache.closestPed
    if not target or not DoesEntityExist(target) or IsEntityAMissionEntity(target) then return end

    local anim = pedConfig.anim

    CreateThread(function()
        SetEntityAsMissionEntity(target, true, true)

        if not loadDict(anim.dict) then
            SetEntityAsNoLongerNeeded(target)
            return
        end

        local flag = anim.flag or 51
        TaskPlayAnim(target, anim.dict, anim.name, 2.0, 2.0, -1, flag, 0, false, false, false)

        local prop
        local propConfig = anim.prop

        if propConfig and propConfig.model and loadModel(propConfig.model) then
            local coords = GetEntityCoords(target)
            prop = CreateObject(propConfig.model, coords.x, coords.y, coords.z + 0.2, true, true, true)

            AttachEntityToEntity(
                prop, target, GetPedBoneIndex(target, propConfig.bone),
                propConfig.pos or vec3(0.0, 0.0, 0.0),
                propConfig.rot or vec3(0.0, 0.0, 0.0),
                true, true, false, true, 1, true
            )

            SetModelAsNoLongerNeeded(propConfig.model)
        end

        local endTime = GetGameTimer() + (anim.duration or 5000)

        while GetGameTimer() < endTime do
            if not DoesEntityExist(target) then break end

            if not IsEntityPlayingAnim(target, anim.dict, anim.name, 3) then
                TaskPlayAnim(target, anim.dict, anim.name, 2.0, 2.0, -1, flag, 0, false, false, false)
            end

            Wait(500)
        end

        if prop and DoesEntityExist(prop) then DeleteEntity(prop) end

        if DoesEntityExist(target) then
            ClearPedTasks(target)
            SetEntityAsNoLongerNeeded(target)
        end

        RemoveAnimDict(anim.dict)
    end)
end

---@param config table
---@param overrides table
local function fireAlert(config, overrides)
    local payload = {
        jobs = config.jobs,
        hiddenJobs = config.hiddenJobs,
        coords = ctx.cache.coords,
        coordsOffset = config.coordsOffset,
        removeTime = config.removeTime,
        platePercentage = config.platePercentage,
        playSound = true,
        showLocation = true,
    }

    for key, value in pairs(overrides) do
        payload[key] = value
    end

    ctx.addCall(payload)
end

local function alertShooting()
    if shouldSkipAlert() then return end

    fireAlert(alertConfig.shooting, {
        title = L('shooting'),
        code = '10-11',
        priority = 'Priority 1',
        showDirection = true,
        showGender = true,
        showWeapon = true,
        showVehicle = true,
        blip = { color = 3, sprite = 110, scale = 1.0, radius = 40.0 },
    })
end

local function alertGunSeen()
    if shouldSkipAlert() then return end

    fireAlert(alertConfig.gunSeen, {
        title = L('gun_seen'),
        code = '10-11',
        priority = 'Priority 2',
        showDirection = true,
        showGender = true,
        showWeapon = true,
        showVehicle = true,
        blip = { color = 3, sprite = 110, scale = 1.0, radius = 40.0 },
    })
end

local function alertSpeeding()
    fireAlert(alertConfig.speeding, {
        title = L('speeding'),
        code = '10-11',
        priority = 'Priority 3',
        showDirection = true,
        showVehicle = true,
        blip = { color = 3, sprite = 225, scale = 1.0 },
    })
end

local function alertFighting()
    fireAlert(alertConfig.fighting, {
        title = L('fighting'),
        code = '10-10',
        priority = 'Priority 3',
        showGender = true,
        blip = { color = 3, sprite = 311, scale = 1.0, radius = 40.0 },
    })
end

local function alertVehicleTheft()
    fireAlert(alertConfig.vehStealing, {
        title = L('vehicle_stealing'),
        code = '10-35',
        priority = 'Priority 3',
        showGender = true,
        showVehicle = true,
        blip = { color = 3, sprite = 225, scale = 1.0 },
    })
end

local function alertInjured()
    if shouldSkipAlert() then return end

    fireAlert(alertConfig.injuredPerson, {
        title = L('injured_person'),
        code = '10-69',
        priority = 'Priority 2',
        showGender = true,
        blip = { color = 3, sprite = 153, scale = 1.0 },
    })
end

---@param dispatchIndex string
function Alerts.panic(dispatchIndex)
    local config = alertConfig.panicButton
    local jobs = {}
    local count = 0

    for jobName in pairs(Config.Dispatch[dispatchIndex].jobs) do
        count = count + 1
        jobs[count] = jobName
    end

    if dispatchIndex == 'police' then
        jobs[count + 1] = 'ambulance'
    elseif dispatchIndex == 'ems' then
        jobs[count + 1] = 'police'
    elseif dispatchIndex == 'government' then
        jobs[count + 1] = 'police'
        jobs[count + 2] = 'usmarshal'
        jobs[count + 3] = 'mercenarysm'
    end

    if config.anim and loadDict(config.anim.dict) then
        TaskPlayAnim(PlayerPedId(), config.anim.dict, config.anim.name, 2.0, 2.0, 3000, 49, 0, false, false, false)
    end

    ctx.addCall({
        title = L('panic_button'),
        code = '10-99',
        priority = 'Priority 1',
        jobs = jobs,
        coords = ctx.cache.coords,
        coordsOffset = config.coordsOffset,
        removeTime = config.removeTime,
        showLocation = true,
        showGender = true,
        showPerson = true,
        flash = true,
        playSound = config.playSound,
        playSoundAll = config.playSoundAll,
        blip = { color = 3, sprite = 58, scale = 1.0, flash = true },
    })
end

local function startCacheThread()
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            ctx.cache.ped = ped
            ctx.cache.coords = GetEntityCoords(ped)
            ctx.cache.vehicle = GetVehiclePedIsIn(ped, false)

            local weapon = GetSelectedPedWeapon(ped)
            ctx.cache.weapon = weapon
            ctx.cache.armed = IsPedArmed(ped, 4) and not blacklisted[weapon]

            Wait(1000)
        end
    end)
end

local function startWitnessThread()
    local needed = false

    for _, config in pairs(alertConfig) do
        if config.nearbyPed and config.nearbyPed.enable then
            needed = true
            break
        end
    end

    if not needed then return end

    CreateThread(function()
        while true do
            ctx.cache.closestPed, ctx.cache.witnessPed = findNearbyPeds()
            Wait(7500)
        end
    end)
end

local function startShootingAlert()
    local config = alertConfig.shooting
    if not config or not config.enable then return end

    AddEventHandler('CEventGunShot', function(_, shooterPed)
        if shooterPed ~= ctx.cache.ped then return end
        if blacklisted[ctx.cache.weapon] then return end
        if config.checkForSuppressor and IsPedCurrentWeaponSilenced(ctx.cache.ped) then return end
        if isIgnoredJob(config) then return end
        if not passChance(config.chance) then return end
        if not passCooldown('shooting', config.cooldown) then return end
        if not hasWitness(config.nearbyPed) then return end

        playWitnessAnim(config.nearbyPed)
        alertShooting()
    end)
end

local function startGunSeenAlert()
    local config = alertConfig.gunSeen
    if not config or not config.enable then return end

    CreateThread(function()
        while true do
            if ctx.cache.armed
                and not isIgnoredJob(config)
                and not (config.checkForSuppressor and IsPedCurrentWeaponSilenced(ctx.cache.ped))
                and hasWitness(config.nearbyPed)
                and passChance(config.chance)
                and passCooldown('gunSeen', config.cooldown)
            then
                playWitnessAnim(config.nearbyPed)
                alertGunSeen()
            end

            Wait(1000)
        end
    end)
end

local function startSpeedingAlert()
    local config = alertConfig.speeding
    if not config or not config.enable then return end

    local locations = config.locations
    if not locations or #locations == 0 then return end

    CreateThread(function()
        while true do
            local sleep = 1000
            local vehicle = ctx.cache.vehicle

            if vehicle and vehicle ~= 0 and not isIgnoredJob(config) then
                if GetPedInVehicleSeat(vehicle, -1) == ctx.cache.ped then
                    sleep = 250
                    local speed = GetEntitySpeed(vehicle) * 3.6
                    local coords = ctx.cache.coords

                    for i = 1, #locations do
                        local location = locations[i]

                        if speed >= location.minSpeed
                            and #(coords - location.coords) <= location.radius
                            and hasWitness(config.nearbyPed)
                            and passChance(config.chance)
                            and passCooldown('speeding', config.cooldown)
                        then
                            playWitnessAnim(config.nearbyPed)
                            alertSpeeding()
                            break
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

local function startFightingAlert()
    local config = alertConfig.fighting
    if not config or not config.enable then return end

    CreateThread(function()
        while true do
            local ped = ctx.cache.ped

            if ped and IsPedInMeleeCombat(ped) and IsPedAPlayer(GetMeleeTargetForPed(ped))
                and not isIgnoredJob(config)
                and hasWitness(config.nearbyPed)
                and passChance(config.chance)
                and passCooldown('fighting', config.cooldown)
            then
                playWitnessAnim(config.nearbyPed)
                alertFighting()
            end

            Wait(1000)
        end
    end)
end

local function startVehicleTheftAlert()
    local config = alertConfig.vehStealing
    if not config or not config.enable then return end

    CreateThread(function()
        while true do
            if ctx.cache.ped and IsPedTryingToEnterALockedVehicle(ctx.cache.ped)
                and not isIgnoredJob(config)
                and hasWitness(config.nearbyPed)
                and passChance(config.chance)
                and passCooldown('vehStealing', config.cooldown)
            then
                playWitnessAnim(config.nearbyPed)
                alertVehicleTheft()
            end

            Wait(500)
        end
    end)
end

local function startInjuredAlert()
    local config = alertConfig.injuredPerson
    if not config or not config.enable then return end

    CreateThread(function()
        while true do
            if ctx.isDead()
                and hasWitness(config.nearbyPed)
                and passChance(config.chance)
                and passCooldown('injuredPerson', config.cooldown)
            then
                playWitnessAnim(config.nearbyPed)
                alertInjured()
            end

            Wait(1000)
        end
    end)
end

---@param data table
function Alerts.playCallSound(data)
    if data.soundId and GetResourceState('sm_chatheme') == 'started' then
        TriggerEvent('sm_chatheme:client:playSound', data.soundId)
    elseif data.playSoundAll then
        PlaySoundFromEntity(-1, 'Event_Start_Text', PlayerPedId(), 'GTAO_FM_Events_Soundset', 0, 0)
    elseif data.playSound then
        PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', 0)
    end
end

---@param context table
function Alerts.bind(context)
    ctx = context
end

function Alerts.start()
    startCacheThread()
    startWitnessThread()
    startShootingAlert()
    startGunSeenAlert()
    startSpeedingAlert()
    startFightingAlert()
    startVehicleTheftAlert()
    startInjuredAlert()
end

if alertConfig.call and alertConfig.call.enable then
    local config = alertConfig.call

    local services = config.services or {}

    ---@return string?
    local function currentStreet()
        local coords = GetEntityCoords(PlayerPedId())
        local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(streetHash)
        local crossing = GetStreetNameFromHashKey(crossingHash)

        if street ~= '' and crossing ~= '' then
            return ('%s, %s'):format(street, crossing)
        end

        return street ~= '' and street or (crossing ~= '' and crossing or nil)
    end

    ---@param service string
    ---@param message string
    local function sendCall(service, message)
        TriggerServerEvent('sm_dispatch:server:emergencyCall', {
            service = service,
            message = message,
            location = currentStreet(),
        })
    end

    RegisterNetEvent('sm_dispatch:client:callAccepted', function()
        if config.emote then
            pcall(function() emotemenu:EmoteCommandStart(config.emote) end)

            if config.emoteDuration and config.emoteDuration > 0 then
                SetTimeout(config.emoteDuration, function()
                    pcall(function() emotemenu:EmoteCancel() end)
                end)
            end
        end

        TriggerServerEvent('sm_chatheme:server:sendMessage', {
            category = 'me',
            message = L('call_me_action'),
            isImage = false,
            mask = false,
        })
    end)

    ---@param preset string? pesan dari `/911 [pesan]`
    local function openCallDialog(preset)
        if #services == 0 then return end

        if not lib.callback.await('sm_dispatch:server:canCall', false) then
            return lib.notify({
                type = 'error',
                description = L('call_cooldown'),
                duration = config.notifyDuration,
            })
        end

        local options = {}

        for i = 1, #services do
            options[i] = { value = services[i].value, label = services[i].label }
        end

        local input = lib.inputDialog(L('call'), {
            {
                type = 'select',
                label = L('call_choose_service'),
                options = options,
                default = options[1].value,
                required = true,
                clearable = false,
            },
            {
                type = 'textarea',
                label = L('call_message_label'),
                description = L('call_message_hint'),
                default = preset ~= '' and preset or nil,
                required = true,
                max = config.maxLength,
                autosize = true,
            },
        })

        if not input then return end

        local service, message = input[1], input[2]
        if not service or not message then return end

        sendCall(service, message)
    end

    RegisterCommand('911', function(_, args)
        if not ctx then return end

        CreateThread(function()
            openCallDialog(table.concat(args, ' '))
        end)
    end, false)

    RegisterCommand('911r', function(_, args)
        if not ctx.getCurrentDispatchIndex() then
            return lib.notify({
                type = 'error',
                description = L('reply_no_permission'),
                duration = config.notifyDuration,
            })
        end

        local publicId = tonumber(args[1])

        if not publicId then
            return lib.notify({
                type = 'error',
                description = L('reply_usage'),
                duration = config.notifyDuration,
            })
        end

        table.remove(args, 1)
        local message = table.concat(args, ' '):gsub('^%s+', ''):gsub('%s+$', '')

        if message == '' then
            return lib.notify({
                type = 'error',
                description = L('reply_usage'),
                duration = config.notifyDuration,
            })
        end

        if config.maxLength and #message > config.maxLength then
            message = message:sub(1, config.maxLength)
        end

        TriggerServerEvent('sm_dispatch:server:replyCall', publicId, message)
    end, false)
end

return Alerts
