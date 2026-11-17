local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local Sync = require 'pelumber.modules.client.sync'
local interact = exports.rhd_interact
local Minigame = require 'pelumber.modules.client.minigame'
local blipUtils = require 'modules.blips'
local utils = require 'modules.utils'

---@class OpenValveEntry
---@field pipe? number
---@field valve? number
---@field blip? number

---@type table<number, OpenValveEntry>
local entries = {}

---@param i number
---@param objId string
local function runGame(_, objId)
    if State.isDone(objId) then return end
    if not Sync.acquire(objId) then
        Util.notifyLocal('Katup sedang dikerjakan pemain lain.', 'error')
        return
    end

    local success = Minigame.valveGame(objId)
    if success then
        Sync.objectDone(objId)
        Util.notifyLocal('Katup berhasil dibuka.', 'success')
    else
        Sync.release(objId)
    end
end

---@param model string
---@param spot table
---@return number?
local function spawnProp(model, spot)
    local ent = utils.createProp(model, spot.coords, false)
    if not ent then return nil end
    if spot.rotation then
        SetEntityRotation(ent, spot.rotation.x, spot.rotation.y, spot.rotation.z, 0, true)
    end
    if spot.heading then
        SetEntityHeading(ent, spot.heading)
    end
    FreezeEntityPosition(ent, true)
    return ent
end

---@param mission ClientMission
local function setup(mission)
    local list = mission.location.openvalve
    if not list then return end

    for i = 1, #list do
        local data = list[i]
        local objId = State.idOpenValve(i)

        local pipe = data.pipe and spawnProp(data.pipe.object, data.pipe) or nil
        local valve = spawnProp(data.valve.object, data.valve)

        if valve then
            interact:addLocalEntity(valve, {
                {
                    name = ('sm_pelumber_ov_%d'):format(i),
                    label = 'Buka Katup',
                    icon = 'fa-solid fa-gear',
                    distance = 1.6,
                    canInteract = function()
                        if State.isDone(objId) then return false end
                        return not State.isBusyByOther(objId)
                    end,
                    onSelect = function()
                        runGame(i, objId)
                    end,
                },
            })
        end

        local blip = blipUtils.create({
            coords = data.valve.coords,
            sprite = 354,
            color = 5,
            scale = 0.7,
            name = 'Buka Katup',
        })

        entries[i] = { pipe = pipe, valve = valve, blip = blip }
    end
end

local function teardown()
    for _, entry in pairs(entries) do
        if entry.valve and DoesEntityExist(entry.valve) then
            interact:removeLocalEntity(entry.valve)
            DeleteEntity(entry.valve)
        end
        if entry.pipe and DoesEntityExist(entry.pipe) then
            DeleteEntity(entry.pipe)
        end
        if entry.blip then blipUtils.remove(entry.blip) end
    end
    entries = {}
end

Minigame.registerTask('openvalve', {
    setup = setup,
    teardown = teardown,
})
