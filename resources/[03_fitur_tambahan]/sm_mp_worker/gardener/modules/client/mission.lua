local State = require 'gardener.modules.client.state'
local Util = require 'gardener.modules.client.util'
local Sync = require 'gardener.modules.client.sync'
local utils = require 'modules.utils'

local Mission = {}

local trimInteractions = {}

local mowerZOffsets = {
    prop_weeds_nxg06 = -0.28,
    prop_weeds_nxg08 = -0.28,
    prop_weeds_nxg07b = -0.28,
    prop_weeds_nxg08b = -0.38,
}

local function trimInteractionId(key)
    return ('sm_gardener:trimPruneTree_%s'):format(key)
end

---@param entry table
---@param key number
local function addTrimInteraction(entry, key)
    exports.rhd_interact:addCoords({
        id = trimInteractionId(key),
        coords = vec3(entry.coords.x, entry.coords.y, entry.coords.z + 1.0),
        options = {
            {
                name = trimInteractionId(key),
                label = 'Pangkas Semak',
                icon = 'fas fa-scissors',
                distance = 2.0,
                pointDistance = 15.0,
                canInteract = function()
                    if not State.isTaskActive('prunegrass') then return false end
                    local current = State.prunegrassObject[key]
                    if not current or current.process then return false end
                    return not cache.vehicle and not State.isInteracting
                end,
                onSelect = function()
                    if not State.playerHandObject.trimmer then
                        State.notify('Kamu membutuhkan trimmer', 'error')
                        return
                    end

                    local current = State.prunegrassObject[key]
                    if not current or current.process or not DoesEntityExist(current.object) then return end

                    current.process = true
                    State.startInteraction()
                    Sync.trimPruneTree(key, current.id)
                    SetTimeout(400, State.endInteraction)
                end,
            },
        },
    })
    trimInteractions[#trimInteractions + 1] = trimInteractionId(key)
end

---@param enable boolean
function Mission.toggleTrimInteractions(enable)
    if enable then
        for key, entry in pairs(State.prunegrassObject) do
            if not entry.process then
                addTrimInteraction(entry, key)
            end
        end
        return
    end

    for i = 1, #trimInteractions do
        exports.rhd_interact:removeCoords(trimInteractions[i])
    end
    trimInteractions = {}
end

---@param areaCoords table[]
---@param count number
---@return table[]
local function pickRandomCoords(areaCoords, count)
    local pool = lib.array:from(areaCoords) --[[@as Array]]
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local selected = {}
    for i = 1, math.min(count, #pool) do
        selected[i] = pool[i]
    end
    return selected
end

---@param areaName 'potongRumput' | 'pangkasSemak'
---@param count number
function Mission.spawnAreaObjects(areaName, count)
    local region = State.getRegion()
    if not region or not region[areaName] then return end

    CreateThread(function()
        local areaCoords = region[areaName]
        local target = areaCoords[1].coords

        while State.getStartJob() do
            if #(GetEntityCoords(cache.ped) - target) < 200.0 then break end
            Wait(2000)
        end
        if not State.getStartJob() then return end

        local isPrunegrass = areaName == 'pangkasSemak'
        local targetTable = isPrunegrass and State.prunegrassObject or State.mowerObject
        local models = isPrunegrass and State.cfg.models.prunegrass.before or State.cfg.models.mower
        local blipsName = isPrunegrass and 'prunegrass' or 'lawnmowing'
        local selected = pickRandomCoords(areaCoords, count)

        local blipsData = {}
        for id = 1, #selected do
            local task = selected[id].coords
            local heading = selected[id].heading or 0.0
            local modelName = models[math.random(#models)]
            local z

            if isPrunegrass then
                z = task.z - 0.40
            else
                z = Util.findGroundZ(task.x, task.y, task.z) + (mowerZOffsets[modelName] or 0.0)
            end

            local object = utils.createProp(modelName, vec3(task.x, task.y, z), false)
            if object then
                SetEntityHeading(object, heading)
                SetEntityAsMissionEntity(object, true, true)
                FreezeEntityPosition(object, true)

                targetTable[id] = {
                    object = object,
                    coords = vec3(task.x, task.y, z),
                    heading = heading,
                    id = id,
                    process = false,
                }

                blipsData[#blipsData + 1] = { task = task, blipsName = blipsName, id = id }
                Sync.addObject(modelName, vec3(task.x, task.y, z), heading, areaName, id)
                Wait(0)
            end
        end

        if State.getStartJob() then
            Sync.blipsBatch(blipsData)
        end
    end)
end

---@param modelName string
---@param coords vector3
---@param heading number
---@param areaName 'potongRumput' | 'pangkasSemak'
---@param id number
---@param update? boolean
function Mission.onObjectSynced(modelName, coords, heading, areaName, id, update)
    if areaName == 'potongRumput' then
        if State.mowerObject[id] then return end

        local object = utils.createProp(modelName, coords, false)
        if not object then return end

        SetEntityHeading(object, heading)
        FreezeEntityPosition(object, true)
        State.mowerObject[id] = { object = object, coords = coords, heading = heading, id = id, process = false }
        return
    end

    if areaName ~= 'pangkasSemak' then return end
    if State.prunegrassObject[id] and not update then return end

    if update and State.prunegrassObject[id] then
        local oldObject = State.prunegrassObject[id].object
        SetTimeout(1500, function()
            if DoesEntityExist(oldObject) then
                DeleteObject(oldObject)
            end
        end)
    end

    local object = utils.createProp(modelName, coords, false)
    if not object then return end

    SetEntityHeading(object, heading)
    FreezeEntityPosition(object, true)
    State.prunegrassObject[id] = {
        object = object,
        coords = coords,
        heading = heading,
        id = id,
        process = update and true or false,
    }
end

function Mission.startLawnmowerThread()
    if State.stateThread.deleteLawnMowerObjectThread then return end
    State.stateThread.deleteLawnMowerObjectThread = true

    CreateThread(function()
        while State.getStartJob() do
            local sleep = 1000

            if cache.vehicle and State.isMissionMower(cache.vehicle) and State.isTaskActive('lawnmowing') then
                sleep = 100
                local mowerCoords = GetEntityCoords(cache.vehicle)

                for _, entry in pairs(State.mowerObject) do
                    if not entry.process
                        and #(mowerCoords.xy - entry.coords.xy) <= 0.8 then
                        entry.process = true
                        Sync.deleteLawnMowerObject(entry.id)
                    end
                end
            end

            Wait(sleep)
        end
        State.stateThread.deleteLawnMowerObjectThread = false
    end)
end

---@param id number
---@param isInitiator boolean
function Mission.onLawnMowerDeleted(id, isInitiator)
    local entry = State.mowerObject[id]
    if not entry or not entry.object then return end

    entry.process = true

    CreateThread(function()
        local object = entry.object
        local alpha = 255

        while alpha > 0 and DoesEntityExist(object) do
            local coords = GetEntityCoords(object)
            SetEntityCoords(object, coords.x, coords.y, coords.z - 0.05, false, false, false, false)
            SetEntityAlpha(object, alpha, false)
            Wait(200)
            alpha -= 50
        end

        if DoesEntityExist(object) then
            DeleteObject(object)
        end

        if isInitiator then
            Sync.blipsDelete(id, 'lawnmowing')
            Sync.updateJobTask('lawnmowing')
        end
    end)
end

---@param key number
---@param isInitiator boolean
function Mission.onTrimPruneTree(key, isInitiator)
    local entry = State.prunegrassObject[key]
    if not entry or not DoesEntityExist(entry.object) then return end

    entry.process = true

    local currentObject = entry.object
    local fadeComplete = false
    local newObjectReady = not isInitiator
    local newObject

    CreateThread(function()
        local alpha = 255
        while alpha > 0 and DoesEntityExist(currentObject) do
            SetEntityAlpha(currentObject, alpha, false)

            if alpha <= 150 and isInitiator and not newObject then
                local models = State.cfg.models.prunegrass.after
                local modelName = models[math.random(#models)]
                newObject = utils.createProp(modelName, entry.coords, false)

                if newObject then
                    Sync.addObject(modelName, entry.coords, entry.heading, 'pangkasSemak', key, true)
                    SetEntityHeading(newObject, entry.heading)
                    SetEntityAsMissionEntity(newObject, true, true)
                    FreezeEntityPosition(newObject, true)
                    SetEntityAlpha(newObject, 0, false)

                    CreateThread(function()
                        local newAlpha = 0
                        while newAlpha < 255 and DoesEntityExist(newObject) do
                            SetEntityAlpha(newObject, newAlpha, false)
                            Wait(90)
                            newAlpha = math.min(newAlpha + 8, 255)
                        end
                        newObjectReady = true
                    end)
                else
                    newObjectReady = true
                end
            end

            Wait(90)
            alpha -= 8
            if alpha < 30 then alpha = 0 end
        end
        fadeComplete = true
    end)

    if not isInitiator then return end

    CreateThread(function()
        lib.requestNamedPtfxAsset('core', 10000)
        while not (fadeComplete and newObjectReady) do
            UseParticleFxAssetNextCall('core')
            StartParticleFxNonLoopedAtCoord('ent_dst_wood_splinter', entry.coords.x, entry.coords.y,
                entry.coords.z + 1.0, 0.0, 0.0, entry.heading, 1.0, false, false, false)
            Wait(500)
        end
    end)

    Util.playAnim('trim')

    while not (fadeComplete and newObjectReady) do
        Wait(0)
    end

    if DoesEntityExist(currentObject) then
        DeleteObject(currentObject)
    end

    State.prunegrassObject[key] = {
        object = newObject,
        coords = entry.coords,
        heading = entry.heading,
        id = key,
        process = true,
    }

    Sync.updateJobTask('prunegrass')
    Sync.blipsDelete(key, 'prunegrass')
    exports.rhd_interact:removeCoords(trimInteractionId(key))
end

function Mission.teardown()
    Mission.toggleTrimInteractions(false)

    for _, group in ipairs({ State.mowerObject, State.prunegrassObject }) do
        for key, entry in pairs(group) do
            if entry.object and DoesEntityExist(entry.object) then
                DeleteObject(entry.object)
            end
            group[key] = nil
        end
    end
end

return Mission
