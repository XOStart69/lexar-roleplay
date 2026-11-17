local ObjectManagement = {}
local knownDrops = {}
local droppedObjects = {}

local config = localmodule 'config'

local function playAnim(anim)
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip or anim.name, 2.0, 2.0, -1, anim.flag or 51, 0, false, false, false)
    RemoveAnimDict(anim.dict)
end

local function removeDropObject(id)
    local drop = droppedObjects[id]
    if not drop then return end

    if drop.entity and DoesEntityExist(drop.entity) then
        for i = 1, #drop.names do
            ox_target:removeLocalEntity(drop.entity, drop.names[i])
        end

        DeleteEntity(drop.entity)
    end

    droppedObjects[id] = nil
end

local function removeDrop(id)
    knownDrops[id] = nil
    removeDropObject(id)
end

local function shouldSpawnDrop(drop)
    local coords = drop and drop.coords
    if type(coords) ~= 'table' or not coords.x or not coords.y or not coords.z then return false end

    local dropCoords = vector3(coords.x, coords.y, coords.z)
    return #(GetEntityCoords(cache.ped) - dropCoords) <= (config.Drop.streamDistance or 80.0)
end

local function openDroppedGiftBox(id)
    playAnim(config.PropsData.opening.anim)

    local opened = lib.progressBar({
        duration = config.PropsData.opening.progressBar.duration,
        label = config.PropsData.opening.progressBar.label,
        useWhileDead = config.PropsData.opening.progressBar.useWhileDead,
        canCancel = config.PropsData.opening.progressBar.canCancel,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        }
    })

    ClearPedTasks(cache.ped)

    if not opened then
        lib.notify({
            type = 'error',
            description = 'Opening cancelled'
        })
        return
    end

    local success, message = lib.callback.await('rhd_giftbox:server:openDroppedGiftBox', false, id)
    if success then
        removeDrop(id)
    end

    lib.notify({
        type = success and 'success' or 'error',
        description = message or (success and 'Gift box opened' or 'Failed to open gift box')
    })
end

print('loaded object management')

local function takeDroppedGiftBox(id)
    local success, message = lib.callback.await('rhd_giftbox:server:takeDroppedGiftBox', false, id)
    if success then
        removeDrop(id)
    end

    lib.notify({
        type = success and 'success' or 'error',
        description = message or (success and 'Gift box picked up' or 'Failed to pick up gift box')
    })
end

local function createDropObject(drop)
    local id = tonumber(drop and drop.id)
    local coords = drop and drop.coords
    if not id or type(coords) ~= 'table' or not coords.x or not coords.y or not coords.z then return end
    if droppedObjects[id] or not shouldSpawnDrop(drop) then return end

    droppedObjects[id] = {
        loading = true,
        names = {}
    }

    local model = joaat(drop.model or config.PropsData.carry.props.model)
    lib.requestModel(model, 5000)

    if not knownDrops[id] or not droppedObjects[id] then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, drop.heading or 0.0)
    SetEntityCollision(entity, true, true)
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(model)

    local name = ('rhd_giftbox_drop_%s'):format(id)
    local takeName = ('%s_take'):format(name)
    droppedObjects[id] = {
        entity = entity,
        names = { name, takeName }
    }

    ox_target:addLocalEntity(entity, {
        {
            name = name,
            label = 'Open Gift Box',
            icon = 'fa-solid fa-gift',
            distance = config.Drop.interactDistance,
            onSelect = function()
                openDroppedGiftBox(id)
            end
        },
        {
            name = takeName,
            label = 'Take Gift Box',
            icon = 'fa-solid fa-hand',
            distance = config.Drop.interactDistance,
            onSelect = function()
                takeDroppedGiftBox(id)
            end
        }
    })
end

local function refreshDropObject(id)
    local drop = knownDrops[id]
    if not drop then
        removeDropObject(id)
        return
    end

    if shouldSpawnDrop(drop) then
        createDropObject(drop)
    else
        removeDropObject(id)
    end
end

function ObjectManagement.syncDrops(drops)
    if type(drops) ~= 'table' then return end

    local synced = {}
    for i = 1, #drops do
        local drop = drops[i]
        local id = tonumber(drop and drop.id)
        if id then
            synced[id] = true
            knownDrops[id] = drop
            refreshDropObject(id)
        end
    end

    for id in pairs(knownDrops) do
        if not synced[id] then
            removeDrop(id)
        end
    end
end

function ObjectManagement.addDrop(drop)
    local id = tonumber(drop and drop.id)
    if not id then return end

    knownDrops[id] = drop
    refreshDropObject(id)
end

function ObjectManagement.removeDrop(id)
    removeDrop(tonumber(id))
end

function ObjectManagement.cleanup()
    for id in pairs(droppedObjects) do
        removeDropObject(id)
    end
end

RegisterNetEvent('rhd_giftbox:client:syncDrops', function(drops)
    if source == '' then return end

    ObjectManagement.syncDrops(drops)
end)

RegisterNetEvent('rhd_giftbox:client:addDrop', function(drop)
    if source == '' then return end

    ObjectManagement.addDrop(drop)
end)

RegisterNetEvent('rhd_giftbox:client:removeDrop', function(id)
    if source == '' then return end

    ObjectManagement.removeDrop(id)
end)

RegisterNetEvent('rhd_giftbox:client:removeDropTarget', function(id)
    if source == '' then return end

    ObjectManagement.removeDrop(id)
end)

CreateThread(function()
    Wait(1500)

    local drops = lib.callback.await('rhd_giftbox:server:getDrops', 1500)
    ObjectManagement.syncDrops(drops or {})
end)

CreateThread(function()
    while true do
        Wait(2500)

        for id in pairs(knownDrops) do
            refreshDropObject(id)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    ObjectManagement.cleanup()
end)

return ObjectManagement
