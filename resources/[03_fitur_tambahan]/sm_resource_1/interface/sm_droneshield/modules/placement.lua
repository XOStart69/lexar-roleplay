local config = localmodule 'config.shared'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityHeading = SetEntityHeading
local SetEntityVisible = SetEntityVisible
local SetEntityDrawOutline = SetEntityDrawOutline
local SetEntityDrawOutlineColor = SetEntityDrawOutlineColor
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local DisableControlAction = DisableControlAction
local IsDisabledControlPressed = IsDisabledControlPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsEntityDead = IsEntityDead
local IsPedInAnyVehicle = IsPedInAnyVehicle
local StartShapeTestBox = StartShapeTestBox
local GetShapeTestResult = GetShapeTestResult
local mathRad = math.rad
local mathSin = math.sin
local mathCos = math.cos
local mathAbs = math.abs

local text = config.text

local ROTATE_STEP = 5.0
local HEIGHT_STEP = 0.05
local HEIGHT_LIMIT = 5.0
local REPEAT_FIRST = 150
local REPEAT_NEXT = 50
local COLLISION_PADDING = 0.05
local RAY_FLAGS = 511
local HINT_ID = 'sm_droneshield_place'

local CONTROL_CONFIRM = 38
local CONTROL_CANCEL = 73
local CONTROL_GROUND = 47
local CONTROL_LEFT = 174
local CONTROL_RIGHT = 175
local CONTROL_UP = 172
local CONTROL_DOWN = 173
local BLOCKED = { 24, 25, 37, 44, 45, 47, 51, 73, 140, 141, 142, 172, 173, 174, 175, 257, 263, 264 }
local BLOCKED_COUNT = #BLOCKED

local placement = {}
local active

---@param description string
local function notify(description, kind)
    lib.notify({ title = text.title, description = description, type = kind or 'error' })
end

---@param value number
---@param low number
---@param high number
---@return number
local function clamp(value, low, high)
    return value < low and low or (value > high and high or value)
end

---@param model number
---@return vector3 size
---@return vector3 center
local function modelBox(model)
    local minDim, maxDim = GetModelDimensions(model)
    local sx, sy, sz = mathAbs(maxDim.x - minDim.x), mathAbs(maxDim.y - minDim.y), mathAbs(maxDim.z - minDim.z)
    local pad = COLLISION_PADDING * 2.0
    return vec3(sx + pad, sy + pad, sz + pad), vec3(minDim.x + sx * 0.5, minDim.y + sy * 0.5, minDim.z + sz * 0.5)
end

---@param model number
---@param coords vector3
---@param heading number
---@return vector3?
function placement.groundCoords(model, coords, heading)
    if not IsModelInCdimage(model) or not pcall(lib.requestModel, model) then return nil end
    local probe = CreateObjectNoOffset(model, coords.x, coords.y, coords.z + 1.0, false, false, false)
    SetModelAsNoLongerNeeded(model)
    if not probe or probe == 0 then return nil end
    SetEntityVisible(probe, false, false)
    SetEntityCollision(probe, false, false)
    SetEntityCoordsNoOffset(probe, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(probe, heading)
    PlaceObjectOnGroundProperly(probe)
    local grounded = GetEntityCoords(probe)
    DeleteEntity(probe)
    return grounded
end

---@return boolean
function placement.isActive()
    return active ~= nil
end

---@param state table
local function cleanup(state)
    if active ~= state then return end
    active = nil
    infoUI.remove(HINT_ID)
    if DoesEntityExist(state.preview) then
        DeleteEntity(state.preview)
    end
end

---@param state table
---@param now number
---@param control number
---@return boolean
local function repeatPressed(state, now, control)
    if not IsDisabledControlPressed(0, control) then
        state.repeatAt[control] = nil
        return false
    end
    local nextAt = state.repeatAt[control]
    if not nextAt then
        state.repeatAt[control] = now + REPEAT_FIRST
        return true
    end
    if now >= nextAt then
        state.repeatAt[control] = now + REPEAT_NEXT
        return true
    end
    return false
end

---@param state table
local function updateCollision(state)
    local coords, heading = state.coords, state.heading
    if state.testCoords ~= coords or state.testHeading ~= heading then
        local rad = mathRad(heading)
        local s, c = mathSin(rad), mathCos(rad)
        local center = state.center
        local size = state.size
        local cx = coords.x + center.x * c - center.y * s
        local cy = coords.y + center.x * s + center.y * c
        local cz = coords.z + center.z
        state.testHandle = StartShapeTestBox(cx, cy, cz, size.x, size.y, size.z, 0.0, 0.0, heading, 2, 126, state.preview, 4)
        state.testCoords = coords
        state.testHeading = heading
        state.blocked = true
        state.pending = true
    end

    if not state.pending then return end
    local status, hit = GetShapeTestResult(state.testHandle)
    if status ~= 2 then return end
    state.pending = false
    state.blocked = hit == 1 or hit == true
end

---@param state table
local function loop(state)
    local preview = state.preview
    local maxDistance = state.maxDistance
    local rayDistance = maxDistance + 2.0
    local outlined = false

    while active == state do
        local ped = cache.ped
        local now = GetGameTimer()

        if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or not state.canContinue() then
            cleanup(state)
            notify(text.placeCancelled, 'inform')
            break
        end

        for i = 1, BLOCKED_COUNT do
            DisableControlAction(0, BLOCKED[i], true)
        end

        if repeatPressed(state, now, CONTROL_RIGHT) then
            state.heading = (state.heading + ROTATE_STEP) % 360.0
        elseif repeatPressed(state, now, CONTROL_LEFT) then
            state.heading = (state.heading - ROTATE_STEP) % 360.0
        end

        if repeatPressed(state, now, CONTROL_UP) then
            state.height = clamp(state.height + HEIGHT_STEP, -HEIGHT_LIMIT, HEIGHT_LIMIT)
        elseif repeatPressed(state, now, CONTROL_DOWN) then
            state.height = clamp(state.height - HEIGHT_STEP, -HEIGHT_LIMIT, HEIGHT_LIMIT)
        end

        local hit, _, endCoords = lib.raycast.fromCamera(RAY_FLAGS, 4, rayDistance)
        if hit then
            state.lastHit = endCoords
        end
        local target = state.lastHit

        if target then
            SetEntityVisible(preview, true, false)
            SetEntityCoordsNoOffset(preview, target.x, target.y, target.z + state.height, false, false, false)
            SetEntityHeading(preview, state.heading)

            if IsDisabledControlJustPressed(0, CONTROL_GROUND) then
                PlaceObjectOnGroundProperly(preview)
                state.height = clamp(GetEntityCoords(preview).z - target.z, -HEIGHT_LIMIT, HEIGHT_LIMIT)
            end

            state.coords = GetEntityCoords(preview)
            updateCollision(state)

            local valid = not state.blocked and #(GetEntityCoords(ped) - state.coords) <= maxDistance
            state.valid = valid
            if valid == outlined then
                outlined = not valid
                SetEntityDrawOutline(preview, outlined)
            end
        else
            SetEntityVisible(preview, false, false)
            state.valid = false
        end

        if IsDisabledControlJustPressed(0, CONTROL_CANCEL) then
            cleanup(state)
            notify(text.placeCancelled, 'inform')
            break
        end

        if IsDisabledControlJustPressed(0, CONTROL_CONFIRM) then
            if state.valid and state.coords then
                local coords, heading = state.coords, state.heading
                cleanup(state)
                state.onConfirm(coords, heading)
                break
            end
            notify(text.placeInvalid)
        end

        Wait(0)
    end
end

---@param opts { model: number, maxDistance: number, heading: number, canContinue: fun(): boolean, onConfirm: fun(coords: vector3, heading: number) }
---@return boolean
function placement.start(opts)
    if active then
        notify(text.placeBusy)
        return false
    end

    local model = opts.model
    if not model or not IsModelInCdimage(model) or not pcall(lib.requestModel, model) then
        notify(text.placeUnavailable)
        return false
    end

    local preview = CreateObjectNoOffset(model, 0.0, 0.0, -200.0, false, false, false)
    SetModelAsNoLongerNeeded(model)
    if not preview or preview == 0 then
        notify(text.placeUnavailable)
        return false
    end

    SetEntityCollision(preview, false, false)
    FreezeEntityPosition(preview, true)
    SetEntityAlpha(preview, 160, false)
    SetEntityVisible(preview, false, false)
    SetEntityDrawOutlineColor(255, 60, 60, 200)

    local size, center = modelBox(model)
    local state = {
        preview = preview,
        size = size,
        center = center,
        maxDistance = opts.maxDistance,
        heading = opts.heading or 0.0,
        height = 0.0,
        repeatAt = {},
        blocked = true,
        pending = false,
        valid = false,
        canContinue = opts.canContinue,
        onConfirm = opts.onConfirm,
    }
    active = state

    infoUI.show({
        id = HINT_ID,
        title = text.title,
        icon = 'fa-solid fa-shield-halved',
        description = text.placeHint,
    })

    CreateThread(function()
        loop(state)
    end)
    return true
end

function placement.cancel()
    if active then
        cleanup(active)
    end
end

return placement
