local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local CreateObject = CreateObject
local GetEntityCoords = GetEntityCoords
local SetEntityHeading = SetEntityHeading
local SetEntityAlpha = SetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityDrawOutline = SetEntityDrawOutline
local SetEntityDrawOutlineColor = SetEntityDrawOutlineColor
local FreezeEntityPosition = FreezeEntityPosition
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local IsEntityPlayingAnim = IsEntityPlayingAnim
local IsEntityDead = IsEntityDead
local IsControlJustReleased = IsControlJustReleased
local DisableControlAction = DisableControlAction
local TaskPlayAnim = TaskPlayAnim
local pairs = pairs

local farm = SmAnimalFarm
local TROUGH = config.trough
local PLACE = TROUGH.placeAnim
local PLACE_RANGE = TROUGH.placeDistance * TROUGH.placeDistance
local GHOST_ALPHA = TROUGH.ghostAlpha
local OUTLINE = TROUGH.outline
local OUTLINE_RANGE = TROUGH.outlineDistance * TROUGH.outlineDistance
local STOCK = config.stock
local PLACE_KEY = 38
local CANCEL_KEY = 73
local BLOCKED = { 23, 24, 25, 37, 44, 140, 141, 142, 257, 263, 264 }
local BLOCKED_COUNT = #BLOCKED

---@class FarmCarry
---@field kind 'food'|'water'
---@field prop integer
---@field busy boolean

---@type FarmCarry|nil
local carrying
---@type table<integer, { obj: integer, x: number, y: number, outlined: boolean }>
local ghosts = {}
local spots = {}

---@param message string
---@param kind? string
local function notify(message, kind)
    lib.notify({ title = 'Peternakan', description = message, type = kind or 'error' })
end

local function clearGhosts()
    for id, ghost in pairs(ghosts) do
        if DoesEntityExist(ghost.obj) then
            DeleteEntity(ghost.obj)
        end

        ghosts[id] = nil
    end
end

---@param kind 'food'|'water'
---@param spot table
---@return integer
local function makeGhost(kind, spot)
    local obj = CreateObject(TROUGH[kind].model, spot.x, spot.y, spot.z, false, false, false)

    SetEntityHeading(obj, spot.h)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, false, false)
    SetEntityAlpha(obj, GHOST_ALPHA, false)

    return obj
end

---@param kind 'food'|'water'
local function refreshGhosts(kind)
    local count = farm.troughSpots and farm.troughSpots(kind, spots) or 0
    local seen = {}
    local me = GetEntityCoords(cache.ped)

    for i = 1, count do
        local spot = spots[i]
        local ghost = ghosts[spot.id]

        seen[spot.id] = true

        if ghost and (ghost.x ~= spot.x or ghost.y ~= spot.y) then
            DeleteEntity(ghost.obj)
            ghost = nil
        end

        if not ghost then
            ghost = { obj = makeGhost(kind, spot), x = spot.x, y = spot.y, outlined = false }
            ghosts[spot.id] = ghost
        end

        local dx, dy = spot.x - me.x, spot.y - me.y
        local near = dx * dx + dy * dy <= OUTLINE_RANGE

        if near ~= ghost.outlined then
            ghost.outlined = near
            SetEntityDrawOutline(ghost.obj, near)
        end
    end

    for id, ghost in pairs(ghosts) do
        if not seen[id] then
            DeleteEntity(ghost.obj)
            ghosts[id] = nil
        end
    end
end

---@param kind 'food'|'water'
---@param target boolean
local function showHelp(kind, target)
    farm.setHud({
        title = STOCK[kind].localLabel,
        hint = not target and 'Bawa ke tanda bayangan di lahan hewanmu.' or nil,
        keys = target and {
            { key = 'E', label = 'Taruh' },
            { key = 'X', label = 'Batal' },
        } or {
            { key = 'X', label = 'Batal' },
        },
    })
end

---@param current FarmCarry
local function finish(current)
    if carrying ~= current then return end

    carrying = nil
    clearGhosts()
    farm.setHud(nil)
    farm.carrying = nil

    if DoesEntityExist(current.prop) then
        DeleteEntity(current.prop)
    end

    StopAnimTask(cache.ped, TROUGH[current.kind].carry.anim.dict, TROUGH[current.kind].carry.anim.clip, 1.0)
end

---@param current FarmCarry
local function cancel(current)
    finish(current)
    lib.callback.await('sm_animalfarm:drop', false)
end

---@param current FarmCarry
---@param id integer
local function place(current, id)
    current.busy = true

    local ped = cache.ped

    if pcall(lib.requestAnimDict, PLACE.dict, 3000) then
        TaskPlayAnim(ped, PLACE.dict, PLACE.clip, 8.0, -8.0, PLACE.duration, 0, 0.0, false, false, false)
    end

    Wait(PLACE.duration * 0.6)

    if DoesEntityExist(current.prop) then
        DeleteEntity(current.prop)
    end

    local result = lib.callback.await('sm_animalfarm:fill', false, id, current.kind)

    Wait(PLACE.duration * 0.4)
    finish(current)

    if type(result) ~= 'table' then return end

    if not result.ok then
        lib.callback.await('sm_animalfarm:drop', false)
    end

    notify(result.message or 'Gagal.', result.ok and 'success' or 'error')
end

---@param current FarmCarry
local function loop(current)
    CreateThread(function()
        local carry = TROUGH[current.kind].carry
        local nextRefresh = 0
        local target
        local shownTarget

        while carrying == current do
            local ped = cache.ped
            local now = GetGameTimer()

            if IsEntityDead(ped) or cache.vehicle or farm.riding or farm.boarded then
                cancel(current)
                break
            end

            for i = 1, BLOCKED_COUNT do
                DisableControlAction(0, BLOCKED[i], true)
            end

            if now >= nextRefresh then
                nextRefresh = now + 500
                refreshGhosts(current.kind)

                if not current.busy and not IsEntityPlayingAnim(ped, carry.anim.dict, carry.anim.clip, 3) then
                    TaskPlayAnim(ped, carry.anim.dict, carry.anim.clip, 8.0, -8.0, -1, 49, 0.0, false, false, false)
                end
            end

            local pos = GetEntityCoords(ped)

            target = nil

            for id, ghost in pairs(ghosts) do
                local dx, dy = ghost.x - pos.x, ghost.y - pos.y

                if dx * dx + dy * dy <= PLACE_RANGE then
                    target = id
                    break
                end
            end

            if target ~= shownTarget then
                shownTarget = target
                showHelp(current.kind, target ~= nil)
            end

            if not current.busy then
                if target and IsControlJustReleased(0, PLACE_KEY) then
                    place(current, target)
                    break
                end

                if IsControlJustReleased(0, CANCEL_KEY) then
                    cancel(current)
                    break
                end
            end

            Wait(0)
        end
    end)
end

---@param kind 'food'|'water'
function farm.startCarry(kind)
    if carrying or not TROUGH[kind] then return end
    if farm.riding or farm.boarded or cache.vehicle then return end

    local trough = TROUGH[kind]
    local carry = trough.carry

    if not lib.requestModel(trough.model, 5000) then
        lib.callback.await('sm_animalfarm:drop', false)
        return notify('Prop gagal dimuat.')
    end

    if not pcall(lib.requestAnimDict, carry.anim.dict, 5000) then
        lib.callback.await('sm_animalfarm:drop', false)
        return notify('Animasi gagal dimuat.')
    end

    local ped = cache.ped
    local pos = GetEntityCoords(ped)
    local prop = CreateObject(trough.model, pos.x, pos.y, pos.z, false, false, false)

    SetModelAsNoLongerNeeded(trough.model)
    SetEntityCollision(prop, false, false)
    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, carry.bone),
        carry.pos.x, carry.pos.y, carry.pos.z,
        carry.rot.x, carry.rot.y, carry.rot.z,
        true, true, false, true, 1, true
    )
    TaskPlayAnim(ped, carry.anim.dict, carry.anim.clip, 8.0, -8.0, -1, 49, 0.0, false, false, false)
    SetEntityDrawOutlineColor(OUTLINE[1], OUTLINE[2], OUTLINE[3], OUTLINE[4])

    carrying = { kind = kind, prop = prop, busy = false }
    farm.carrying = kind
    showHelp(kind, false)
    loop(carrying)
end

---@param kind 'food'|'water'
function farm.takeStock(kind)
    if carrying then return end

    local result = lib.callback.await('sm_animalfarm:take', false, kind)

    if type(result) ~= 'table' then return end
    if not result.ok then return notify(result.message) end

    farm.startCarry(kind)
end

local PICKUP = config.pickup
local PICKUP_RANGE = PICKUP.distance * PICKUP.distance
local pickupLabels = { food = 'Ambil Jerami', water = 'Ambil Air' }
local pickupHud
local pickupHudStock
local SetDrawOrigin = SetDrawOrigin
local ClearDrawOrigin = ClearDrawOrigin
local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextCentre = SetTextCentre
local SetTextOutline = SetTextOutline
local SetTextColour = SetTextColour
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandDisplayText = EndTextCommandDisplayText
local LABEL_RANGE = PICKUP.labelDistance

---@param x number
---@param y number
---@param z number
---@param text string
local function drawLabel(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(255, 255, 255, 230)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

for kind, label in pairs(pickupLabels) do
    local coords = PICKUP[kind]
    local ground = lib.marker.new({
        type = 'HorizontalCircleSkinny',
        coords = vec3(coords.x, coords.y, coords.z - 0.95),
        width = 1.2,
        height = 1.2,
        color = PICKUP.marker,
    })
    local arrow = lib.marker.new({
        type = 'ChevronUpx1',
        coords = vec3(coords.x, coords.y, coords.z + 0.2),
        width = 0.4,
        height = 0.4,
        color = PICKUP.marker,
        bobUpAndDown = true,
        rotate = true,
    })

    local upperLabel = STOCK[kind].localLabel:upper()
    local labelCount = -1
    local labelText

    lib.points.new({
        coords = coords,
        distance = PICKUP.renderDistance,
        nearby = function(self)
            if not farm.inPen and pickupHud ~= kind then return end

            local stock = farm.penStock
            local visible = farm.inPen and farm.penOwner == cache.serverId and stock and (stock[kind] or 0) > 0
            local usable = false

            local count = stock and stock[kind] or 0

            if visible and not carrying then
                ground:draw()
                arrow:draw()

                if self.currentDistance <= LABEL_RANGE then
                    if labelCount ~= count then
                        labelCount = count
                        labelText = ('%s - SISA %d'):format(upperLabel, count)
                    end

                    drawLabel(coords.x, coords.y, coords.z + 0.75, labelText)
                end

                local inside = self.currentDistance * self.currentDistance <= PICKUP_RANGE

                usable = inside and not farm.riding and not farm.boarded and not cache.vehicle
            end

            if usable and (pickupHud ~= kind or pickupHudStock ~= count) then
                pickupHud = kind
                pickupHudStock = count
                farm.setHud({ title = ('%s · Sisa %d'):format(STOCK[kind].localLabel, count), keys = { { key = 'E', label = label } } })
            elseif not usable and pickupHud == kind then
                pickupHud = nil

                if not carrying then
                    farm.setHud(nil)
                end
            end

            if usable and IsControlJustReleased(0, PLACE_KEY) then
                pickupHud = nil
                farm.takeStock(kind)
            end
        end,
        onExit = function()
            if pickupHud == kind then
                pickupHud = nil

                if not carrying then
                    farm.setHud(nil)
                end
            end
        end,
    })
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    clearGhosts()

    if carrying and DoesEntityExist(carrying.prop) then
        DeleteEntity(carrying.prop)
    end

    carrying = nil
end)
