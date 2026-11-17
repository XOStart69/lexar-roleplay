local cam = nil
local camPitch = 0.0
local camYaw = 0.0
local camDistance = 5.0

local function cosDeg(angle)
    return math.cos(math.rad(angle))
end

local function sinDeg(angle)
    return math.sin(math.rad(angle))
end

function SetCamPosition(targetCoords, deltaYaw, deltaPitch)
    deltaYaw = deltaYaw or 0.0
    deltaPitch = deltaPitch or 0.0

    camYaw = camYaw - deltaYaw
    camPitch = math.clamp(camPitch + deltaPitch, 0.0, 89.0)

    local offset = vec3(
        cosDeg(camYaw) * cosDeg(camPitch) * camDistance,
        sinDeg(camYaw) * cosDeg(camPitch) * camDistance,
        sinDeg(camPitch) * camDistance
    )
    local camCoords = vec3(targetCoords.x + offset.x, targetCoords.y + offset.y, targetCoords.z + offset.z + 2.0)

    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cam, targetCoords.x, targetCoords.y, targetCoords.z)
end

function SetCameraEntity(entity)
    if not cam then
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        RenderScriptCams(true, true, 500, 1, 0)
    end

    local coords = GetEntityCoords(entity)
    SetCamPosition(coords)
end

function StopCameraEntity()
    RenderScriptCams(false, true, 500, 1, 0)
    DestroyCam(cam, true)
    cam = nil
end