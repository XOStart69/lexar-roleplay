local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local Sync = require 'pelumber.modules.client.sync'
local interact = exports.rhd_interact
local Minigame = require 'pelumber.modules.client.minigame'
local blipUtils = require 'modules.blips'
local utils = require 'modules.utils'

---@class SwitchEntry
---@field entity? number
---@field blip? number

---@type table<number, SwitchEntry>
local entries = {}

---@param i number
---@param objId string
local function runGame(_, objId)
    if State.isDone(objId) then return end
    if not Sync.acquire(objId) then
        Util.notifyLocal('Saklar sedang dikerjakan pemain lain.', 'error')
        return
    end

    local success = Minigame.switchGame(objId)
    if success then
        Sync.objectDone(objId)
        Util.notifyLocal('Saklar berhasil diperbaiki.', 'success')
    else
        Sync.release(objId)
    end
end

---@param mission ClientMission
local function setup(mission)
    local list = mission.location.fixswitch
    if not list then return end

    for i = 1, #list do
        local data = list[i]
        local objId = State.idSwitch(i)

        local ent = utils.createProp(data.object, data.coords, false)
        if ent then
            if data.rotation then
                SetEntityRotation(ent, data.rotation.x, data.rotation.y, data.rotation.z, 0, true)
            end
            FreezeEntityPosition(ent, true)

            interact:addLocalEntity(ent, {
                {
                    name = ('sm_pelumber_fs_%d'):format(i),
                    label = 'Perbaiki Saklar',
                    icon = 'fa-solid fa-bolt',
                    distance = 1.8,
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
            coords = data.coords,
            sprite = 354,
            color = 5,
            scale = 0.7,
            name = 'Perbaiki Saklar',
        })

        entries[i] = { entity = ent, blip = blip }
    end
end

local function teardown()
    for _, entry in pairs(entries) do
        if entry.entity and DoesEntityExist(entry.entity) then
            interact:removeLocalEntity(entry.entity)
            DeleteEntity(entry.entity)
        end
        if entry.blip then blipUtils.remove(entry.blip) end
    end
    entries = {}
end

Minigame.registerTask('fixswitch', {
    setup = setup,
    teardown = teardown,
})
