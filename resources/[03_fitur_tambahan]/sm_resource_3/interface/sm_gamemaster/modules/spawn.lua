local config = localmodule 'config'
local state = localmodule 'modules.state'
local util = localmodule 'modules.util'
local camera = localmodule 'modules.camera'
local control = localmodule 'modules.control'
local orders = localmodule 'modules.orders'
local nui = localmodule 'modules.nui'

local type = type
local joaat = joaat
local sfind = string.find
local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local IsModelInCdimage = IsModelInCdimage
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local CreatePed = CreatePed
local CreateVehicle = CreateVehicle
local CreateObjectNoOffset = CreateObjectNoOffset
local SetEntityAlpha = SetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityInvincible = SetEntityInvincible
local SetEntityVisible = SetEntityVisible
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityHeading = SetEntityHeading
local FreezeEntityPosition = FreezeEntityPosition
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local SetPedRandomComponentVariation = SetPedRandomComponentVariation
local SetPedRandomProps = SetPedRandomProps
local SetVehicleOnGroundProperly = SetVehicleOnGroundProperly
local SetVehicleEngineOn = SetVehicleEngineOn
local NetworkDoesEntityExistWithNetworkId = NetworkDoesEntityExistWithNetworkId
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local IsThisModelAHeli = IsThisModelAHeli
local IsThisModelAPlane = IsThisModelAPlane
local IsThisModelABoat = IsThisModelABoat
local IsThisModelAJetski = IsThisModelAJetski
local IsThisModelABike = IsThisModelABike
local IsThisModelABicycle = IsThisModelABicycle
local IsThisModelATrain = IsThisModelATrain

local PREVIEW_ALPHA = config.spawn.previewAlpha
local PED_OFFSET = 1.0

local TRAILERS = {
    tanker = true,
    tanker2 = true,
    tr2 = true,
    tr3 = true,
    tr4 = true,
    trflat = true,
    armytanker = true,
}

local spawn = {}

---@type { entity: integer, model?: string, kind?: string, loading: boolean, x: number, y: number, vx: number, vy: number }
local preview = { entity = 0, model = nil, kind = nil, loading = false, x = 0.0, y = 0.0, vx = 0.0, vy = 0.0 }
---@type { start: vector3, heading: number, startAt: integer, moved: boolean }?
local hold = nil

---@param hash integer
---@return boolean
local function loadModel(hash)
    if not IsModelInCdimage(hash) then return false end

    RequestModel(hash)

    local tries = 0

    while not HasModelLoaded(hash) do
        tries += 1

        if tries > 250 then return false end

        Wait(20)
    end

    return true
end

---@param model string
---@return string?
function spawn.vehicleType(model)
    local hash = joaat(model)

    if IsThisModelATrain(hash) then return nil end
    if IsThisModelAHeli(hash) then return 'heli' end
    if IsThisModelAPlane(hash) then return 'plane' end
    if IsThisModelABoat(hash) or IsThisModelAJetski(hash) then return 'boat' end
    if IsThisModelABike(hash) or IsThisModelABicycle(hash) then return 'bike' end
    if sfind(model, 'submersible', 1, true) then return 'submarine' end
    if TRAILERS[model] or sfind(model, 'trailer', 1, true) then return 'trailer' end

    return 'automobile'
end

function spawn.clearPreview()
    local entity = preview.entity

    preview.entity = 0
    preview.model = nil
    preview.kind = nil

    if entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param item GmItem
---@param coords vector3
local function createPreview(item, coords)
    preview.loading = true
    preview.model = item.model
    preview.kind = item.kind

    CreateThread(function()
        local hash = joaat(item.model)
        local loaded = loadModel(hash)
        local current = state.item

        preview.loading = false

        if not loaded or not current or current.model ~= item.model or preview.model ~= item.model then
            SetModelAsNoLongerNeeded(hash)
            return
        end

        local heading = state.heading
        local entity

        if item.kind == 'ped' then
            entity = CreatePed(4, hash, coords.x, coords.y, coords.z + PED_OFFSET, heading, false, false)
            SetBlockingOfNonTemporaryEvents(entity, true)
            SetPedRandomComponentVariation(entity, 0)
        elseif item.kind == 'vehicle' then
            entity = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, false, false)
        else
            entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
        end

        SetModelAsNoLongerNeeded(hash)

        if not entity or entity == 0 then return end

        SetEntityAlpha(entity, PREVIEW_ALPHA, false)
        SetEntityCollision(entity, false, false)
        SetEntityInvincible(entity, true)
        FreezeEntityPosition(entity, true)

        if preview.entity ~= 0 or preview.model ~= item.model then
            DeleteEntity(entity)
            return
        end

        preview.entity = entity
        preview.x = coords.x
        preview.y = coords.y
        preview.vx = 0.0
        preview.vy = 0.0
    end)
end

---@param dt number
function spawn.updatePreview(dt)
    local item = state.item

    if not item or state.mode ~= 'spawn' or not state.options.preview or state.placing then
        if preview.entity ~= 0 or preview.model then
            spawn.clearPreview()
        end

        return
    end

    if preview.model ~= item.model then
        spawn.clearPreview()
    end

    local target = hold and hold.start or camera.ground(preview.entity ~= 0 and preview.entity or nil)

    if not target then return end

    if preview.entity == 0 then
        if not preview.loading and not preview.model then
            createPreview(item, target)
        end

        return
    end

    local entity = preview.entity

    if state.overUi then
        SetEntityVisible(entity, false, false)
        return
    end

    SetEntityVisible(entity, true, false)

    preview.x, preview.vx = util.smoothDamp(preview.x, target.x, preview.vx, 0.06, 120.0, dt)
    preview.y, preview.vy = util.smoothDamp(preview.y, target.y, preview.vy, 0.06, 120.0, dt)

    local z = target.z

    if preview.kind == 'ped' then
        z = z + PED_OFFSET
    end

    SetEntityCoordsNoOffset(entity, preview.x, preview.y, z, false, false, false)
    SetEntityHeading(entity, hold and hold.heading or state.heading)

    if preview.kind == 'vehicle' then
        SetVehicleOnGroundProperly(entity)
    end
end

---@param coords vector3
function spawn.holdStart(coords)
    hold = { start = coords, heading = state.heading, startAt = GetGameTimer(), moved = false }
end

---@param coords? vector3
function spawn.holdUpdate(coords)
    if not hold or not coords then return end

    local dx = coords.x - hold.start.x
    local dy = coords.y - hold.start.y

    if dx * dx + dy * dy > 0.0625 then
        hold.moved = true
        hold.heading = util.headingFrom(dx, dy)
    end
end

---@return { start: vector3, heading: number, startAt: integer, moved: boolean }?
function spawn.hold()
    return hold
end

---@param coords? vector3
---@return vector3?, number?
function spawn.holdEnd(coords)
    local current = hold

    hold = nil

    if not current then return nil end

    if current.moved or GetGameTimer() - current.startAt > 200 then
        return current.start, current.heading
    end

    return coords or current.start, state.heading
end

---@param netId integer
---@return integer
local function resolve(netId)
    local tries = 0

    while not NetworkDoesEntityExistWithNetworkId(netId) do
        tries += 1

        if tries > 100 then return 0 end

        Wait(50)
    end

    return NetworkGetEntityFromNetworkId(netId)
end

---@param kind 'ped'|'vehicle'
---@param entity integer
---@param ambient boolean
function spawn.after(kind, entity, ambient)
    if not control.one(entity) then return end

    if kind == 'ped' then
        SetPedRandomComponentVariation(entity, 0)
        SetPedRandomProps(entity)

        if ambient then
            orders.ambient(entity)
        else
            orders.stabilize(entity)
        end

        return
    end

    SetVehicleOnGroundProperly(entity)
    SetVehicleEngineOn(entity, true, true, false)
end

---@param kind 'ped'|'vehicle'
---@param model string
---@param coords vector3
---@param heading number
---@return table?
function spawn.payload(kind, model, coords, heading)
    local payload = { kind = kind, model = model, coords = coords, heading = heading }

    if kind == 'vehicle' then
        local vehicleType = spawn.vehicleType(model)

        if not vehicleType then return nil end

        payload.vehicleType = vehicleType
    end

    return payload
end

---@param kind 'ped'|'vehicle'
---@param model string
---@param coords vector3
---@param heading number
---@return integer
function spawn.request(kind, model, coords, heading)
    local payload = spawn.payload(kind, model, coords, heading)

    if not payload then
        nui.log('error', ('Model %s tidak bisa di-spawn'):format(model))
        return 0
    end

    local result = lib.callback.await('sm_gamemaster:server:spawn', false, payload)

    if type(result) ~= 'table' or not result.ok then
        nui.log('error', type(result) == 'table' and result.reason or 'Server tidak merespons')
        return 0
    end

    local entity = resolve(result.netId)

    if entity == 0 then
        nui.log('warn', 'Entitas dibuat tapi belum terlihat di sekitar kamera')
        return 0
    end

    spawn.after(kind, entity, state.options.ambient)
    nui.log('success', ('%s di-spawn: %s'):format(kind == 'ped' and 'NPC' or 'Kendaraan', model))

    return entity
end

return spawn
