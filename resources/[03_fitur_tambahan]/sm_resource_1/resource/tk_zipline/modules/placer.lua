local shared = localmodule 'modules.shared'

local MAX_PLACE_DIST = 10.0
local MIN_PLAYER_DIST = 3.0
local ROTATE_STEP = 5.0
local CONTROL_CANCEL = 194
local CONTROL_PLACE = 38
local CONTROL_ROTATE_LEFT = 14
local CONTROL_ROTATE_RIGHT = 15

local ZiplinePlacer = {}

local function outline(entity, canPlace)
    SetEntityDrawOutline(entity, true)
    SetEntityDrawOutlineShader(1)

    if canPlace then
        SetEntityDrawOutlineColor(0, 255, 0, 255)
    else
        SetEntityDrawOutlineColor(255, 0, 0, 255)
    end
end

---Spawn ghost props the player aims to position, then resolve with the chosen coords.
---@param props { model: number, offset: vector3? }[]
---@param onPlace fun(coords: vector3?, heading: number?)
function ZiplinePlacer.start(props, onPlace)
    local ghosts = {}
    local ped = cache.ped
    local coords = GetEntityCoords(ped)

    -- Load every model up front so a failure cancels cleanly instead of
    -- leaving half the ghost props floating in the world.
    for i = 1, #props do
        local model = props[i].model

        if not pcall(lib.requestModel, model, 5000) or not HasModelLoaded(model) then
            print(('[tk_zipline] model %s gagal dimuat - cek config/shared.lua'):format(model))
            onPlace(nil)
            return
        end
    end

    for i = 1, #props do
        local prop = props[i]

        local entity = CreateObjectNoOffset(prop.model, coords.x, coords.y, coords.z, false, false, false)

        SetEntityAlpha(entity, 102, false)
        SetEntityCollision(entity, false, false)
        SetEntityRotation(entity, 0.0, 0.0, 0.0, 2, true)

        ghosts[i] = { entity = entity, offset = prop.offset or vec3(0.0, 0.0, 0.0) }
    end

    local anchor = ghosts[1].entity
    local heading = 0.0
    local placing = true

    local function cleanup()
        placing = false

        for i = 1, #ghosts do
            DeleteEntity(ghosts[i].entity)
        end
    end

    CreateThread(function()
        while placing do
            local hit, _, target = lib.raycast.fromCamera(511, 4, MAX_PLACE_DIST)
            local playerCoords = GetEntityCoords(ped)
            local canPlace = hit and #(target - playerCoords) < MIN_PLAYER_DIST

            if hit then
                for i = 1, #ghosts do
                    local ghost = ghosts[i]
                    local offset = shared.rotateVector(ghost.offset, heading)

                    SetEntityCoordsNoOffset(ghost.entity, target.x + offset.x, target.y + offset.y, target.z + offset.z, false, false, false)
                    SetEntityRotation(ghost.entity, 0.0, 0.0, heading, 2, true)
                    outline(ghost.entity, canPlace)
                end
            end

            if IsControlJustPressed(0, CONTROL_CANCEL) then
                cleanup()
                onPlace(nil)
                return
            end

            if IsControlJustPressed(0, CONTROL_ROTATE_LEFT) then
                heading = (heading - ROTATE_STEP) % 360.0
            elseif IsControlJustPressed(0, CONTROL_ROTATE_RIGHT) then
                heading = (heading + ROTATE_STEP) % 360.0
            end

            if canPlace and IsControlJustPressed(0, CONTROL_PLACE) then
                local placed = GetEntityCoords(anchor) - shared.rotateVector(ghosts[1].offset, heading)

                cleanup()
                onPlace(placed, heading)
                return
            end

            Wait(0)
        end
    end)
end

return ZiplinePlacer
