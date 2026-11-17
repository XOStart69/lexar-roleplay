local config = localmodule 'config'
local state = localmodule 'modules.state'
local objects = localmodule 'modules.objects'
local keys = localmodule 'modules.keys'

local tremove = table.remove
local min = math.min
local max = math.max
local DoesEntityExist = DoesEntityExist
local IsEntityAPed = IsEntityAPed
local IsEntityAVehicle = IsEntityAVehicle
local IsPedAPlayer = IsPedAPlayer
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local GetEntityCoords = GetEntityCoords
local GetGamePool = GetGamePool
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehicleModelNumberOfSeats = GetVehicleModelNumberOfSeats
local GetEntityModel = GetEntityModel
local GetPedBoneCoords = GetPedBoneCoords
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetVehiclePedIsIn = GetVehiclePedIsIn

local SELECT_RADIUS_SQ = config.selectRadius * config.selectRadius
local HEAD_BONE = 31086

local selection = {}

---@param entity integer
---@return boolean
function selection.isPed(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if not IsEntityAPed(entity) or IsPedAPlayer(entity) then return false end

    return NetworkGetEntityIsNetworked(entity)
end

---@param entity integer
---@return boolean
function selection.isVehicle(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if not IsEntityAVehicle(entity) then return false end

    return NetworkGetEntityIsNetworked(entity)
end

---@param entity integer
---@return boolean
function selection.isObject(entity)
    if not entity or entity == 0 then return false end

    return objects.idOf(entity) ~= nil and DoesEntityExist(entity)
end

---@param entity integer
---@return boolean
function selection.pickable(entity)
    local options = state.options

    if options.pickPeds and selection.isPed(entity) then return true end
    if options.pickVehicles and selection.isVehicle(entity) then return true end
    if options.pickObjects and selection.isObject(entity) then return true end

    return false
end

---@param entity integer
---@return boolean
function selection.has(entity)
    return state.selected[entity] == true
end

---@param entity integer
---@return boolean
function selection.add(entity)
    if state.selected[entity] or not selection.pickable(entity) then return false end

    local list = state.selection

    list[#list + 1] = entity
    state.selected[entity] = true
    state.selectionDirty = true

    return true
end

---@param entity integer
---@return boolean
function selection.remove(entity)
    if not state.selected[entity] then return false end

    local list = state.selection

    for i = #list, 1, -1 do
        if list[i] == entity then
            tremove(list, i)
            break
        end
    end

    state.selected[entity] = nil
    state.selectionDirty = true

    return true
end

function selection.clear()
    if #state.selection == 0 then return end

    state.selection = {}
    state.selected = {}
    state.selectionDirty = true
end

---@param entities integer[]
function selection.set(entities)
    state.selection = {}
    state.selected = {}
    state.selectionDirty = true

    for i = 1, #entities do
        selection.add(entities[i])
    end
end

---@param entity integer
function selection.only(entity)
    state.selection = { entity }
    state.selected = { [entity] = true }
    state.selectionDirty = true
end

---@return boolean
function selection.prune()
    local list = state.selection
    local changed = false

    for i = #list, 1, -1 do
        local entity = list[i]

        if not DoesEntityExist(entity) then
            tremove(list, i)
            state.selected[entity] = nil
            changed = true
        end
    end

    if changed then
        state.selectionDirty = true
    end

    return changed
end

---@return integer[]
function selection.peds()
    local result = {}
    local count = 0
    local list = state.selection

    for i = 1, #list do
        local entity = list[i]

        if selection.isPed(entity) then
            count += 1
            result[count] = entity
        end
    end

    return result
end

---@return integer[]
function selection.vehicles()
    local result = {}
    local count = 0
    local list = state.selection

    for i = 1, #list do
        local entity = list[i]

        if selection.isVehicle(entity) then
            count += 1
            result[count] = entity
        end
    end

    return result
end

---@return integer[]
function selection.actors()
    local result = {}
    local seen = {}
    local count = 0
    local list = state.selection

    for i = 1, #list do
        local entity = list[i]
        local ped = 0

        if selection.isPed(entity) then
            ped = entity
        elseif selection.isVehicle(entity) then
            local driver = GetPedInVehicleSeat(entity, -1)

            if driver ~= 0 and not IsPedAPlayer(driver) then
                ped = driver
            end
        end

        if ped ~= 0 and not seen[ped] then
            seen[ped] = true
            count += 1
            result[count] = ped
        end
    end

    return result
end

---@return integer[] netIds, string[] objectIds
function selection.deletable()
    local netIds = {}
    local objectIds = {}
    local netCount = 0
    local objectCount = 0
    local list = state.selection

    for i = 1, #list do
        local entity = list[i]
        local objectId = objects.idOf(entity)

        if objectId then
            objectCount += 1
            objectIds[objectCount] = objectId
        elseif DoesEntityExist(entity) and NetworkGetEntityIsNetworked(entity) then
            netCount += 1
            netIds[netCount] = NetworkGetNetworkIdFromEntity(entity)
        end
    end

    return netIds, objectIds
end

---@param entity integer
---@return vector3
function selection.anchor(entity)
    if IsEntityAPed(entity) then
        return GetPedBoneCoords(entity, HEAD_BONE, 0.0, 0.0, 0.0)
    end

    return GetEntityCoords(entity)
end

---@param entity integer
---@param minX number
---@param maxX number
---@param minY number
---@param maxY number
---@return boolean
local function insideRect(entity, minX, maxX, minY, maxY)
    local coords = GetEntityCoords(entity)
    local cam = state.camPos
    local dx = coords.x - cam.x
    local dy = coords.y - cam.y
    local dz = coords.z - cam.z

    if dx * dx + dy * dy + dz * dz > SELECT_RADIUS_SQ then return false end

    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

    if not onScreen then return false end

    return sx >= minX and sx <= maxX and sy >= minY and sy <= maxY
end

---@param pool integer[]
---@param check fun(entity: integer): boolean
---@param minX number
---@param maxX number
---@param minY number
---@param maxY number
---@param subtract boolean
local function sweep(pool, check, minX, maxX, minY, maxY, subtract)
    for i = 1, #pool do
        local entity = pool[i]

        if check(entity) and insideRect(entity, minX, maxX, minY, maxY) then
            if subtract then
                selection.remove(entity)
            else
                selection.add(entity)
            end
        end
    end
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function selection.rect(x1, y1, x2, y2)
    local minX = min(x1, x2)
    local maxX = max(x1, x2)
    local minY = min(y1, y2)
    local maxY = max(y1, y2)
    local additive = keys.shift()
    local subtract = keys.ctrl()

    if not additive and not subtract then
        selection.clear()
    end

    local options = state.options

    if options.pickPeds then
        sweep(GetGamePool('CPed'), selection.isPed, minX, maxX, minY, maxY, subtract)
    end

    if options.pickVehicles then
        sweep(GetGamePool('CVehicle'), selection.isVehicle, minX, maxX, minY, maxY, subtract)
    end

    if options.pickObjects then
        sweep(objects.entities(), selection.isObject, minX, maxX, minY, maxY, subtract)
    end
end

---@param vehicle integer
---@return integer?
function selection.occupantNear(vehicle)
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    local best = nil
    local bestDist = 0.0016

    for seat = -1, seats - 2 do
        local ped = GetPedInVehicleSeat(vehicle, seat)

        if ped ~= 0 and not IsPedAPlayer(ped) then
            local coords = GetPedBoneCoords(ped, HEAD_BONE, 0.0, 0.0, 0.0)
            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

            if onScreen then
                local dx = state.cursorX - sx
                local dy = state.cursorY - sy
                local dist = dx * dx + dy * dy

                if dist < bestDist then
                    bestDist = dist
                    best = ped
                end
            end
        end
    end

    return best
end

---@param ped integer
---@return integer
function selection.vehicleOf(ped)
    if not IsPedInAnyVehicle(ped, false) then return 0 end

    return GetVehiclePedIsIn(ped, false)
end

return selection
