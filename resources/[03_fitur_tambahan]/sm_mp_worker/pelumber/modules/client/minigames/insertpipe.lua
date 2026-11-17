local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local Sync = require 'pelumber.modules.client.sync'
local interact = exports.rhd_interact
local Minigame = require 'pelumber.modules.client.minigame'
local blipUtils = require 'modules.blips'
local utils = require 'modules.utils'

local pipeNames = State.offsets.pipeNames

local VALVE_MODEL = 'prop_oil_valve_01'
local PLACE_ANIM = { dict = 'anim@mp_fireworks', clip = 'place_firework_3_box', flag = 2 }

---@class InsertSet
---@field valveEnt? number
---@field valveId string
---@field pipes table<number, number>
---@field pipeIds table<number, string>
---@field blip? number

---@type table<number, InsertSet>
local sets = {}

---@param ent? number
---@param solid boolean
local function applyPipeVisual(ent, solid)
    if not ent or not DoesEntityExist(ent) then return end
    if solid then
        SetEntityAlpha(ent, 255, false)
        SetEntityCollision(ent, true, true)
    else
        SetEntityAlpha(ent, 100, false)
        SetEntityCollision(ent, false, false)
    end
end

---@param s number
---@return boolean
local function allPipesDone(s)
    local set = sets[s]
    if not set then return false end
    for _, pipeId in pairs(set.pipeIds) do
        if not State.isDone(pipeId) then return false end
    end
    return true
end

---@param s number
---@param i number
---@return boolean
local function prevPipesDone(s, i)
    for k = 1, i - 1 do
        if not State.isDone(State.idInsertPipe(s, k)) then return false end
    end
    return true
end

---@param s number
---@param i number
---@param pipeId string
---@param pipeData table
local function placePipe(s, i, pipeId, pipeData)
    if State.isDone(pipeId) then return end
    if not prevPipesDone(s, i) then
        Util.notifyLocal('Pasang pipa sebelumnya terlebih dahulu.', 'error')
        return
    end
    if not Util.isHoldingPipeType(pipeData.object) then
        Util.notifyLocal('Kamu tidak memegang pipa yang sesuai.', 'error')
        return
    end
    if not Sync.acquire(pipeId) then
        Util.notifyLocal('Pipa ini sedang dikerjakan pemain lain.', 'error')
        return
    end

    local pipeLabel = pipeNames[pipeData.object] or 'Pipa'
    local ok = Util.progress(('Memasang %s...'):format(pipeLabel), 3500, PLACE_ANIM)
    if not ok then
        Sync.release(pipeId)
        return
    end

    Util.resetPlayerHandObject()
    Sync.objectDone(pipeId)
end

---@param s number
---@param valveId string
local function placeValve(s, valveId)
    if State.isDone(valveId) then return end
    if State.valveState(valveId) == 'placed' then return end
    if not allPipesDone(s) then
        Util.notifyLocal('Pasang semua pipa terlebih dahulu.', 'error')
        return
    end
    if not Util.isHoldingValve() then
        Util.notifyLocal('Kamu harus memegang katup dari kendaraan.', 'error')
        return
    end
    if not Sync.acquire(valveId) then
        Util.notifyLocal('Katup sedang dikerjakan pemain lain.', 'error')
        return
    end

    local ok = Util.progress('Memasang katup...', 3500, PLACE_ANIM)
    if not ok then
        Sync.release(valveId)
        return
    end

    Util.resetPlayerHandObject()
    Sync.valveState(valveId, 'placed')
    Util.notifyLocal('Katup terpasang. Sekarang buka katup.', 'success')
end

---@param s number
---@param valveId string
---@param valveEnt number
local function openValve(_, valveId, valveEnt)
    if State.isDone(valveId) then return end
    if State.valveState(valveId) ~= 'placed' then return end
    if not Sync.acquire(valveId) then
        Util.notifyLocal('Katup sedang dikerjakan pemain lain.', 'error')
        return
    end

    local success = Minigame.pipeGame('open', valveEnt, valveId)
    if success then
        Sync.objectDone(valveId)
        Util.notifyLocal('Rangkaian pipa selesai.', 'success')
    else
        Sync.release(valveId)
    end
end

---@param mission ClientMission
local function setup(mission)
    local list = mission.location.insertpipe
    if not list then return end

    for s = 1, #list do
        local setData = list[s]
        local valveId = State.idInsertValve(s)

        local valveEnt = utils.createProp(VALVE_MODEL, setData.valve.coords, false)
        if valveEnt then
            SetEntityHeading(valveEnt, setData.valve.heading or 0.0)
            FreezeEntityPosition(valveEnt, true)
            applyPipeVisual(valveEnt, State.valveState(valveId) == 'placed' or State.isDone(valveId))
        end

        local pipes = {}
        local pipeIds = {}
        for i = 1, #setData.pipes do
            local pipeData = setData.pipes[i]
            local pipeId = State.idInsertPipe(s, i)
            pipeIds[i] = pipeId

            local ent = utils.createProp(pipeData.object, pipeData.coords, false)
            if ent then
                if pipeData.rotation then
                    SetEntityRotation(ent, pipeData.rotation.x, pipeData.rotation.y, pipeData.rotation.z, 0, true)
                end
                FreezeEntityPosition(ent, true)
                applyPipeVisual(ent, State.isDone(pipeId))
                pipes[i] = ent

                interact:addLocalEntity(ent, {
                    {
                        name = ('sm_pelumber_ip_pipe_%d_%d'):format(s, i),
                        label = ('Pasang %s'):format(pipeNames[pipeData.object] or 'Pipa'),
                        icon = 'fa-solid fa-wrench',
                        distance = 1.4,
                        canInteract = function()
                            if State.isDone(pipeId) then return false end
                            if State.isBusyByOther(pipeId) then return false end
                            if not prevPipesDone(s, i) then return false end
                            return Util.isHoldingPipeType(pipeData.object)
                        end,
                        onSelect = function()
                            placePipe(s, i, pipeId, pipeData)
                        end,
                    },
                })
            end
        end

        if valveEnt then
            interact:addLocalEntity(valveEnt, {
                {
                    name = ('sm_pelumber_ip_valve_place_%d'):format(s),
                    label = 'Pasang Katup',
                    icon = 'fa-solid fa-screwdriver-wrench',
                    distance = 1.5,
                    canInteract = function()
                        if State.isDone(valveId) then return false end
                        if State.isBusyByOther(valveId) then return false end
                        if State.valveState(valveId) == 'placed' then return false end
                        if not allPipesDone(s) then return false end
                        return Util.isHoldingValve()
                    end,
                    onSelect = function()
                        placeValve(s, valveId)
                    end,
                },
                {
                    name = ('sm_pelumber_ip_valve_open_%d'):format(s),
                    label = 'Buka Katup',
                    icon = 'fa-solid fa-gear',
                    distance = 1.5,
                    canInteract = function()
                        if State.isDone(valveId) then return false end
                        if State.isBusyByOther(valveId) then return false end
                        return State.valveState(valveId) == 'placed'
                    end,
                    onSelect = function()
                        openValve(s, valveId, valveEnt)
                    end,
                },
            })
        end

        local blip = blipUtils.create({
            coords = setData.valve.coords,
            sprite = 354,
            color = 5,
            scale = 0.7,
            name = 'Pemasangan Pipa',
        })

        sets[s] = { valveEnt = valveEnt, valveId = valveId, pipes = pipes, pipeIds = pipeIds, blip = blip }
    end

    for _, set in pairs(sets) do
        for i, pipeId in pairs(set.pipeIds) do
            applyPipeVisual(set.pipes[i], State.isDone(pipeId))
        end
        applyPipeVisual(set.valveEnt, State.valveState(set.valveId) == 'placed' or State.isDone(set.valveId))
    end
end

---@param objId string
local function onObjectDone(objId)
    for _, set in pairs(sets) do
        for i, pipeId in pairs(set.pipeIds) do
            if pipeId == objId then
                applyPipeVisual(set.pipes[i], true)
                return
            end
        end
    end
end

---@param objId string
---@param state string
local function onValveState(objId, state)
    if state ~= 'placed' then return end
    for _, set in pairs(sets) do
        if set.valveId == objId then
            applyPipeVisual(set.valveEnt, true)
            return
        end
    end
end

local function teardown()
    for _, set in pairs(sets) do
        for _, ent in pairs(set.pipes) do
            if DoesEntityExist(ent) then
                interact:removeLocalEntity(ent)
                DeleteEntity(ent)
            end
        end
        if set.valveEnt and DoesEntityExist(set.valveEnt) then
            interact:removeLocalEntity(set.valveEnt)
            DeleteEntity(set.valveEnt)
        end
        if set.blip then blipUtils.remove(set.blip) end
    end
    sets = {}
end

Minigame.registerTask('insertpipe', {
    setup = setup,
    teardown = teardown,
    onObjectDone = onObjectDone,
    onValveState = onValveState,
})
