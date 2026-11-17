local Config = localmodule 'config.shared'

local zoneState = {}
local markerThread = nil

local function shuffled(t)
    local copy = {}
    for i, v in ipairs(t) do copy[i] = v end
    for i = #copy, 2, -1 do
        local j = math.random(i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    return copy
end

local function hasActiveMarkers()
    for _, state in pairs(zoneState) do
        if next(state.activeMarkers) then return true end
    end
    return false
end

local function startMarkerThread()
    if markerThread then return end
    markerThread = Citizen.CreateThread(function()
        while hasActiveMarkers() do
            for _, state in pairs(zoneState) do
                for _, m in pairs(state.activeMarkers) do
                    local c = m.color
                    DrawMarker(20,
                        m.coords.x, m.coords.y, m.coords.z,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.8, 0.8, 0.8,
                        c.r, c.g, c.b, c.a,
                        true, true, 2, true, nil, nil, false
                    )
                end
            end
            Citizen.Wait(0)
        end
        markerThread = nil
    end)
end

local function spawnTree(zoneName, treeIndex)
    local zoneData = nil
    for _, z in ipairs(Config) do
        if z.name == zoneName then zoneData = z break end
    end
    if not zoneData then return end

    local state = zoneState[zoneName]
    local coords = zoneData.trees[treeIndex]
    local interactCoords = vec3(coords.x, coords.y, coords.z + 0.5)
    local markerCoords = vec3(coords.x, coords.y, coords.z + zoneData.markerHeight)

    local id = exports.rhd_interact:addCoords({
        coords = interactCoords,
        options = {
            {
                label = "Petik " .. zoneData.label,
                icon = "fa-solid fa-seedling",
                distance = 3.0,
                onSelect = function()
                    TriggerEvent("petikbuah:tryPickFruit", zoneData, treeIndex)
                end,
            }
        }
    })

    state.activeInteracts[treeIndex] = id
    state.activeMarkers[treeIndex] = {
        coords = markerCoords,
        color = zoneData.markerColor,
    }

    startMarkerThread()
end

local function removeTree(zoneName, treeIndex)
    local state = zoneState[zoneName]
    if not state then return end

    if state.activeInteracts[treeIndex] then
        exports.rhd_interact:removeCoords(state.activeInteracts[treeIndex])
        state.activeInteracts[treeIndex] = nil
    end

    state.activeMarkers[treeIndex] = nil
end

local function spawnNextAvailable(zoneName)
    local state = zoneState[zoneName]
    if not state or not state.pool or #state.pool == 0 then return end

    local nextIndex = table.remove(state.pool, 1)
    spawnTree(zoneName, nextIndex)
end

local function initZone(zoneData)
    local shuffledIndices = {}
    for i = 1, #zoneData.trees do
        table.insert(shuffledIndices, i)
    end
    shuffledIndices = shuffled(shuffledIndices)

    local active = {}
    local pool = {}

    for i, idx in ipairs(shuffledIndices) do
        if i <= zoneData.activeCount then
            table.insert(active, idx)
        else
            table.insert(pool, idx)
        end
    end

    zoneState[zoneData.name] = {
        activeInteracts = {},
        activeMarkers = {},
        pool = pool,
    }

    for _, idx in ipairs(active) do
        spawnTree(zoneData.name, idx)
    end
end

local function clearZone(zoneName)
    local state = zoneState[zoneName]
    if not state then return end

    for treeIndex, id in pairs(state.activeInteracts) do
        exports.rhd_interact:removeCoords(id)
    end

    zoneState[zoneName] = nil
end

Citizen.CreateThread(function()
    for _, zoneData in ipairs(Config) do
        local flatPoints = {}
        for _, p in ipairs(zoneData.zone.points) do
            table.insert(flatPoints, p)
        end

        lib.zones.poly({
            name = zoneData.name,
            points = flatPoints,
            thickness = zoneData.zone.thickness,
            onEnter = function()
                initZone(zoneData)
            end,
            onExit = function()
                clearZone(zoneData.name)
            end,
        })
    end
end)

RegisterNetEvent("petikbuah:tryPickFruit", function(zoneData, treeIndex)
    if not zoneData or not treeIndex then return end

    local canUse, message = lib.callback.await('petikbuah:checkHoeDurability', false)
    if not canUse then
        lib.notify({ title = message, type = 'error' })
        return
    end

    local playerPed = PlayerPedId()

    local completed = lib.progressBar({
        duration = zoneData.picking.progressDuration,
        label = "Memetik Buah...",
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'missmechanic',
            clip = 'work_base',
            flag = 16,
        },
    })

    ClearPedTasks(playerPed)

    if completed then
        removeTree(zoneData.name, treeIndex)
        TriggerTokenEvent("petikbuah:giveFruit", zoneData.fruit)
        spawnNextAvailable(zoneData.name)
    end
end)

-- RegisterCommand("getcoords", function()
--     local coords = GetEntityCoords(PlayerPedId())
--     local str = string.format("vec3(%.4f, %.4f, %.4f),", coords.x, coords.y, coords.z)
--     lib.setClipboard(str)
--     lib.notify({ title = "Coords Copied!", description = str, type = 'info' })
-- end, false)