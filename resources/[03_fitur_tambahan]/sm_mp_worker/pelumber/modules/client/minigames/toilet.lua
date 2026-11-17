local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local Sync = require 'pelumber.modules.client.sync'
local interact = exports.rhd_interact
local Minigame = require 'pelumber.modules.client.minigame'
local blipUtils = require 'modules.blips'
local utils = require 'modules.utils'

---@class ToiletEntry
---@field ent? number
---@field blip? number

---@type table<number, ToiletEntry>
local entries = {}

---@param i number
---@param objId string
---@param data table
local function runGame(_, objId, data)
    if State.isDone(objId) then return end
    if not Sync.acquire(objId) then
        Util.notifyLocal('Toilet ini sedang dibersihkan pemain lain.', 'error')
        return
    end

    local success = Minigame.toilet(data)
    if success then
        Sync.objectDone(objId)
        Util.notifyLocal('Toilet berhasil dibersihkan.', 'success')
    else
        Sync.release(objId)
    end
end

---@param mission ClientMission
local function setup(mission)
    local list = mission.location.toilet
    if not list then return end

    for i = 1, #list do
        local data = list[i]
        local objId = State.idToilet(i)

        local ent = utils.createProp(data.object, data.coords, false)
        if ent then
            SetEntityHeading(ent, data.heading or 0.0)
            FreezeEntityPosition(ent, true)

            interact:addLocalEntity(ent, {
                {
                    name = ('sm_pelumber_tl_opt_%d'):format(i),
                    label = 'Bersihkan Toilet',
                    icon = 'fa-solid fa-toilet',
                    distance = 1.5,
                    offset = vec(0.0, 0.0, 1.0),
                    canInteract = function()
                        if State.isDone(objId) then return false end
                        return not State.isBusyByOther(objId)
                    end,
                    onSelect = function()
                        runGame(i, objId, data)
                    end,
                },
            })
        end

        local blip = blipUtils.create({
            coords = data.coords,
            sprite = 354,
            color = 5,
            scale = 0.7,
            name = 'Bersihkan Toilet',
        })

        entries[i] = { ent = ent, blip = blip }
    end
end

local function teardown()
    for _, entry in pairs(entries) do
        if entry.ent and DoesEntityExist(entry.ent) then
            interact:removeLocalEntity(entry.ent)
            DeleteEntity(entry.ent)
        end
        if entry.blip then blipUtils.remove(entry.blip) end
    end
    entries = {}
end

Minigame.registerTask('toilet', {
    setup = setup,
    teardown = teardown,
})
