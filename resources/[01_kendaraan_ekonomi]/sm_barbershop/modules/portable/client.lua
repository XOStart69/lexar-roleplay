local config = Config
local settings = config.portable
local Sync = require 'modules.sync.client'

local PLACE_CONTROL = 38
local CANCEL_CONTROL = 194
local ROTATE_LEFT_CONTROL = 174
local ROTATE_RIGHT_CONTROL = 175
local ROTATE_SPEED = 90.0
local RAY_FLAGS = 1 | 16
local RAY_EXTRA = 5.0
local MIN_NORMAL_Z = 0.9
local GHOST_ALPHA = 160
local BLOCKED_CONTROLS = { 14, 15, 16, 17, 24, 25, 37, 38, 44, 140, 141, 142, 174, 175, 194, 257, 263 }
local HINT = '[E] Pasang  [Panah Kiri/Kanan] Putar  [Backspace] Batal'

local model = joaat(settings.model)

---@class BarberPortableObject
---@field coords vector4
---@field point CPoint
---@field inside boolean
---@field entity number?

---@type table<string, BarberPortableObject>
local objects = {}

local placing = false

local function notify(notifyType, description)
    lib.notify({ type = notifyType, description = description })
end

---@param record BarberPortableObject
local function spawn(record)
    if record.entity then return end

    lib.requestModel(model)

    if not record.inside or record.entity then
        SetModelAsNoLongerNeeded(model)

        return
    end

    local coords = record.coords
    local entity = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)

    SetEntityHeading(entity, coords.w)
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(model)

    record.entity = entity
end

---@param record BarberPortableObject
local function despawn(record)
    if record.entity and DoesEntityExist(record.entity) then
        DeleteEntity(record.entity)
    end

    record.entity = nil
end

Sync.onPortables(function(list)
    ---@type table<string, boolean>
    local seen = {}

    for i = 1, #list do
        local entry = list[i]
        local id = tostring(entry.index)

        seen[id] = true

        if not objects[id] then
            ---@type BarberPortableObject
            local record

            record = {
                coords = entry.coords,
                inside = false,
                point = lib.points.new({
                    coords = entry.coords.xyz,
                    distance = settings.renderDistance,
                    onEnter = function()
                        record.inside = true
                        CreateThread(function() spawn(record) end)
                    end,
                    onExit = function()
                        record.inside = false
                        despawn(record)
                    end,
                }),
            }

            objects[id] = record
        end
    end

    for id, record in pairs(objects) do
        if not seen[id] then
            record.point:remove()
            record.inside = false
            despawn(record)
            objects[id] = nil
        end
    end
end)

---@param coords vector3
---@return boolean
local function crowded(coords)
    for i = 1, #config.shops do
        local list = config.shops[i].coords.chairs

        for j = 1, #list do
            if #(coords - list[j].xyz) < settings.spacing then return true end
        end
    end

    local list = Sync.portables()

    for i = 1, #list do
        if #(coords - list[i].coords.xyz) < settings.spacing then return true end
    end

    return false
end

---@return vector3? coords
---@return number? heading
local function choosePlacement()
    lib.requestModel(model)

    local ped = cache.ped
    local start = GetEntityCoords(ped)
    local ghost = CreateObjectNoOffset(model, start.x, start.y, start.z, false, false, false)
    local heading = GetEntityHeading(ped)
    local chosen

    SetModelAsNoLongerNeeded(model)
    SetEntityAlpha(ghost, GHOST_ALPHA, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetEntityDrawOutline(ghost, true)
    lib.showTextUI(HINT, { position = 'right-center' })

    while not (cache.vehicle or IsEntityDead(ped) or not LocalPlayer.state.barberDuty) do
        for i = 1, #BLOCKED_CONTROLS do
            DisableControlAction(0, BLOCKED_CONTROLS[i], true)
        end

        local hit, _, target, normal = lib.raycast.fromCamera(RAY_FLAGS, 4, settings.reach + RAY_EXTRA)
        local valid = hit and normal.z >= MIN_NORMAL_Z and #(target - GetEntityCoords(ped)) <= settings.reach and not crowded(target)

        if hit then
            SetEntityCoordsNoOffset(ghost, target.x, target.y, target.z, false, false, false)
        end

        SetEntityHeading(ghost, heading)
        SetEntityDrawOutlineColor(valid and 0 or 255, valid and 255 or 0, 0, 255)

        if IsDisabledControlPressed(0, ROTATE_LEFT_CONTROL) then
            heading = (heading + ROTATE_SPEED * GetFrameTime()) % 360.0
        elseif IsDisabledControlPressed(0, ROTATE_RIGHT_CONTROL) then
            heading = (heading - ROTATE_SPEED * GetFrameTime()) % 360.0
        end

        if IsDisabledControlJustPressed(0, CANCEL_CONTROL) then break end

        if valid and IsDisabledControlJustPressed(0, PLACE_CONTROL) then
            chosen = target
            break
        end

        Wait(0)
    end

    lib.hideTextUI()
    SetEntityDrawOutline(ghost, false)
    DeleteEntity(ghost)

    return chosen, chosen and heading or nil
end

---@param _ table
---@param slot { name: string, slot: integer, metadata: table? }
exports('placeChair', function(_, slot)
    if placing then return end

    if not LocalPlayer.state.barberDuty then
        return notify('error', 'Anda harus sedang shift untuk memasang kursi cukur.')
    end

    if cache.vehicle then
        return notify('error', 'Tidak bisa memasang kursi dari dalam kendaraan.')
    end

    if not IsModelInCdimage(model) then
        return notify('error', ('Model kursi %s tidak tersedia.'):format(settings.model))
    end

    placing = true

    CreateThread(function()
        local ok, coords, heading = pcall(choosePlacement)

        if ok and coords then
            local result = lib.callback.await('sm_barbershop:portable:place', false, slot.slot, coords, heading)

            if result.success then
                notify('success', 'Kursi cukur terpasang.')
            else
                notify('error', result.message)
            end
        end

        placing = false
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for _, record in pairs(objects) do
        despawn(record)
    end
end)
