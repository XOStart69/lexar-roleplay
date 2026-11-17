if not interface.init(false) then return end

local cam
local promiseId

local frameToken = 0
local frameShown = false

local function openFrame()
    frameToken += 1
    if frameShown then return true end

    frameShown = true
    return interface.show()
end

local function closeFrame()
    frameToken += 1
    local token = frameToken

    SetTimeout(400, function()
        if token == frameToken then
            frameShown = false
            interface.hide()
        end
    end)
end

interface.callback('ui:setStatus', function(data, cb)
    local status = data.status

    if promiseId then
        promiseId:resolve(status)
    end

    cb('ok')
    interface.focus(false, false)
    closeFrame()
end)

local function DestroyCamera()
    if not cam then return end
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    cam = nil
end

local function CreateCam(ped)
    if cam then
        DestroyCamera()
    end

    local coords = GetEntityCoords(ped, true)
    local x = coords.x + GetEntityForwardX(ped) * 1.2
    local y = coords.y + GetEntityForwardY(ped) * 1.2
    local z = coords.z + 0.52
    local camRot = GetEntityRotation(ped, 2)

    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", x, y, z, camRot.x, camRot.y, camRot.z + 181.0, GetGameplayCamFov(), false, 0)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
end

return function(entity, message)
    if not (entity and DoesEntityExist(entity) and message) then return end

    playerState.drugsell_dialog = true

    openFrame()
    interface.send({ action = 'ui:visible', data = true })
    interface.send({ action = 'ui:setMessage', data = message })
    interface.focus(true, true)

    if promiseId then
        promiseId:reject()
        promiseId = nil
    end

    CreateCam(entity)
    SetEntityAlpha(cache.ped, 0, true)

    promiseId = promise.new()
    local status = Citizen.Await(promiseId)
    promiseId = nil

    ResetEntityAlpha(cache.ped)
    DestroyCamera()

    playerState.drugsell_dialog = false

    return status
end