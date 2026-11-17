local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'

local Wait = Wait
local CreateObject = CreateObject
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local random = math.random

local RESPAWN_DELAY = config.respawnDelay
local SPAWN_ATTEMPTS = config.spawnAttempts
local INTERACT_DISTANCE = config.interactDistance
local OBJECT_WEAPON = `OBJECT`
local UNARMED = `WEAPON_UNARMED`
local PICKUP_ANIM = { dict = 'anim@mp_snowball', clip = 'pickup_snowball', flag = 49 }
local GARDENER_ANIM = { scenario = 'world_human_gardener_plant' }

---@type table[]
local states = {}
local busy = false

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'error' })
end

---@param field table
---@param x number
---@param y number
---@return number
local function groundZ(field, x, y)
    local heights = field.groundHeights
    for i = 1, #heights do
        local found, z = GetGroundZFor_3dCoord(x, y, heights[i] + 0.0, false)
        if found then return z end
    end
    return field.fallbackZ
end

---@param state table
---@return vector3?
local function findSpot(state)
    local field = state.field
    local center, radius, minDistance = field.coords, field.spawnRadius, field.minDistance
    local plants = state.plants

    for _ = 1, SPAWN_ATTEMPTS do
        local x = center.x + (random() * 2 - 1) * radius
        local y = center.y + (random() * 2 - 1) * radius
        local spot = vector3(x, y, groundZ(field, x, y))

        local free = true
        for i = 1, #plants do
            if #(spot - plants[i].coords) < minDistance then
                free = false
                break
            end
        end

        if free then return spot end
    end
end

---@param plant table
local function removePlant(plant)
    local entity = plant.entity
    plant.entity = nil
    if not entity then return end

    ox_target:removeLocalEntity(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local pickPlant

---@param state table
---@return boolean
local function spawnOne(state)
    local spot = findSpot(state)
    if not spot then return false end

    local field = state.field
    local entity = CreateObject(state.model, spot.x, spot.y, spot.z, false, false, false)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)

    local plant = { entity = entity, coords = spot }
    state.plants[#state.plants + 1] = plant

    ox_target:addLocalEntity(entity, {
        {
            name = 'sm_drugfield_' .. field.key,
            label = field.label,
            icon = 'fa-solid fa-hand',
            distance = INTERACT_DISTANCE,
            onSelect = function() pickPlant(state, plant) end,
        },
    })

    return true
end

---@param state table
local function fillField(state)
    if state.filling then return end
    state.filling = true

    if pcall(lib.requestModel, state.model, 10000) then
        local plants, maxPlants = state.plants, state.field.maxPlants
        while state.streamed and #plants < maxPlants do
            if not spawnOne(state) then break end
            Wait(0)
        end
        SetModelAsNoLongerNeeded(state.model)
    end

    state.filling = false
end

---@param state table
local function clearField(state)
    local plants = state.plants
    for i = #plants, 1, -1 do
        removePlant(plants[i])
        plants[i] = nil
    end
end

---@param state table
---@param plant table
local function dropPlant(state, plant)
    local plants = state.plants
    for i = 1, #plants do
        if plants[i] == plant then
            table.remove(plants, i)
            break
        end
    end
    removePlant(plant)

    SetTimeout(RESPAWN_DELAY, function()
        if state.streamed then
            CreateThread(function() fillField(state) end)
        end
    end)
end

local function restoreWeapon()
    if GetSelectedPedWeapon(cache.ped) == OBJECT_WEAPON then
        SetCurrentPedWeapon(cache.ped, UNARMED, true)
    end
end

---@param state table
---@param plant table
pickPlant = function(state, plant)
    if busy or not state.inZone or not plant.entity or not IsPedOnFoot(cache.ped) then return end

    local field = state.field
    local required = field.requireItem
    if required and ox_inventory:Search('count', required) < 1 then
        return notify(('Kamu butuh %s!'):format(required))
    end

    busy = true

    local ok, reason = lib.callback.await('sm_drugfield:start', false, field.key)
    if not ok then
        busy = false
        return notify(reason or 'Tidak bisa mengambil sekarang.')
    end

    local done = lib.progressBar({
        duration = field.pickupTime,
        label = field.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = field.anim == 'gardener' and GARDENER_ANIM or PICKUP_ANIM,
    })

    restoreWeapon()

    if not done then
        lib.callback.await('sm_drugfield:cancel', false)
        busy = false
        return
    end

    local success, message = lib.callback.await('sm_drugfield:finish', false, field.key)
    if success then
        dropPlant(state, plant)
        notify(message, 'success')
    elseif message then
        notify(message)
    end

    busy = false
end

for i = 1, #config.fields do
    local field = config.fields[i]
    local state = { field = field, model = joaat(field.model), plants = {}, inZone = false, streamed = false, filling = false }
    states[i] = state

    lib.points.new({
        coords = field.coords,
        distance = field.radius + config.streamMargin,
        onEnter = function()
            state.streamed = true
            CreateThread(function() fillField(state) end)
        end,
        onExit = function()
            state.streamed = false
            clearField(state)
        end,
    })

    lib.zones.sphere({
        coords = field.coords,
        radius = field.radius,
        onEnter = function() state.inZone = true end,
        onExit = function() state.inZone = false end,
    })
end

---@return boolean
local function isInDrugField()
    for i = 1, #states do
        if states[i].inZone then return true end
    end
    return false
end

exportWrapper('sm_sidejob', 'isInDrugField', isInDrugField)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for i = 1, #states do
        clearField(states[i])
    end
end)
