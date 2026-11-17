local camera = {}

local FOLLOW_FLAGS <const> = 17
local FOLLOW_MARGIN <const> = 0.25
local FOLLOW_RECENTER_MS <const> = 2000
local DEFAULT_DOF <const> = { near = 0.5, far = 2.0 }

---@class CameraView
---@field position vector3
---@field target vector3
---@field fov number
---@field dof { near: number, far: number }|false

---@type number?
local active
---@type CameraView?
local view
local token = 0

---@param t number
---@return number
local function smooth(t)
    if t >= 1.0 then return 1.0 end

    return t * t * (3.0 - 2.0 * t)
end

---@param from vector3
---@param first vector3
---@param second vector3
---@param to vector3
---@param t number
---@return vector3
local function bezier(from, first, second, to, t)
    local u = 1.0 - t

    return from * (u * u * u) + first * (3.0 * u * u * t) + second * (3.0 * u * t * t) + to * (t * t * t)
end

---@param position vector3
---@param fov number
---@return number
local function create(position, fov)
    return CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', position.x, position.y, position.z, 0.0, 0.0, 0.0, fov, false, 2)
end

---@param cam number
---@param easeMs number
local function activate(cam, easeMs)
    local previous = active

    active = cam
    token += 1

    if previous and DoesCamExist(previous) and easeMs > 0 then
        SetCamActiveWithInterp(cam, previous, easeMs, 1, 1)
        SetTimeout(easeMs + 100, function()
            DestroyCam(previous, false)
        end)
    else
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, false)

        if previous then
            DestroyCam(previous, false)
        end
    end

    return token
end

---@class CameraFocus
---@field position vector3
---@field target vector3
---@field fov number
---@field dof? { near: number, far: number }|false
---@field easeMs? number

---@param data CameraFocus
---@return promise
function camera.focus(data)
    local done = promise.new()
    local cam = create(data.position, data.fov)
    local dof = data.dof ~= false and (data.dof or DEFAULT_DOF) or false

    PointCamAtCoord(cam, data.target.x, data.target.y, data.target.z)

    if dof then
        SetCamUseShallowDofMode(cam, true)
        SetCamNearDof(cam, dof.near)
        SetCamFarDof(cam, dof.far)
        SetCamDofStrength(cam, 1.0)
    end

    local id = activate(cam, data.easeMs or 0)

    view = { position = data.position, target = data.target, fov = data.fov, dof = dof }
    done:resolve(true)

    if dof then
        CreateThread(function()
            while id == token and DoesCamExist(cam) do
                SetUseHiDof()
                Wait(0)
            end
        end)
    end

    return done
end

---@param data CameraFocus
---@param durationMs integer
---@param via? { [1]: vector3, [2]: vector3 }
function camera.glide(data, durationMs, via)
    local cam, from = active, view

    if not cam or not DoesCamExist(cam) or not from or durationMs <= 0 then
        camera.focus(data)
        return
    end

    token += 1

    local id = token
    local dof = data.dof ~= false and (data.dof or DEFAULT_DOF) or false
    local fromDof = from.dof or dof
    local began = GetGameTimer()

    view = { position = data.position, target = data.target, fov = data.fov, dof = dof }

    if dof then
        SetCamUseShallowDofMode(cam, true)
        SetCamDofStrength(cam, 1.0)
    end

    CreateThread(function()
        while id == token and DoesCamExist(cam) do
            local t = smooth(math.min(1.0, (GetGameTimer() - began) / durationMs))
            local position = via and bezier(from.position, via[1], via[2], data.position, t) or from.position + (data.position - from.position) * t
            local target = from.target + (data.target - from.target) * t

            SetCamCoord(cam, position.x, position.y, position.z)
            PointCamAtCoord(cam, target.x, target.y, target.z)
            SetCamFov(cam, from.fov + (data.fov - from.fov) * t)

            if dof and fromDof then
                SetCamNearDof(cam, fromDof.near + (dof.near - fromDof.near) * t)
                SetCamFarDof(cam, fromDof.far + (dof.far - fromDof.far) * t)
                SetUseHiDof()
            end

            Wait(0)
        end
    end)
end

---@return CameraView?
function camera.view()
    return view
end

---@param from vector3
---@param point vector3
---@param amount number
---@return vector3
function camera.aside(from, point, amount)
    local direction = point - from
    local length = math.sqrt(direction.x * direction.x + direction.y * direction.y)

    if amount == 0.0 or length < 0.001 then return point end

    return point - vec3(direction.y / length, -direction.x / length, 0.0) * amount
end

---@param from vector3
---@param to vector3
---@param ignore number
---@return vector3
local function reachable(from, to, ignore)
    local path = to - from
    local length = #path

    if length < 0.001 then return to end

    local direction = path / length
    local reach = to + direction * FOLLOW_MARGIN
    local probe = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, reach.x, reach.y, reach.z, FOLLOW_FLAGS, ignore, 4)
    local _, hit, coords = GetShapeTestResult(probe)

    if hit ~= true and hit ~= 1 then return to end

    local free = #(coords - from) - FOLLOW_MARGIN

    return free > 0.0 and from + direction * math.min(free, length) or from
end

---@param from vector3
---@param point vector3
---@param angle number
---@return vector3
local function turned(from, point, angle)
    local direction = point - from
    local cos, sin = math.cos(angle), math.sin(angle)

    return from + vec3(direction.x * cos - direction.y * sin, direction.x * sin + direction.y * cos, direction.z)
end

---@param ped number
---@param bone integer
---@param shift? number
function camera.follow(ped, bone, shift)
    local cam = active
    if not cam then return end

    token += 1

    local id = token

    CreateThread(function()
        local position = GetCamCoord(cam)
        local offset = position - GetEntityCoords(ped)
        local target = GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0)
        local flat = target - position
        local angle = math.atan(shift or 0.0, math.sqrt(flat.x * flat.x + flat.y * flat.y))
        local began = GetGameTimer()

        while id == token and DoesCamExist(cam) and DoesEntityExist(ped) do
            local frame = GetFrameTime()
            local desired = reachable(position, GetEntityCoords(ped) + offset, ped)
            local recenter = smooth(math.min(1.0, (GetGameTimer() - began) / FOLLOW_RECENTER_MS))

            position = position + (desired - position) * math.min(1.0, frame * 1.5)
            target = target + (GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0) - target) * math.min(1.0, frame * 3.0)

            local aim = turned(position, target, angle * (1.0 - recenter))

            if view then
                view.position = position
                view.target = aim
            end

            SetCamCoord(cam, position.x, position.y, position.z)
            PointCamAtCoord(cam, aim.x, aim.y, aim.z)
            SetUseHiDof()
            Wait(0)
        end
    end)
end

---@param easeMs? number
function camera.destroy(easeMs)
    token += 1
    view = nil

    if not active then return end

    RenderScriptCams(false, (easeMs or 0) > 0, easeMs or 0, true, false)
    DestroyCam(active, false)
    active = nil
end

---@return number?
function camera.handle()
    return active
end

return camera
