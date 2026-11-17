local config = localmodule 'config.shared'
local props = localmodule 'data.props'
local Growth = localmodule 'modules.growth'

local ZERO = vec3(0.0, 0.0, 0.0)
local MIN_SCALE = 0.05

local SCALES = {
    weed = function(stage, share)
        if stage == 1 then return share end
        if stage == 2 then return math.max(share, 0.6) end
        if stage == 3 then return math.max(share, 0.55) end

        return 1.0
    end,
    coca = function(stage, share)
        if stage == 1 then return share * 0.4 end
        if stage == 2 then return 0.4 + share * 0.2 end
        if stage == 3 then return 0.6 + share * 0.4 end

        return 1.0
    end,
}

---@class DrugClientState
---@field soil? boolean
---@field seed? string
---@field watered? boolean
---@field lamp? boolean
---@field progress? number
---@field remaining? number
---@field amount? integer
---@field batches? integer
---@field cooking? boolean

---@class DrugParts
---@field main integer
---@field ready integer[]
---@field items integer[]
---@field soil? integer
---@field plant? integer
---@field plantModel? integer
---@field scale? number
---@field flask? integer
---@field liquid? integer
---@field flame? integer
---@field steam? integer
---@field door? integer
---@field trayModel? integer
---@field done? boolean

---@class DrugClientObject
---@field id integer
---@field kind string
---@field coords vector3
---@field heading number
---@field state DrugClientState
---@field receivedAt integer
---@field options table[]
---@field optionNames string[]
---@field point? CPoint
---@field parts? DrugParts
---@field visible? boolean
---@field removed? boolean
---@field locked? boolean
---@field syncing? boolean
---@field dirty? boolean

local Render = {}

---@param model integer | string
---@param coords vector3
---@param solid? boolean
---@return integer
function Render.create(model, coords, solid)
    local hash = lib.requestModel(model)
    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)

    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(entity, true)

    if not solid then
        SetEntityCollision(entity, false, false)
    end

    return entity
end

---@param entity integer
---@param parent integer
---@param offset vector3
---@param rotation? vector3
function Render.attach(entity, parent, offset, rotation)
    rotation = rotation or ZERO

    AttachEntityToEntity(entity, parent, 0, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, false, false, false, false, props.attachOrder, true)
end

---@param entity? integer
function Render.delete(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param obj DrugClientObject
---@return number
function Render.progress(obj)
    local state = obj.state

    if not state.progress then return 0 end

    return Growth.progress(state.progress, obj.receivedAt / 1000, state.lamp, GetGameTimer() / 1000)
end

---@param obj DrugClientObject
---@return number?
function Render.timeLeft(obj)
    local remaining = obj.state.remaining

    if not remaining then return end

    return math.max(0, remaining - (GetGameTimer() - obj.receivedAt) / 1000)
end

---@param entity integer
---@param scale number
local function setScale(entity, scale)
    local x, y, z, at = GetEntityMatrix(entity)

    scale = math.max(scale, MIN_SCALE)
    x, y, z = norm(x) * scale, norm(y) * scale, norm(z) * scale
    SetEntityMatrix(entity, x.x, x.y, x.z, y.x, y.y, y.z, z.x, z.y, z.z, at.x, at.y, at.z)
end

---@param parts DrugParts
local function clearPlant(parts)
    for i = 1, #parts.ready do
        Render.delete(parts.ready[i])
    end

    table.wipe(parts.ready)
    Render.delete(parts.plant)
    parts.plant = nil
    parts.plantModel = nil
    parts.scale = nil
end

---@param parts DrugParts
---@param ready { model: integer, points: vector3[][] }
local function fillReady(parts, ready)
    for i = 1, #ready.points do
        local entity = parts.ready[i]

        if not entity or not DoesEntityExist(entity) then
            local point = ready.points[i]

            entity = Render.create(ready.model, GetEntityCoords(parts.plant))
            Render.attach(entity, parts.plant, point[1], point[2])
            parts.ready[i] = entity
        end
    end
end

---@param obj DrugClientObject
local function refreshPot(obj)
    local parts = obj.parts --[[@as DrugParts]]
    local state = obj.state
    local pot = props.pot

    if state.soil and not parts.soil then
        parts.soil = Render.create(pot.soil, obj.coords)
        Render.attach(parts.soil, parts.main, ZERO)
    elseif not state.soil and parts.soil then
        Render.delete(parts.soil)
        parts.soil = nil
    end

    if parts.soil then
        SetEntityVisible(parts.soil, true, false)
        SetObjectTextureVariation(parts.soil, state.watered and pot.wetSoil or pot.drySoil)
    end

    local plant = props.plants[state.seed]

    if not plant or not state.progress then
        return clearPlant(parts)
    end

    local stage, share = Growth.stage(Render.progress(obj))

    if stage == 0 then
        return clearPlant(parts)
    end

    local model = plant.models[math.min(stage, #plant.models)]

    if parts.plantModel ~= model then
        clearPlant(parts)

        local coords = GetOffsetFromEntityInWorldCoords(parts.main, 0.0, 0.0, pot.plantHeight)

        parts.plant = Render.create(model, coords)
        parts.plantModel = model
        SetEntityHeading(parts.plant, obj.heading)
    end

    local scale = math.floor(SCALES[state.seed](stage, share) * 100 + 0.5) / 100

    if parts.scale ~= scale then
        setScale(parts.plant, scale)
        parts.scale = scale
    end

    if stage == 4 then
        fillReady(parts, plant.ready)
    end
end

---@param entity integer
---@param fx { dict: string, name: string, offset: vector3, rotation: vector3, scale: number }
---@return integer
local function startLoop(entity, fx)
    lib.requestNamedPtfxAsset(fx.dict)
    UseParticleFxAsset(fx.dict)

    return StartParticleFxLoopedOnEntity(fx.name, entity, fx.offset.x, fx.offset.y, fx.offset.z, fx.rotation.x, fx.rotation.y, fx.rotation.z, fx.scale, false, false, false)
end

---@param handle? integer
local function stopLoop(handle)
    if handle then
        StopParticleFxLooped(handle, false)
    end
end

---@param parts DrugParts
---@param model integer
---@param slots vector3[][]
---@param count integer
local function fillSlots(parts, model, slots, count)
    local items = parts.items

    count = math.min(count, #slots)

    for i = #items, count + 1, -1 do
        Render.delete(items[i])
        items[i] = nil
    end

    for i = #items + 1, count do
        local slot = slots[i]
        local entity = Render.create(model, GetEntityCoords(parts.main))

        Render.attach(entity, parts.main, slot[1], slot[2])
        items[i] = entity
    end
end

---@param obj DrugClientObject
local function refreshTable(obj)
    local parts = obj.parts --[[@as DrugParts]]
    local data = props.table
    local cooking = obj.state.cooking == true

    if not parts.flask then
        parts.flask = Render.create(data.flask.model, obj.coords)
    end

    Render.attach(parts.flask, parts.main, data.flask.offset)

    if cooking and not parts.liquid then
        parts.liquid = Render.create(data.liquid.model, obj.coords)
        SetObjectTextureVariation(parts.liquid, data.liquid.texture)
        Render.attach(parts.liquid, parts.flask, ZERO)
    elseif not cooking and parts.liquid then
        Render.delete(parts.liquid)
        parts.liquid = nil
    end

    if cooking and not parts.flame then
        parts.flame = startLoop(parts.main, data.flame)
    elseif not cooking and parts.flame then
        stopLoop(parts.flame)
        parts.flame = nil
    end
end

---@param obj DrugClientObject
local function refreshDry(obj)
    local state = obj.state

    fillSlots(obj.parts --[[@as DrugParts]], props.dry.model, props.dry.slots, state.remaining and (state.batches or state.amount) or 0)
end

---@param obj DrugClientObject
---@param left? number
local function refreshCauldron(obj, left)
    local parts = obj.parts --[[@as DrugParts]]
    local data = props.cauldron
    local boiling = left ~= nil and left > 0

    if boiling and not parts.steam then
        parts.steam = startLoop(parts.main, data.steam)
    elseif not boiling and parts.steam then
        stopLoop(parts.steam)
        parts.steam = nil
    end

    fillSlots(parts, data.model, data.slots, left == 0 and obj.state.amount or 0)
end

---@param obj DrugClientObject
---@param left? number
local function refreshChiller(obj, left)
    local parts = obj.parts --[[@as DrugParts]]
    local data = props.chiller
    local model = left and (left > 0 and data.tray or data.frozen)

    if not parts.door then
        parts.door = Render.create(data.door.model, obj.coords)
    end

    Render.attach(parts.door, parts.main, data.door.offset)

    if parts.trayModel ~= model then
        fillSlots(parts, model, data.slots, 0)
        parts.trayModel = model
    end

    if model then
        fillSlots(parts, model, data.slots, obj.state.batches or 1)
    end

    for i = 1, #parts.items do
        SetEntityVisible(parts.items[i], true, false)
    end
end

---@param obj DrugClientObject
local function spawn(obj)
    local main = Render.create(config.equipment[obj.kind].model, obj.coords, true)

    SetEntityHeading(main, obj.heading)
    obj.parts = { main = main, ready = {}, items = {} }
    ox_target:addLocalEntity(main, obj.options)
end

---@param obj DrugClientObject
local function despawn(obj)
    local parts = obj.parts --[[@as DrugParts]]

    ox_target:removeLocalEntity(parts.main, obj.optionNames)
    clearPlant(parts)
    stopLoop(parts.flame)
    stopLoop(parts.steam)

    for i = 1, #parts.items do
        Render.delete(parts.items[i])
    end

    Render.delete(parts.soil)
    Render.delete(parts.liquid)
    Render.delete(parts.flask)
    Render.delete(parts.door)
    Render.delete(parts.main)
    obj.parts = nil
end

---@param obj DrugClientObject
local function refresh(obj)
    local group = config.equipment[obj.kind].group

    if group == 'pot' then
        return refreshPot(obj)
    end

    local left = Render.timeLeft(obj)

    if group == 'table' then
        refreshTable(obj)
    elseif group == 'dry' then
        refreshDry(obj)
    elseif group == 'cauldron' then
        refreshCauldron(obj, left)
    elseif group == 'chiller' then
        refreshChiller(obj, left)
    end

    obj.parts.done = left == 0
end

---@param obj DrugClientObject
local function sync(obj)
    repeat
        obj.dirty = false

        if obj.visible and not obj.removed then
            if not obj.parts then
                spawn(obj)
            end

            if not obj.locked then
                refresh(obj)
            end
        elseif obj.parts then
            despawn(obj)
        end
    until not obj.dirty
end

---@param obj DrugClientObject
function Render.sync(obj)
    if obj.syncing then
        obj.dirty = true
        return
    end

    obj.syncing = true

    local ok, err = pcall(sync, obj)

    obj.syncing = false

    if not ok then
        lib.print.error(err)
    end
end

---@param obj DrugClientObject
---@return boolean
function Render.animated(obj)
    local parts = obj.parts

    if not parts or obj.locked then return false end

    local group = config.equipment[obj.kind].group

    if group == 'pot' then
        return obj.state.progress ~= nil and #parts.ready == 0
    end

    return obj.state.remaining ~= nil and not parts.done
end

---@param obj DrugClientObject
function Render.clear(obj)
    if obj.parts then
        despawn(obj)
    end
end

return Render
