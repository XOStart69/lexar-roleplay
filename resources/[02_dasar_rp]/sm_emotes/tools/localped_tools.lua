local isRecording = false
local radarHidden = false
local oldCoords = nil
local location = vec4(-1255.3362, -3396.9685, 14.1270, 52.5590)
local cameraHandler = CamHandler:new(location)

local pedEntity = { male = nil, female = nil }
local propsEntities = {}
local camThreadRunning = false
local recordingThread = nil

local config = {
    pedMale = `ig_tomcasino`,
    pedFemale = `ig_screen_writer`,
    defaultCameraSettings = {
        angle = 88.0,
        height = 0.5,
        pointAtHeight = 0.5,
        distance = 2.5,
        fov = 50.0
    },
    controlKeys = {
        rotateLeft = 174,    -- Arrow Left
        rotateRight = 175,   -- Arrow Right
        focusUp = 172,       -- Arrow Up
        focusDown = 173,     -- Arrow Down
        zoomIn = 241,        -- Mouse Scroll Up
        zoomOut = 242,       -- Mouse Scroll Down
        confirm = 191,       -- Enter
        cancel = 194,        -- Backspace
        shift = 21,          -- Left Shift
        autoDetect = 38,     -- E key
        adjustDistance = {
            increase = 20,   -- Z key
            decrease = 44    -- Q key
        }
    },
    timeouts = {
        cameraConfirm = 3000,
        pedSpawn = 5000,
        animLoad = 3000
    }
}

local emotes = require 'data.emotes'.category
local cameraCache = {}

local function log(level, message, ...)
    local prefix = ("[AnimRecorder][%s]"):format(level:upper())
    lib.print[level](("%s %s"):format(prefix, message:format(...)))
end

local function safeDeleteEntity(entity)
    if entity and DoesEntityExist(entity) then
        pcall(function()
            DeleteEntity(entity)
        end)
    end
end

local function safeReqModel(model, timeout)
    local ok, response = pcall(lib.requestModel, model, timeout or 15000)

    if not ok and response then
        lib.print.error(response)
        return false
    end

    return ok and response
end

local function safeReqAnim(anim, timeout)
    local ok, response = pcall(lib.requestAnimDict, anim, timeout or 15000)

    if not ok and response then
        lib.print.error(response)
        return false
    end

    return ok and response
end

local function validateModel(model)
    if type(model) == 'string' then
        model = joaat(model)
    end
    return IsModelValid(model)
end

local function setupWeather()
    SetRainLevel(0.0)
    SetWeatherTypePersist("EXTRASUNNY")
    SetWeatherTypeNow("EXTRASUNNY")
    SetWeatherTypeNowPersist("EXTRASUNNY")
    NetworkOverrideClockTime(18, 0, 0)
    NetworkOverrideClockMillisecondsPerGameMinute(1000000)
end

local function hideRadar()
    if radarHidden then return end
    radarHidden = true
    
    CreateThread(function()
        while isRecording do
            DisplayRadar(false)
            HideHudComponentThisFrame(2)  -- Weapon icon
            HideHudComponentThisFrame(3)  -- Cash
            HideHudComponentThisFrame(4)  -- MP Cash
            HideHudComponentThisFrame(6)  -- Vehicle name
            HideHudComponentThisFrame(13) -- Cash change
            Wait(0)
        end
    end)
end

local function clearProps(targetPed)
    if targetPed then
        -- Clear all props (since we can't identify which prop belongs to which ped anymore)
        for i = #propsEntities, 1, -1 do
            safeDeleteEntity(propsEntities[i])
            table.remove(propsEntities, i)
        end
    else
        -- Clear all props
        for i = #propsEntities, 1, -1 do
            safeDeleteEntity(propsEntities[i])
        end
        propsEntities = {}
    end
end

local function addProp(ped, data)
    if not DoesEntityExist(ped) then
        log('warn', 'Ped does not exist for prop attachment')
        return false
    end

    if not data.prop1 or not data.bone then
        log('error', 'Missing required prop data (prop1 or bone)')
        return false
    end

    data.off1 = data.off1 or 0.0
    data.off2 = data.off2 or 0.0
    data.off3 = data.off3 or 0.0
    data.rot1 = data.rot1 or 0.0
    data.rot2 = data.rot2 or 0.0
    data.rot3 = data.rot3 or 0.0

    if not validateModel(data.prop1) then
        log('warn', 'Invalid prop model: %s', data.prop1)
        return false
    end

    local pedCoords = GetEntityCoords(ped)
    local model = safeReqModel(data.prop1, 15000)
    
    if not model then
        log('error', 'Failed to load prop model: %s', data.prop1)
        return false
    end

    local entity = CreateObject(model, pedCoords.x, pedCoords.y, pedCoords.z + 0.2, true, true, true)
    
    if not DoesEntityExist(entity) then
        log('error', 'Failed to create prop entity')
        SetModelAsNoLongerNeeded(data.prop1)
        return false
    end

    if data.textureVariation then
        SetObjectTextureVariation(entity, data.textureVariation)
    end

    if data.noCollision then
        SetEntityCollision(entity, false, false)
    end

    AttachEntityToEntity(
        entity, ped,
        GetPedBoneIndex(ped, data.bone),
        data.off1, data.off2, data.off3,
        data.rot1, data.rot2, data.rot3,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(data.prop1)
    propsEntities[#propsEntities+1] = entity
    log('info', 'Prop attached successfully')
    return true
end

local function addPropsToAnimation(ped, animOptions, textureVariation)
    if not animOptions or not animOptions.Prop then
        return true
    end

    Wait(animOptions.EmoteDuration or 0)

    local propData = {
        prop1 = animOptions.Prop,
        bone = animOptions.PropBone,
        textureVariation = textureVariation,
        noCollision = animOptions.PropNoCollision
    }

    if animOptions.PropPlacement then
        propData.off1, propData.off2, propData.off3,
        propData.rot1, propData.rot2, propData.rot3 = table.unpack(animOptions.PropPlacement)
    end

    if not addProp(ped, propData) then
        return false
    end

    if animOptions.SecondProp then
        local secondPropData = {
            prop1 = animOptions.SecondProp,
            bone = animOptions.SecondPropBone,
            textureVariation = textureVariation,
            noCollision = animOptions.SecondPropNoCollision
        }

        if animOptions.SecondPropPlacement then
            secondPropData.off1, secondPropData.off2, secondPropData.off3,
            secondPropData.rot1, secondPropData.rot2, secondPropData.rot3 = table.unpack(animOptions.SecondPropPlacement)
        end

        if not addProp(ped, secondPropData) then
            clearProps(ped)
            return false
        end
    end

    return true
end

local function deletePeds()
    camThreadRunning = false
    
    for _, ped in pairs(pedEntity) do
        safeDeleteEntity(ped)
    end
    
    clearProps()
    
    pedEntity = { male = nil, female = nil }
end

local function createPed(model, coords, heading)
    if not validateModel(model) then
        log('error', 'Invalid ped model: %s', model)
        return nil
    end

    if not safeReqModel(model, config.timeouts.pedSpawn) then
        log('error', 'Failed to load ped model: %s', model)
        return nil
    end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1, heading, false, false)
    
    local timeout = GetGameTimer() + config.timeouts.pedSpawn
    while not DoesEntityExist(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not DoesEntityExist(ped) then
        log('error', 'Ped creation timed out')
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    SetModelAsNoLongerNeeded(model)
    return ped
end

local function saveCameraCache(animType, settings)
    cameraCache[animType] = settings
    log('info', 'Camera settings cached for: %s', animType)
end

local function getCameraCache(animType)
    return cameraCache[animType]
end

local function getPedDimensions(ped)
    if not DoesEntityExist(ped) then
        return nil
    end

    local modelHash = GetEntityModel(ped)
    local minDim, maxDim = GetModelDimensions(modelHash)

    local pedCoords = GetEntityCoords(ped)
    local headPos = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)  -- Head bone
    local neckPos = GetPedBoneCoords(ped, 39317, 0.0, 0.0, 0.0)  -- Neck bone
    local spinePos = GetPedBoneCoords(ped, 24816, 0.0, 0.0, 0.0) -- Spine root
    local leftFoot = GetPedBoneCoords(ped, 14201, 0.0, 0.0, 0.0) -- Left foot
    local rightFoot = GetPedBoneCoords(ped, 52301, 0.0, 0.0, 0.0) -- Right foot
    local leftHand = GetPedBoneCoords(ped, 18905, 0.0, 0.0, 0.0) -- Left hand
    local rightHand = GetPedBoneCoords(ped, 57005, 0.0, 0.0, 0.0) -- Right hand
    
    local allPoints = {
        pedCoords, headPos, neckPos, spinePos,
        leftFoot, rightFoot, leftHand, rightHand
    }

    -- Add all props to calculation (array based now)
    for _, propEntity in ipairs(propsEntities) do
        if propEntity and DoesEntityExist(propEntity) then
            local propModel = GetEntityModel(propEntity)
            local propMin, propMax = GetModelDimensions(propModel)

            for _, corner in ipairs({
                GetOffsetFromEntityInWorldCoords(propEntity, propMin.x, propMin.y, propMin.z),
                GetOffsetFromEntityInWorldCoords(propEntity, propMax.x, propMax.y, propMax.z),
                GetOffsetFromEntityInWorldCoords(propEntity, propMin.x, propMax.y, propMin.z),
                GetOffsetFromEntityInWorldCoords(propEntity, propMax.x, propMin.y, propMax.z),
            }) do
                table.insert(allPoints, corner)
            end
        end
    end

    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge

    for _, point in ipairs(allPoints) do
        minX = math.min(minX, point.x)
        maxX = math.max(maxX, point.x)
        minY = math.min(minY, point.y)
        maxY = math.max(maxY, point.y)
        minZ = math.min(minZ, point.z)
        maxZ = math.max(maxZ, point.z)
    end

    local actualHeight = maxZ - minZ
    local centerZ = (maxZ + minZ) / 2
    local centerOffset = centerZ - pedCoords.z

    local horizontalSpread = math.max(
        math.abs(maxX - pedCoords.x),
        math.abs(minX - pedCoords.x),
        math.abs(maxY - pedCoords.y),
        math.abs(minY - pedCoords.y)
    )

    return {
        modelMin = minDim,
        modelMax = maxDim,
        actualHeight = actualHeight,
        lowestPoint = minZ,
        highestPoint = maxZ,
        centerOffset = centerOffset,
        horizontalSpread = horizontalSpread,
        headHeight = headPos.z - pedCoords.z,
        spineHeight = spinePos.z - pedCoords.z,
        neckHeight = neckPos.z - pedCoords.z,
        boundingBox = {
            min = vector3(minX, minY, minZ),
            max = vector3(maxX, maxY, maxZ)
        }
    }
end

local function calculateOptimalCameraSettings(ped)
    local dims = getPedDimensions(ped)
    if not dims then
        return table.clone(config.defaultCameraSettings)
    end

    local settings = {}

    settings.height = dims.centerOffset

    settings.pointAtHeight = dims.centerOffset + (dims.actualHeight * 0.1)
    
    local verticalDistance = dims.actualHeight * 1.2
    local horizontalDistance = dims.horizontalSpread * 2.0
    local baseDistance = math.max(verticalDistance, horizontalDistance)
    settings.distance = math.max(2.5, math.min(6.0, baseDistance))

    if dims.horizontalSpread > 1.0 then
        settings.fov = 65.0  -- Wider FOV for very spread out poses
    elseif dims.horizontalSpread > 0.7 then
        settings.fov = 60.0  -- Medium-wide FOV for spread poses
    elseif dims.actualHeight > 2.5 then
        settings.fov = 58.0  -- Medium FOV for tall poses
    else
        settings.fov = 55.0  -- Standard FOV
    end

    settings.angle = 88.0

    log('info', 'Auto-detected dimensions: Height=%.2f, Spread=%.2f, Distance=%.2f, FOV=%.1f',
        dims.actualHeight, dims.horizontalSpread, settings.distance, settings.fov)

    return settings
end

local function applyCameraSettings(ped, settings)
    if not cameraHandler or not cameraHandler.cam or not DoesEntityExist(ped) then
        return false
    end

    local pedCoords = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)

    local angleRad = math.rad(settings.angle)
    local headingRad = math.rad(pedHeading)
    local finalAngle = headingRad + angleRad

    local camX = pedCoords.x - (math.sin(finalAngle) * settings.distance)
    local camY = pedCoords.y - (math.cos(finalAngle) * settings.distance)
    local camZ = pedCoords.z + settings.height

    SetCamCoord(cameraHandler.cam, camX, camY, camZ)
    SetCamFov(cameraHandler.cam, settings.fov)

    local pointAtZ = pedCoords.z + settings.pointAtHeight
    PointCamAtCoord(cameraHandler.cam, pedCoords.x, pedCoords.y, pointAtZ)

    -- print(json.encode(settings, ))

    return true
end

-- local function confirmCameraSetup(animType)
--     local cached = getCameraCache(animType)
    
--     if not cached then
--         return true, nil
--     end

--     log('info', 'Camera settings found for: %s', animType)

--     local confirmed = false
--     local useSaved = false
--     local startTime = GetGameTimer()
--     local timeout = config.timeouts.cameraConfirm

--     while not confirmed do
--         local elapsed = GetGameTimer() - startTime
--         local remaining = math.max(0, timeout - elapsed)
--         local remainingSec = math.ceil(remaining / 1000)

--         if remaining <= 0 then
--             useSaved = true
--             confirmed = true
--             log('info', 'Auto-confirmed cached settings')
--             break
--         end

--         DisableAllControlActions(0)
--         EnableControlAction(0, config.controlKeys.confirm, true)
--         EnableControlAction(0, config.controlKeys.cancel, true)

--         SetTextFont(4)
--         SetTextProportional(1)
--         SetTextScale(0.0, 0.4)
--         SetTextColour(255, 255, 255, 255)
--         SetTextDropshadow(0, 0, 0, 0, 255)
--         SetTextEdge(2, 0, 0, 0, 150)
--         SetTextDropShadow()
--         SetTextOutline()
--         SetTextEntry("STRING")
--         AddTextComponentString(
--             ("~b~Camera Settings Found~w~\n~g~ENTER~w~ = Use Saved | ~r~BACKSPACE~w~ = Adjust\n~y~Auto-confirm in %d seconds..."):format(remainingSec)
--         )
--         DrawText(0.5, 0.5)
        
--         if IsControlJustPressed(0, config.controlKeys.confirm) then
--             useSaved = true
--             confirmed = true
--         elseif IsControlJustPressed(0, config.controlKeys.cancel) then
--             useSaved = false
--             confirmed = true
--         end
        
--         Wait(0)
--     end
    
--     return not useSaved, cached
-- end

local function interactiveCameraSetup(ped, animType, useCache)
    if not DoesEntityExist(ped) then
        log('error', 'Ped does not exist for camera setup')
        return nil
    end

    local needSetup = true
    local cached = nil
    
    -- if useCache then
    --     needSetup, cached = confirmCameraSetup(animType)
        
    --     if not needSetup and cached then
    --         if applyCameraSettings(ped, cached) then
    --             log('info', 'Applied cached camera settings')
    --             return cached
    --         else
    --             log('warn', 'Failed to apply cached settings, starting manual setup')
    --             needSetup = true
    --         end
    --     end
    -- end
    
    local setupComplete = false
    local settings = table.clone(config.defaultCameraSettings)
    local controlsDisabled = true
    
    CreateThread(function()
        while not setupComplete do
            if controlsDisabled then
                DisableAllControlActions(0)
                
                for _, key in pairs(config.controlKeys) do
                    if type(key) == 'number' then
                        EnableControlAction(0, key, true)
                    elseif type(key) == 'table' then
                        for _, subKey in pairs(key) do
                            EnableControlAction(0, subKey, true)
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
    
    log('info', '=== Camera Setup Mode ===')
    log('info', 'Arrow Left/Right: Rotate | Arrow Up/Down: Camera Height')
    log('info', 'Shift + Arrow Up/Down: Focus Height | Scroll: FOV | Q/Z: Distance')
    log('info', 'E: Auto-Detect Position | ENTER: Confirm')

    -- Auto-detect on start
    CreateThread(function()
        Wait(500) -- Small delay to ensure everything is ready
        local autoSettings = calculateOptimalCameraSettings(ped)
        if autoSettings then
            settings.height = autoSettings.height
            settings.pointAtHeight = autoSettings.pointAtHeight
            settings.distance = autoSettings.distance
            settings.fov = autoSettings.fov
            settings.angle = autoSettings.angle
            applyCameraSettings(ped, settings)
            log('info', 'Initial auto-detect applied')
        end

        setupComplete = true
    end)

    -- CreateThread(function()
    --     while not setupComplete do
    --         local pedCoords = GetEntityCoords(ped)
    --         local pedHeading = GetEntityHeading(ped)
            
    --         if IsControlPressed(0, config.controlKeys.rotateLeft) then
    --             settings.angle = settings.angle - 2.0
    --         elseif IsControlPressed(0, config.controlKeys.rotateRight) then
    --             settings.angle = settings.angle + 2.0
    --         end

    --         local isShiftPressed = IsControlPressed(0, config.controlKeys.shift)

    --         if IsControlPressed(0, config.controlKeys.focusUp) then
    --             if isShiftPressed then
    --                 settings.pointAtHeight = settings.pointAtHeight + 0.05
    --             else
    --                 settings.height = settings.height + 0.05
    --             end
    --         elseif IsControlPressed(0, config.controlKeys.focusDown) then
    --             if isShiftPressed then
    --                 settings.pointAtHeight = settings.pointAtHeight - 0.05
    --             else
    --                 settings.height = settings.height - 0.05
    --             end
    --         end
            
    --         if IsControlJustPressed(0, config.controlKeys.zoomIn) then
    --             settings.fov = math.max(10.0, settings.fov - 2.0)
    --         elseif IsControlJustPressed(0, config.controlKeys.zoomOut) then
    --             settings.fov = math.min(90.0, settings.fov + 2.0)
    --         end
            
    --         if IsControlPressed(0, config.controlKeys.adjustDistance.increase) then
    --             settings.distance = math.min(10.0, settings.distance + 0.05)
    --         elseif IsControlPressed(0, config.controlKeys.adjustDistance.decrease) then
    --             settings.distance = math.max(1.0, settings.distance - 0.05)
    --         end

    --         if IsControlJustPressed(0, config.controlKeys.autoDetect) then
    --             local detectedSettings = calculateOptimalCameraSettings(ped)
    --             if detectedSettings then
    --                 settings.height = detectedSettings.height
    --                 settings.pointAtHeight = detectedSettings.pointAtHeight
    --                 settings.distance = detectedSettings.distance
    --                 settings.fov = detectedSettings.fov
    --                 log('info', 'Auto-detect applied!')
    --             end
    --         end

    --         settings.pointAtHeight = math.max(-0.5, math.min(2.0, settings.pointAtHeight))
            
    --         applyCameraSettings(ped, settings)
            
    --         local focusText = "Body"
    --         if settings.pointAtHeight > 1.3 then
    --             focusText = "Head"
    --         elseif settings.pointAtHeight < 0.3 then
    --             focusText = "Feet"
    --         end
            
    --         SetTextFont(4)
    --         SetTextProportional(1)
    --         SetTextScale(0.0, 0.35)
    --         SetTextColour(255, 255, 255, 255)
    --         SetTextDropshadow(0, 0, 0, 0, 255)
    --         SetTextEdge(2, 0, 0, 0, 150)
    --         SetTextDropShadow()
    --         SetTextOutline()
    --         SetTextEntry("STRING")
    --         AddTextComponentString(
    --             ("~b~Camera Setup~w~\nAngle: ~y~%.1f°~w~ | Height: ~y~%.2fm~w~ | Focus: ~y~%s~w~ (%.2f)\nFOV: ~y~%.1f~w~ | Distance: ~y~%.1fm~w~\n~o~E~w~ Auto-Detect | ~g~ENTER~w~ Confirm"):format(
    --                 settings.angle, settings.height, focusText, settings.pointAtHeight, settings.fov, settings.distance
    --             )
    --         )
    --         DrawText(0.5, 0.85)
            
    --         if IsControlJustPressed(0, config.controlKeys.confirm) then
    --             setupComplete = true
    --             controlsDisabled = false
    --             saveCameraCache(animType, settings)
    --             log('info', 'Camera setup complete')
    --         end
            
    --         Wait(0)
    --     end
    -- end)
    
    while not setupComplete do
        Wait(100)
    end
    
    return settings
end

local function recordTypeAnimation(category, emote)
    local promise = promise.new()

    local spData
    local fpData = emote
    local sharedEmote = fpData.secondPlayersAnim
    
    if not safeReqModel(config.pedMale, config.timeouts.animLoad) then
        return promise:resolve(false)
    end
    
    if sharedEmote and not safeReqModel(config.pedFemale, config.timeouts.animLoad) then
        return promise:resolve(false)
    end
    
    if not safeReqAnim(fpData.dict) then
        log('error', 'Failed to load anim dict: %s', emote.dict)
        return promise:resolve(false)
    end
    
    pedEntity.male = createPed(config.pedMale, location, location.w)
    if not pedEntity.male then
        return promise:resolve(false)
    end

    FreezeEntityPosition(pedEntity.male, true)

    if sharedEmote then
        spData = emotes[category]?[sharedEmote]

        if not (spData and safeReqAnim(spData.dict, config.timeouts.animLoad)) then
            return promise:resolve(false)
        end

        pedEntity.female = createPed(config.pedFemale, location, location.w)
        if not pedEntity.female then
            deletePeds()
            return promise:resolve(false)
        end
        
        local options = spData.AnimationOptions
        local options2 = fpData.AnimationOptions
        
        if options and options.Attachto and not options2?.Attachto then
            AttachEntityToEntity(
                pedEntity.female, pedEntity.male,
                GetPedBoneIndex(pedEntity.male, options.bone or -1),
                options.pos.x, options.pos.y, options.pos.z,
                options.rot.x, options.rot.y, options.rot.z,
                false, false, false, true, 1, true
            )
        end
    end


    local options = fpData.AnimationOptions

    if options and options.Attachto then
        AttachEntityToEntity(
            pedEntity.male, pedEntity.female,
            GetPedBoneIndex(pedEntity.female, options.bone or -1),
            options.pos.x, options.pos.y, options.pos.z,
            options.rot.x, options.rot.y, options.rot.z,
            false, false, false, true, 1, true
        )

        local coords = GetOffsetFromEntityInWorldCoords(
            pedEntity.female,
            (options.SyncOffsetSide or 0) + 0.0,
            (options.SyncOffsetFront or 1) + 0.0,
            (options.SyncOffsetHeight or 0) + 0.0
        )
        local heading = GetEntityHeading(pedEntity.female)

        SetEntityHeading(pedEntity.male, heading - (options.SyncOffsetHeading or 180) + 0.0)
        SetEntityCoordsNoOffset(pedEntity.male, coords.x, coords.y, coords.z, false, false, false)
    end

    -- Play animation first
    TaskPlayAnim(
        pedEntity.male,
        fpData.dict,
        fpData.anim,
        8.0, -8.0, -1,
        options and options.Flag or 1,
        0, false, false, false
    )

    if spData then
        TaskPlayAnim(
            pedEntity.female,
            spData.dict,
            spData.anim,
            8.0, -8.0, -1,
            spData.AnimationOptions?.Flag or 1,
            0, false, false, false
        )
    end

    -- Wait for animation to start
    Wait(300)

    -- Add props if needed (before camera setup)
    if options?.Prop then
        addPropsToAnimation(pedEntity.male, options)
    end

    if spData and spData.AnimationOptions?.Prop then
        addPropsToAnimation(pedEntity.female, spData.AnimationOptions)
    end

    -- Wait a bit more for props to attach
    if options?.Prop or (spData and spData.AnimationOptions?.Prop) then
        Wait(200)
    end

    -- Now setup camera with auto-detect (props are loaded)
    local camSetup = interactiveCameraSetup(pedEntity.male, "animation", true)
    if not camSetup then
        return promise:resolve(false)
    end
    
    local duration = GetAnimDuration(fpData.dict, fpData.anim) * 1000

    if duration ~= duration or duration <= 0 or duration > 5000 or duration < 1000 then
            print("⚠️ Invalid duration detected, using fallback")
        duration = 5000
    end

    return promise:resolve(duration)
end

local function recordTypeWalk(walk)
    local promise = promise.new()
    if not safeReqModel(config.pedMale, config.timeouts.pedSpawn) then
        return promise:resolve(false)
    end
    
    if not lib.requestAnimSet(walk, config.timeouts.animLoad) then
        log('error', 'Failed to load walk animset: %s', walk)
        return promise:resolve(false)
    end
    
    pedEntity.male = createPed(config.pedMale, location, location.w)
    if not pedEntity.male then
        return promise:resolve(false)
    end
    
    SetPedMovementClipset(pedEntity.male, walk, 0.2)
    SetEntityCoords(pedEntity.male, location.x, location.y, location.z, false, false, false, false)
    SetEntityHeading(pedEntity.male, location.w)
    FreezeEntityPosition(pedEntity.male, false)

    -- Start walking
    local targetCoords = GetOffsetFromEntityInWorldCoords(pedEntity.male, 0.0, 2.0, 0.0)
    TaskGoStraightToCoord(
        pedEntity.male,
        targetCoords.x, targetCoords.y + 0.5, targetCoords.z,
        0.5, -1, location.w, 0.1
    )

    Wait(1000) -- Wait for walk animation to start

    local camSetup = interactiveCameraSetup(pedEntity.male, "walk", true)
    if not camSetup then
        return promise:resolve(false)
    end
    
    return promise:resolve(4000)
end

local function recordTypeExpression(expression)
    local p = promise.new()

    if not safeReqModel(config.pedMale, config.timeouts.pedSpawn) then
        return p:resolve(false)
    end
    
    pedEntity.male = createPed(config.pedMale, location, location.w)
    if not pedEntity.male then
        return p:resolve(false)
    end
    
    FreezeEntityPosition(pedEntity.male, true)
    lib.playAnim(pedEntity.male, "mp_sleep", "bind_pose_180", 8.0, 1, -1, 1, 0, false, false, false)

    Wait(300)

    SetFacialIdleAnimOverride(pedEntity.male, expression, 0)

    Wait(200) -- Wait for expression to apply

    local camSetup = interactiveCameraSetup(pedEntity.male, "expression", true)
    if not camSetup then
        return p:resolve(false)
    end
    
    return p:resolve(3000)
end

local function recordTypeScenario(scenario)
    local p = promise.new()

    if not safeReqModel(config.pedMale, config.timeouts.pedSpawn) then
        return p:resolve(false)
    end
    
    pedEntity.male = createPed(config.pedMale, location, location.w)
    if not pedEntity.male then
        return p:resolve(false)
    end

    FreezeEntityPosition(pedEntity.male, true)
    utils.clearScenarioObject()
    TaskStartScenarioInPlace(pedEntity.male, scenario, 0, true)

    Wait(800) -- Wait for scenario animation to start

    local camSetup = interactiveCameraSetup(pedEntity.male, "scenario", true)
    if not camSetup then
        return p:resolve(false)
    end
    
    return p:resolve(5000)
end

local function reset()
    camThreadRunning = false
    isRecording = false
    radarHidden = false
    
    if recordingThread then
        recordingThread = nil
    end
    
    deletePeds()
    
    if cameraHandler then
        cameraHandler:destroy()
    end
    
    if oldCoords then
        SetEntityCoords(cache.ped, oldCoords.x, oldCoords.y, oldCoords.z, false, false, false, false)
        oldCoords = nil
    end
end

local function startRecording(category, emote)
    if isRecording then
        log('warn', 'Recording already in progress')
        return false
    end

    if not emote then
        log('error', 'Invalid emote data')
        return false
    end

    log('info', 'Starting recording: %s - %s', category, emote.command)
    
    ClearPedTasks(cache.ped)
    oldCoords = GetEntityCoords(cache.ped)
    
    isRecording = true
    cameraHandler:setup()
    hideRadar()
    setupWeather()
    
    SetEntityCoords(cache.ped, location.x, location.y, location.z - 5.0, false, false, false, false)
    
    Wait(1000)
    
    local duration = false
    
    if category == "walks" then
        duration = Citizen.Await(recordTypeWalk(emote.anim))
    elseif category == "expressions" then
        duration = Citizen.Await(recordTypeExpression(emote.anim))
    elseif category == "scenario" then
        duration = Citizen.Await(recordTypeScenario(emote.scenario))
    else
        duration = Citizen.Await(recordTypeAnimation(category, emote))
    end
    
    if not duration then
        log('error', 'Failed to setup recording')
        reset()
        return false
    end

    Wait(2000)
    local success = false
    exports.rhd_gifanim:StartRecording(emote.command, duration, function(result)
        success = result
        reset()
        log('info', 'Recording %s', success and 'completed successfully' or 'failed')
    end)

    while isRecording do
        Wait(500)
    end
    
    return success
end

local busy = false

local function prepare(category, command)
    local emoteData = emotes[category]

    if busy then return end

    if not emoteData then
        log('error', 'Invalid category: %s', category)
        log('info', 'Valid categories: walks, expressions, scenario, emotes, shared, dances')
        return
    end

    if command then
        local emote = emoteData[command]
        if not emote then
            log('error', 'Command not found: %s', command)
            return
        end
        
        local ignored = (
            emote.secondPlayersAnim or emote.category == 'animalemotes'
        )

        if ignored then
            return
        end

        busy = true

        startRecording(category, emote)

        busy = false
    else
        busy = true

        for cmd, emote in pairs(emoteData) do

            if not busy then
                break
            end

            local ignored = (
                emote.secondPlayersAnim or emote.category == 'animalemotes'
            )

            if not ( not ignored and startRecording(category, emote)) then
                log('warn', 'Skipped: %s', cmd)
            end
            Wait(1000)
        end

        busy = false
    end
end

RegisterCommand('recordanim', function(_, args)
    if #args < 1 then
        log('info', 'Usage: /recordanim <category> [command]')
        log('info', 'Categories: walks, expressions, scenario, emotes, shared, dances')
        return
    end

    local category = args[1]:lower()
    local command = args[2]
    
    prepare(category, command)
end, false)


local animlist = { 
}

RegisterCommand('recordanimlist', function (_, args)
    local emote_data = emotes[args[1]]

    if not emote_data then
        return
    end

    if busy then return end

    busy = true

    for i=1, #animlist do

        if not busy then
            break
        end
        
        local emote = emote_data[animlist[i]]
        if not emote then
            log('error', 'Command not found: %s', animlist[i])
            return
        end
        
        local ignored = (
            emote.secondPlayersAnim or emote.category == 'animalemotes'
        )

        if ignored then
            return
        end

        startRecording(args[1]:lower(), emote)
    end

    busy = false
end, false)

RegisterCommand('stoprecording', function()
    busy = false

    exports.rhd_gifanim:StopRecording(function()
        reset()
        log('info', 'Recording stopped by user')
    end)
end, false)

RegisterCommand('clearcache', function()
    cameraCache = {}
    log('info', 'Camera cache cleared')
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        reset()
        if isRecording then
            exports.rhd_gifanim:StopRecording()
        end
    end
end)