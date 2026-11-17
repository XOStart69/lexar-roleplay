camera = {}

local CONFIG = {
    DEFAULT_RADIUS = 5.0,
    MIN_RADIUS = 2.5,
    MAX_RADIUS = 10.0,
    ENTITY_HEIGHT_OFFSET = 0.5,
    MAX_ANGLE_Y = 89.0,
    MIN_ANGLE_Y = -20.0,

    FADE_OUT_DURATION = 300,
    FADE_IN_DURATION = 300,
    SNAP_TRANSITION_DURATION = 200,

    LERP_SPEED = 0.15,

    COLLISION_CHECK_DISTANCE = 0.3,

    DEFAULT_FOV = 50.0,
    MIN_FOV = 30.0,
    MAX_FOV = 80.0,

    SMALL_VEHICLE_RADIUS = 4.0,
    MEDIUM_VEHICLE_RADIUS = 6.0,
    LARGE_VEHICLE_RADIUS = 9.0,
    SMALL_VEHICLE_FOV = 45.0,
    MEDIUM_VEHICLE_FOV = 50.0,
    LARGE_VEHICLE_FOV = 60.0
}

local TRANSITION_STATE = {
    IDLE = 1,
    FADING_OUT = 2,
    SNAPPING = 3,
    FADING_IN = 4,
}

local state = {
    cam = nil,
    entity = nil,
    running = false,

    radius = CONFIG.DEFAULT_RADIUS,
    angleY = 10.0,
    angleZ = 0.0,
    fov = CONFIG.DEFAULT_FOV,

    targetRadius = CONFIG.DEFAULT_RADIUS,
    targetAngleY = 10.0,
    targetAngleZ = 0.0,
    targetFov = CONFIG.DEFAULT_FOV,

    currentIndex = 1,
    transitionState = TRANSITION_STATE.IDLE,
    transitionStartTime = 0,
    fadeAlpha = 0.0,

    vehicleDimensions = nil,
    baseRadius = CONFIG.DEFAULT_RADIUS
}

state.cameraPositions = {
    { az = 180, ay = 12, rm = 1.1,  name = "Depan" },
    { az = 90,  ay = 10, rm = 0.9,  name = "Kanan" },
    { az = 0,   ay = 15, rm = 1.0,  name = "Belakang" },
    { az = 270, ay = 8,  rm = 0.85, name = "Kiri" }
}

local function cos(degrees) return math.cos(math.rad(degrees)) end
local function sin(degrees) return math.sin(math.rad(degrees)) end

local function lerp(current, target, speed)
    return current + (target - current) * speed
end


local function startTransition()
    state.transitionState = TRANSITION_STATE.FADING_OUT
    state.transitionStartTime = GetGameTimer()
    state.fadeAlpha = 0.0
end

local nextCameraPosition = function()
    if state.transitionState ~= TRANSITION_STATE.IDLE then return end

    state.currentIndex = state.currentIndex + 1
    if state.currentIndex > #state.cameraPositions then
        state.currentIndex = 1
    end

    startTransition()
end

local previousCameraPosition = function()
    if state.transitionState ~= TRANSITION_STATE.IDLE then return end

    state.currentIndex = state.currentIndex - 1
    if state.currentIndex < 1 then
        state.currentIndex = #state.cameraPositions
    end

    startTransition()
end

local function getVehicleDimensions(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local dimensions = {
        length = max.y - min.y,
        width = max.x - min.x,
        height = max.z - min.z
    }

    dimensions.diagonal = math.sqrt(
        dimensions.length * dimensions.length +
        dimensions.width * dimensions.width +
        dimensions.height * dimensions.height
    )

    return dimensions
end

local function calculateOptimalCameraSettings(dimensions)
    local diagonal = dimensions.diagonal
    local radius, fov

    if diagonal < 6.0 then
        radius = CONFIG.SMALL_VEHICLE_RADIUS
        fov = 55.0
    elseif diagonal < 10.0 then
        radius = CONFIG.MEDIUM_VEHICLE_RADIUS
        fov = 65.0
    else
        radius = CONFIG.LARGE_VEHICLE_RADIUS
        fov = 75.0
    end

    local aspectRatio = dimensions.length / dimensions.width
    if aspectRatio > 2.5 then
        radius = radius * 1.2
        fov = math.min(fov + 5, CONFIG.MAX_FOV)
    end

    if dimensions.height > 3.0 then
        radius = radius * 1.15
        fov = math.min(fov + 5, CONFIG.MAX_FOV)
    end

    return radius, fov
end

local function checkCollision(entityCoords, camPos)
    local rayHandle = StartShapeTestRay(
        entityCoords.x, entityCoords.y, entityCoords.z + CONFIG.ENTITY_HEIGHT_OFFSET,
        camPos.x, camPos.y, camPos.z,
        -1,
        state.entity,
        7
    )

    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)

    if hit then
        local distance = #(entityCoords - vec3(hitCoords.x, hitCoords.y, hitCoords.z))
        return true, distance - CONFIG.COLLISION_CHECK_DISTANCE
    end

    return false, nil
end

local function calculateCameraPosition()
    local entityCoords = GetEntityCoords(state.entity)

    local cosAngleZ = cos(state.angleZ)
    local cosAngleY = cos(state.angleY)
    local sinAngleZ = sin(state.angleZ)
    local sinAngleY = sin(state.angleY)

    local offset = vec3(
        cosAngleZ * cosAngleY * state.radius,
        sinAngleZ * cosAngleY * state.radius,
        sinAngleY * state.radius
    )

    local desiredCamPos = vec3(
        entityCoords.x + offset.x,
        entityCoords.y + offset.y,
        entityCoords.z + offset.z
    )

    local hasCollision, safeDistance = checkCollision(entityCoords, desiredCamPos)

    if hasCollision and safeDistance then
        local adjustedRadius = math.max(CONFIG.MIN_RADIUS, safeDistance)
        offset = vec3(
            cosAngleZ * cosAngleY * adjustedRadius,
            sinAngleZ * cosAngleY * adjustedRadius,
            sinAngleY * adjustedRadius
        )

        desiredCamPos = vec3(
            entityCoords.x + offset.x,
            entityCoords.y + offset.y,
            entityCoords.z + offset.z
        )
    end

    return desiredCamPos, entityCoords
end

local function updateCameraView()
    state.angleZ = lerp(state.angleZ, state.targetAngleZ, CONFIG.LERP_SPEED)
    state.angleY = lerp(state.angleY, state.targetAngleY, CONFIG.LERP_SPEED)
    state.radius = lerp(state.radius, state.targetRadius, CONFIG.LERP_SPEED)
    state.fov = lerp(state.fov, state.targetFov, CONFIG.LERP_SPEED)

    local camPos, entityCoords = calculateCameraPosition()

    SetCamCoord(state.cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(state.cam, entityCoords.x, entityCoords.y, entityCoords.z + CONFIG.ENTITY_HEIGHT_OFFSET)
    SetCamFov(state.cam, state.fov)
end

local function drawFadeOverlay()
    if state.fadeAlpha > 0.0 then
        DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, math.floor(state.fadeAlpha * 255))
    end
end

local function handleCameraTransition()
    if state.transitionState == TRANSITION_STATE.IDLE then
        return
    end

    local currentTime = GetGameTimer()
    local elapsed = currentTime - state.transitionStartTime
    local target = state.cameraPositions[state.currentIndex]

    if state.transitionState == TRANSITION_STATE.FADING_OUT then
        local progress = elapsed / CONFIG.FADE_OUT_DURATION
        state.fadeAlpha = math.min(progress, 1.0)

        if elapsed >= CONFIG.FADE_OUT_DURATION then
            state.transitionState = TRANSITION_STATE.SNAPPING
            state.transitionStartTime = currentTime
        end

    elseif state.transitionState == TRANSITION_STATE.SNAPPING then
        state.targetAngleZ = target.az
        state.targetAngleY = target.ay
        state.targetRadius = state.baseRadius * target.rm

        state.angleZ = target.az
        state.angleY = target.ay
        state.radius = state.baseRadius * target.rm

        if elapsed >= CONFIG.SNAP_TRANSITION_DURATION then
            state.transitionState = TRANSITION_STATE.FADING_IN
            state.transitionStartTime = currentTime
        end

    elseif state.transitionState == TRANSITION_STATE.FADING_IN then
        local progress = elapsed / CONFIG.FADE_IN_DURATION
        state.fadeAlpha = math.max(1.0 - progress, 0.0)

        if elapsed >= CONFIG.FADE_IN_DURATION then
            state.fadeAlpha = 0.0
            state.transitionState = TRANSITION_STATE.IDLE
        end
    end
end

local function startInputListener()
    CreateThread(function()
        while state.running and DoesEntityExist(state.entity) do
            DisableAllControlActions(0)

            if IsDisabledControlJustPressed(0, 175) then -- Arrow Right
                nextCameraPosition()
            end

            if IsDisabledControlJustPressed(0, 174) then -- Arrow Left
                previousCameraPosition()
            end

            if IsDisabledControlPressed(0, 173) then -- Arrow Up
                state.targetFov = math.min(state.targetFov + 0.5, CONFIG.MAX_FOV)
            elseif IsDisabledControlPressed(0, 172) then -- Arrow Down
                state.targetFov = math.max(state.targetFov - 0.5, CONFIG.MIN_FOV)
            end

            handleCameraTransition()
            updateCameraView()
            drawFadeOverlay()

            Wait(0)
        end
    end)
end

function camera.create(entity)
    state.entity = entity
    state.currentIndex = 1

    if DoesEntityExist(entity) then
        state.vehicleDimensions = getVehicleDimensions(entity)
        local optimalRadius, optimalFov = calculateOptimalCameraSettings(state.vehicleDimensions)

        state.baseRadius = optimalRadius
        state.radius = optimalRadius
        state.targetRadius = optimalRadius
        state.fov = optimalFov
        state.targetFov = optimalFov

        CONFIG.MAX_RADIUS = math.max(CONFIG.MAX_RADIUS, optimalRadius * 1.5)
    end

    if not (state.cam and DoesCamExist(state.cam)) then
        state.running = true

        DoScreenFadeOut(500)
        Wait(1000)

        state.transitionState = TRANSITION_STATE.FADING_IN
        state.transitionStartTime = GetGameTimer()
        state.fadeAlpha = 1.0

        local initialTarget = state.cameraPositions[state.currentIndex]

        state.angleZ = initialTarget.az
        state.angleY = initialTarget.ay
        state.radius = state.baseRadius * initialTarget.rm
        state.targetAngleZ = initialTarget.az
        state.targetAngleY = initialTarget.ay
        state.targetRadius = state.baseRadius * initialTarget.rm

        state.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        RenderScriptCams(true, false, 0, false, false)

        Wait(1000)
        DoScreenFadeIn(500)
    end

    startInputListener()
    return state.cam
end

function camera.destroy()
    if state.cam and DoesCamExist(state.cam) then
        RenderScriptCams(false, false, 0, false, false)
        DestroyCam(state.cam, false)
    end

    state.cam = nil
    state.running = false

    state.entity = nil
    state.radius = CONFIG.DEFAULT_RADIUS
    state.angleY = 10.0
    state.angleZ = 0.0
    state.targetRadius = CONFIG.DEFAULT_RADIUS
    state.targetAngleY = 10.0
    state.targetAngleZ = 0.0
    state.fov = CONFIG.DEFAULT_FOV
    state.targetFov = CONFIG.DEFAULT_FOV
    state.currentIndex = 1
    state.transitionState = TRANSITION_STATE.IDLE
    state.transitionStartTime = 0
    state.fadeAlpha = 0.0
    state.vehicleDimensions = nil
    state.baseRadius = CONFIG.DEFAULT_RADIUS
end

function camera.setFov(fov)
    if state.cam and DoesCamExist(state.cam) then
        state.targetFov = math.max(CONFIG.MIN_FOV, math.min(CONFIG.MAX_FOV, fov))
    end
end

function camera.getFov()
    return state.fov
end

function camera.getVehicleDimensions()
    return state.vehicleDimensions
end

function camera.nextPosition()
    nextCameraPosition()
end

function camera.previousPosition()
    previousCameraPosition()
end

function camera.getCurrentPositionName()
    return state.cameraPositions[state.currentIndex].name
end

function camera.getCurrentPositionIndex()
    return state.currentIndex
end
