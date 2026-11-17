local state = localmodule 'modules.state'
local util = localmodule 'modules.util'
local camera = localmodule 'modules.camera'
local gizmo = localmodule 'modules.gizmo'
local objects = localmodule 'modules.objects'
local keys = localmodule 'modules.keys'
local nui = localmodule 'modules.nui'

local type = type
local joaat = joaat
local Wait = Wait
local CreateThread = CreateThread
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local IsModelInCdimage = IsModelInCdimage
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local CreateObjectNoOffset = CreateObjectNoOffset
local SetEntityAlpha = SetEntityAlpha
local ResetEntityAlpha = ResetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityRotation = SetEntityRotation
local GetEntityCoords = GetEntityCoords
local GetEntityRotation = GetEntityRotation
local FreezeEntityPosition = FreezeEntityPosition

local placement = {}

---@class GmPlacement
---@field kind 'new'|'modify'
---@field entity integer
---@field model string
---@field id? string
---@field gizmo GmGizmo
---@field original? { pos: vector3, rot: vector3 }
---@field busy boolean

---@type GmPlacement?
local session = nil

local function publish()
    nui.send('placement', {
        active = session ~= nil,
        mode = session and session.gizmo.mode or 'translate',
        kind = session and session.kind or nil,
        persist = state.options.persist,
    })
end

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

---@return boolean
function placement.active()
    return session ~= nil
end

---@param model string
---@param coords vector3
function placement.begin(model, coords)
    if session then return end

    state.placing = true

    CreateThread(function()
        local hash = joaat(model)

        if not loadModel(hash) then
            state.placing = false
            nui.log('error', ('Model %s gagal dimuat'):format(model))
            return
        end

        local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)

        SetModelAsNoLongerNeeded(hash)

        if entity == 0 then
            state.placing = false
            return
        end

        local rot = { x = 0.0, y = 0.0, z = state.heading }

        SetEntityAlpha(entity, 200, false)
        SetEntityCollision(entity, false, false)
        FreezeEntityPosition(entity, true)
        SetEntityRotation(entity, rot.x, rot.y, rot.z, 2, true)

        if not state.enabled or not state.placing then
            DeleteEntity(entity)
            return
        end

        session = {
            kind = 'new',
            entity = entity,
            model = model,
            gizmo = gizmo.new(coords, rot),
            busy = false,
        }

        publish()
    end)
end

---@param entity integer
function placement.modify(entity)
    if session then return end

    local id = objects.idOf(entity)
    local record = id and objects.record(id)

    if not record then return end

    local pos = GetEntityCoords(entity)
    local rot = GetEntityRotation(entity, 2)

    SetEntityAlpha(entity, 200, false)
    SetEntityCollision(entity, false, false)

    state.placing = true
    session = {
        kind = 'modify',
        entity = entity,
        model = record.model,
        id = id,
        gizmo = gizmo.new(pos, { x = rot.x, y = rot.y, z = rot.z }),
        original = { pos = pos, rot = rot },
        busy = false,
    }

    publish()
end

local function finish()
    session = nil
    state.placing = false
    publish()
end

function placement.cancel()
    local current = session

    if not current then
        state.placing = false
        return
    end

    local entity = current.entity

    if DoesEntityExist(entity) then
        if current.kind == 'new' then
            DeleteEntity(entity)
        else
            local original = current.original

            SetEntityCoordsNoOffset(entity, original.pos.x, original.pos.y, original.pos.z, false, false, false)
            SetEntityRotation(entity, original.rot.x, original.rot.y, original.rot.z, 2, true)
            ResetEntityAlpha(entity)
            SetEntityCollision(entity, true, true)
        end
    end

    finish()
end

local function confirm()
    local current = session

    if not current or current.busy then return end

    current.busy = true

    local g = current.gizmo
    local payload = {
        coords = g.pos,
        rot = { x = g.rot.x, y = g.rot.y, z = g.rot.z },
    }

    CreateThread(function()
        local result

        if current.kind == 'new' then
            payload.model = current.model
            payload.persist = state.options.persist
            result = lib.callback.await('sm_gamemaster:server:objectPlace', false, payload)
        else
            payload.id = current.id
            result = lib.callback.await('sm_gamemaster:server:objectUpdate', false, payload)
        end

        if session ~= current then return end

        if type(result) ~= 'table' or not result.ok then
            current.busy = false
            nui.log('error', type(result) == 'table' and result.reason or 'Server tidak merespons')
            return
        end

        if current.kind == 'new' then
            if DoesEntityExist(current.entity) then
                DeleteEntity(current.entity)
            end

            nui.log('success', ('Objek %s ditaruh%s'):format(current.model, payload.persist and ' (permanen)' or ''))
        else
            nui.log('success', 'Posisi objek diperbarui')
        end

        finish()
    end)
end

---@param input { pressed: boolean, released: boolean, rmb: boolean }
function placement.update(input)
    local current = session

    if not current then return end

    local entity = current.entity

    if not DoesEntityExist(entity) then
        finish()
        return
    end

    local g = current.gizmo
    local origin, dir = camera.ray()

    if not state.typing and not current.busy then
        if input.rmb and not g.drag then
            placement.cancel()
            return
        end

        if keys.pressed(keys.TAB) then
            gizmo.toggleMode(g)
            publish()
        end

        if keys.pressed(keys.G) and not g.drag then
            g.pos = util.toGround(g.pos)
        end

        if keys.pressed(keys.ENTER) and not g.drag then
            confirm()
        end

        gizmo.update(g, origin, dir, {
            pressed = input.pressed and not state.overUi,
            released = input.released,
            pitch = state.pitch,
            heading = state.heading,
        })
    end

    SetEntityCoordsNoOffset(entity, g.pos.x, g.pos.y, g.pos.z, false, false, false)
    SetEntityRotation(entity, g.rot.x, g.rot.y, g.rot.z, 2, true)
    gizmo.draw(g, origin)
end

function placement.confirm()
    confirm()
end

function placement.toggleMode()
    if not session then return end

    gizmo.toggleMode(session.gizmo)
    publish()
end

function placement.publish()
    publish()
end

return placement
