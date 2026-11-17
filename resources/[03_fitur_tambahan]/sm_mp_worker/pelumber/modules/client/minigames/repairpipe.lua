local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local Sync = require 'pelumber.modules.client.sync'
local interact = exports.rhd_interact
local Minigame = require 'pelumber.modules.client.minigame'
local blipUtils = require 'modules.blips'
local utils = require 'modules.utils'

local pipeNames = State.offsets.pipeNames

local VALVE_MODEL = 'prop_oil_valve_01'
local BROKEN_MODEL = 'veo_pipes_asd'
local REPAIR_ANIM = { dict = 'anim@mp_fireworks', clip = 'place_firework_3_box', flag = 2 }

---@class RepairSet
---@field valveEnt? number
---@field valveId string
---@field pipes table<number, number>
---@field pipeIds table<number, string>
---@field brokenPipe table<number, boolean>
---@field stage table<number, 'broken'|'removed'|'done'>
---@field pipeData table<number, table>
---@field blip? number

---@type table<number, RepairSet>
local sets = {}

local buildPipeOptions

---@param s number
---@return boolean
local function allBrokenDone(s)
    local set = sets[s]
    if not set then return false end
    for i, pipeId in pairs(set.pipeIds) do
        if set.brokenPipe[i] and not State.isDone(pipeId) then return false end
    end
    return true
end

---@param s number
---@param i number
---@param pipeId string
local function startWaterParticle(s, i, pipeId)
    CreateThread(function()
        while true do
            Wait(0)
            local set = sets[s]
            if not set or not State.mission or set.stage[i] == 'done' or State.isDone(pipeId) then break end
            if State.valveState(set.valveId) == 'closed' then break end
            local ent = set.pipes[i]
            if ent and DoesEntityExist(ent) then
                Util.loadParticleLib('core')
                StartParticleFxNonLoopedOnEntity('bul_decal_water_heli', ent, 0.0, 0.16, 0.3, 0.0, math.random(-90, 90) + 0.0, 0.0, 1.4, false, false, false)
            end
        end
    end)
end

---@param s number
---@param i number
local function replaceWithSolid(s, i)
    local set = sets[s]
    if not set or set.stage[i] == 'done' then return end
    set.stage[i] = 'done'

    local ent = set.pipes[i]
    if ent and DoesEntityExist(ent) then
        interact:removeLocalEntity(ent)
        DeleteEntity(ent)
    end

    local pipeData = set.pipeData[i]
    local solid = utils.createProp(pipeData.object, pipeData.coords, false)
    if solid then
        if pipeData.rotation then
            SetEntityRotation(solid, pipeData.rotation.x, pipeData.rotation.y, pipeData.rotation.z, 0, true)
        end
        FreezeEntityPosition(solid, true)
        set.pipes[i] = solid
    end
end

---@param s number
---@param i number
local function replaceWithGhost(s, i)
    local set = sets[s]
    if not set or set.stage[i] ~= 'broken' then return end
    set.stage[i] = 'removed'

    local ent = set.pipes[i]
    if ent and DoesEntityExist(ent) then
        interact:removeLocalEntity(ent)
        DeleteEntity(ent)
    end

    local pipeData = set.pipeData[i]
    local ghost = utils.createProp(pipeData.object, pipeData.coords, false)
    if ghost then
        if pipeData.rotation then
            SetEntityRotation(ghost, pipeData.rotation.x, pipeData.rotation.y, pipeData.rotation.z, 0, true)
        end
        FreezeEntityPosition(ghost, true)
        SetEntityAlpha(ghost, 60, false)
        SetEntityDrawOutline(ghost, true)
        SetEntityDrawOutlineColor(255, 0, 0, 255)
        set.pipes[i] = ghost
        interact:addLocalEntity(ghost, buildPipeOptions(s, i, set.pipeIds[i], pipeData, set.valveId))
    end
end

---@param s number
---@param i number
---@param pipeId string
---@param valveId string
local function removePipe(_, _, pipeId, valveId)
    if State.isDone(pipeId) or State.isPipeRemoved(pipeId) then return end
    if State.valveState(valveId) ~= 'closed' then
        Util.notifyLocal('Tutup katup terlebih dahulu.', 'error')
        return
    end
    if Util.getValidHandObject() then
        Util.notifyLocal('Tanganmu harus kosong untuk melepas pipa.', 'error')
        return
    end
    if not Sync.acquire(pipeId) then
        Util.notifyLocal('Pipa ini sedang dikerjakan pemain lain.', 'error')
        return
    end

    local ok = Util.progress('Melepas pipa rusak...', 4000, REPAIR_ANIM)
    if not ok then
        Sync.release(pipeId)
        return
    end

    local coords = GetEntityCoords(cache.ped)
    local obj = utils.createProp(BROKEN_MODEL, coords, false)
    if obj then
        Util.addPlayerHandObject(obj, BROKEN_MODEL, 'pipe', BROKEN_MODEL)
    end
    Sync.pipeRemoved(pipeId)
    Util.notifyLocal('Pipa rusak dilepas. Kembalikan ke kendaraan dan ambil pipa baru.', 'success')
end

---@param s number
---@param i number
---@param pipeId string
---@param pipeData table
local function repairPipe(s, _, pipeId, pipeData)
    if State.isDone(pipeId) then return end
    if State.valveState(State.idRepairValve(s)) ~= 'closed' then
        Util.notifyLocal('Tutup katup terlebih dahulu.', 'error')
        return
    end
    if not State.isPipeRemoved(pipeId) then
        Util.notifyLocal('Lepas pipa rusak terlebih dahulu.', 'error')
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
    local ok = Util.progress(('Memasang %s...'):format(pipeLabel), 4000, REPAIR_ANIM)
    if not ok then
        Sync.release(pipeId)
        return
    end

    Util.resetPlayerHandObject()
    Sync.objectDone(pipeId)
end

---@param s number
---@param i number
---@param pipeId string
---@param pipeData table
---@param valveId string
---@return table[]
function buildPipeOptions(s, i, pipeId, pipeData, valveId)
    return {
        {
            name = ('sm_pelumber_rp_remove_%d_%d'):format(s, i),
            label = 'Lepas Pipa Rusak',
            icon = 'fa-solid fa-wrench',
            distance = 1.4,
            canInteract = function()
                if State.isDone(pipeId) or State.isPipeRemoved(pipeId) then return false end
                if State.isBusyByOther(pipeId) then return false end
                if State.valveState(valveId) ~= 'closed' then return false end
                return Util.getValidHandObject() == nil
            end,
            onSelect = function()
                removePipe(s, i, pipeId, valveId)
            end,
        },
        {
            name = ('sm_pelumber_rp_pipe_%d_%d'):format(s, i),
            label = ('Pasang %s'):format(pipeNames[pipeData.object] or 'Pipa'),
            icon = 'fa-solid fa-wrench',
            distance = 1.4,
            canInteract = function()
                if State.isDone(pipeId) then return false end
                if not State.isPipeRemoved(pipeId) then return false end
                if State.isBusyByOther(pipeId) then return false end
                if State.valveState(valveId) ~= 'closed' then return false end
                return Util.isHoldingPipeType(pipeData.object)
            end,
            onSelect = function()
                repairPipe(s, i, pipeId, pipeData)
            end,
        },
    }
end

---@param s number
---@param valveId string
---@param valveEnt number
---@param heading number
local function closeValve(_, valveId, valveEnt, heading)
    if State.isDone(valveId) then return end
    if State.valveState(valveId) == 'closed' then return end
    if not Sync.acquire(valveId) then
        Util.notifyLocal('Katup sedang dikerjakan pemain lain.', 'error')
        return
    end

    SetEntityHeading(valveEnt, heading)
    local success = Minigame.pipeGame('close', valveEnt, valveId)
    if success then
        Sync.valveState(valveId, 'closed')
        Util.notifyLocal('Katup tertutup. Ganti pipa yang rusak.', 'success')
    else
        Sync.release(valveId)
    end
end

---@param s number
---@param valveId string
---@param valveEnt number
---@param heading number
local function openValve(s, valveId, valveEnt, heading)
    if State.isDone(valveId) then return end
    if State.valveState(valveId) ~= 'closed' then return end
    if not allBrokenDone(s) then
        Util.notifyLocal('Ganti semua pipa rusak terlebih dahulu.', 'error')
        return
    end
    if not Sync.acquire(valveId) then
        Util.notifyLocal('Katup sedang dikerjakan pemain lain.', 'error')
        return
    end

    SetEntityHeading(valveEnt, heading)
    local success = Minigame.pipeGame('open', valveEnt, valveId, 450.0)
    if success then
        Sync.objectDone(valveId)
        Util.notifyLocal('Pipa berhasil diperbaiki.', 'success')
    else
        Sync.release(valveId)
    end
end

---@param mission ClientMission
local function setup(mission)
    local list = mission.location.repairpipe
    if not list then return end

    for s = 1, #list do
        local setData = list[s]
        local valveId = State.idRepairValve(s)

        local valveEnt = utils.createProp(VALVE_MODEL, setData.valve.coords, false)
        if valveEnt then
            SetEntityHeading(valveEnt, setData.valve.heading or 0.0)
            FreezeEntityPosition(valveEnt, true)
        end

        local pipes = {}
        local pipeIds = {}
        local brokenPipe = {}
        local stage = {}
        local pipeDataMap = {}

        for i = 1, #setData.pipes do
            local pipeData = setData.pipes[i]
            local pipeId = State.idRepairPipe(s, i)
            pipeIds[i] = pipeId
            pipeDataMap[i] = pipeData
            local isBroken = mission.brokenPipes[pipeId] == true
            brokenPipe[i] = isBroken

            if not isBroken or State.isDone(pipeId) then
                if isBroken then stage[i] = 'done' end
                local ent = utils.createProp(pipeData.object, pipeData.coords, false)
                if ent then
                    if pipeData.rotation then
                        SetEntityRotation(ent, pipeData.rotation.x, pipeData.rotation.y, pipeData.rotation.z, 0, true)
                    end
                    FreezeEntityPosition(ent, true)
                    pipes[i] = ent
                end
            else
                local removed = State.isPipeRemoved(pipeId)
                stage[i] = removed and 'removed' or 'broken'
                local ent = utils.createProp(removed and pipeData.object or BROKEN_MODEL, pipeData.coords, false)
                if ent then
                    if pipeData.rotation then
                        SetEntityRotation(ent, pipeData.rotation.x, pipeData.rotation.y, pipeData.rotation.z, 0, true)
                    end
                    FreezeEntityPosition(ent, true)
                    if removed then
                        SetEntityAlpha(ent, 60, false)
                        SetEntityDrawOutline(ent, true)
                        SetEntityDrawOutlineColor(255, 0, 0, 255)
                    end
                    pipes[i] = ent

                    interact:addLocalEntity(ent, buildPipeOptions(s, i, pipeId, pipeData, valveId))
                end
            end
        end

        if valveEnt then
            interact:addLocalEntity(valveEnt, {
                {
                    name = ('sm_pelumber_rp_valve_close_%d'):format(s),
                    label = 'Tutup Katup',
                    icon = 'fa-solid fa-lock',
                    distance = 1.5,
                    canInteract = function()
                        if State.isDone(valveId) then return false end
                        if State.isBusyByOther(valveId) then return false end
                        return State.valveState(valveId) ~= 'closed'
                    end,
                    onSelect = function()
                        closeValve(s, valveId, valveEnt, setData.valve.heading or 0.0)
                    end,
                },
                {
                    name = ('sm_pelumber_rp_valve_open_%d'):format(s),
                    label = 'Buka Katup',
                    icon = 'fa-solid fa-unlock',
                    distance = 1.5,
                    canInteract = function()
                        if State.isDone(valveId) then return false end
                        if State.isBusyByOther(valveId) then return false end
                        if State.valveState(valveId) ~= 'closed' then return false end
                        return allBrokenDone(s)
                    end,
                    onSelect = function()
                        openValve(s, valveId, valveEnt, setData.valve.heading or 0.0)
                    end,
                },
            })
        end

        local blip = blipUtils.create({
            coords = setData.valve.coords,
            sprite = 354,
            color = 5,
            scale = 0.7,
            name = 'Perbaikan Pipa',
        })

        sets[s] = {
            valveEnt = valveEnt,
            valveId = valveId,
            pipes = pipes,
            pipeIds = pipeIds,
            brokenPipe = brokenPipe,
            stage = stage,
            pipeData = pipeDataMap,
            blip = blip,
        }
    end

    for s, set in pairs(sets) do
        for i, pipeId in pairs(set.pipeIds) do
            if set.brokenPipe[i] then
                if State.isDone(pipeId) then
                    replaceWithSolid(s, i)
                elseif State.isPipeRemoved(pipeId) then
                    replaceWithGhost(s, i)
                end
                if set.stage[i] ~= 'done' then
                    startWaterParticle(s, i, pipeId)
                end
            end
        end
    end
end

---@param objId string
local function onObjectDone(objId)
    for s, set in pairs(sets) do
        for i, pipeId in pairs(set.pipeIds) do
            if pipeId == objId and set.brokenPipe[i] then
                replaceWithSolid(s, i)
                return
            end
        end
    end
end

---@param objId string
local function onPipeRemoved(objId)
    for s, set in pairs(sets) do
        for i, pipeId in pairs(set.pipeIds) do
            if pipeId == objId and set.brokenPipe[i] then
                replaceWithGhost(s, i)
                return
            end
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

Minigame.registerTask('repairpipe', {
    setup = setup,
    teardown = teardown,
    onObjectDone = onObjectDone,
    onPipeRemoved = onPipeRemoved,
})
