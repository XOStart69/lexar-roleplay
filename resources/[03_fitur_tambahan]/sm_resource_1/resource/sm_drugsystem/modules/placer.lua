local config = localmodule 'config.shared'

local DISABLED_CONTROLS = { 24, 25, 37, 38, 44, 140, 141, 142, 177, 191, 199, 200 }
local ROTATE_LEFT = 44
local ROTATE_RIGHT = 38
local CONFIRM = 191
local CANCEL = 177
local RAY_FLAGS = 17
local RAY_IGNORE = 4
local ROTATE_STEP = 1.5
local GHOST_ALPHA = 150
local VALID_OUTLINE = { 0, 255, 0, 150 }
local INVALID_OUTLINE = { 255, 0, 0, 150 }

local Placer = {}

---@param valid boolean
local function setOutline(valid)
    local color = valid and VALID_OUTLINE or INVALID_OUTLINE

    SetEntityDrawOutlineColor(color[1], color[2], color[3], color[4])
end

---@param model string
---@return vector3?
---@return number?
function Placer.start(model)
    local hash = lib.requestModel(model)
    local origin = GetEntityCoords(cache.ped)
    local ghost = CreateObjectNoOffset(hash, origin.x, origin.y, origin.z, false, false, false)
    local heading = GetEntityHeading(cache.ped)
    local valid = false
    local coords

    SetModelAsNoLongerNeeded(hash)
    SetEntityAlpha(ghost, GHOST_ALPHA, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetEntityDrawOutline(ghost, true)
    setOutline(valid)
    lib.showTextUI('[Q/E] Putar  [Enter] Pasang  [Backspace] Batal')

    while true do
        for i = 1, #DISABLED_CONTROLS do
            DisableControlAction(0, DISABLED_CONTROLS[i], true)
        end

        local pedCoords = GetEntityCoords(cache.ped)
        local reach = #(GetFinalRenderedCamCoord() - pedCoords) + config.placeDistance
        local hit, _, endCoords = lib.raycast.fromCamera(RAY_FLAGS, RAY_IGNORE, reach)
        local inRange = hit and #(endCoords - pedCoords) <= config.placeDistance

        if hit then
            coords = endCoords
            SetEntityCoordsNoOffset(ghost, coords.x, coords.y, coords.z, false, false, false)
        end

        if inRange ~= valid then
            valid = inRange
            setOutline(valid)
        end

        if IsDisabledControlPressed(0, ROTATE_LEFT) then
            heading -= ROTATE_STEP
        elseif IsDisabledControlPressed(0, ROTATE_RIGHT) then
            heading += ROTATE_STEP
        end

        SetEntityHeading(ghost, heading)

        if IsDisabledControlJustPressed(0, CANCEL) or cache.vehicle then
            coords = nil
            break
        end

        if valid and IsDisabledControlJustPressed(0, CONFIRM) then break end
    end

    lib.hideTextUI()
    SetEntityDrawOutline(ghost, false)
    DeleteEntity(ghost)

    if coords then
        return coords, heading % 360.0
    end
end

return Placer
