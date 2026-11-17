local config = localmodule 'config'
local blipList = localmodule 'data.blips'

local Wait = Wait
local SetScenarioTypeEnabled = SetScenarioTypeEnabled
local SetScenarioGroupEnabled = SetScenarioGroupEnabled
local IsPedBeingStunned = IsPedBeingStunned
local SetPedMinGroundTimeForStungun = SetPedMinGroundTimeForStungun
local InvalidateIdleCam = InvalidateIdleCam
local InvalidateVehicleIdleCam = InvalidateVehicleIdleCam
local DisableControlAction = DisableControlAction
local DisplayAmmoThisFrame = DisplayAmmoThisFrame
local IsPedArmed = IsPedArmed
local GetGameTimer = GetGameTimer
local random = math.random

local PLAYER_GROUP = `PLAYER`
local UNARMED = `WEAPON_UNARMED`
local SCENARIO_INTERVAL = 10000
local IDLE_INTERVAL = 1000
local STUN_INTERVAL = 1000

local scenarioTypes = config.scenarioTypes
local scenarioGroups = config.scenarioGroups
local blacklistedWeapons = config.blacklistedWeapons

local blips = {}
local objectPoints = {}
local armedLoop = false

for i = 1, #config.relationshipGroups do
    SetRelationshipBetweenGroups(1, config.relationshipGroups[i], PLAYER_GROUP)
end

AddTextEntry('FE_THDR_GTAO', config.pauseMapText)
SetAudioFlag('PoliceScannerDisabled', true)
SetGarbageTrucks(false)
SetCreateRandomCops(false)
SetCreateRandomCopsNotOnScenarios(false)
SetCreateRandomCopsOnScenarios(false)
DistantCopCarSirens(false)
SetMaxWantedLevel(0)

for service = 1, 15 do
    EnableDispatchService(service, false)
end

for i = 1, #config.generatorAreas do
    local area = config.generatorAreas[i]
    local c, size = area.coords, area.size

    RemoveVehiclesFromGeneratorsInArea(c.x - size, c.y - size, c.z - size, c.x + size, c.y + size, c.z + size)
end

---@param ped number
local function prepareAmbientPed(ped)
    SetPedDropsWeaponsWhenDead(ped, false)
end

local peds = GetGamePool('CPed')

for i = 1, #peds do
    prepareAmbientPed(peds[i])
end

local GetClosestPed = GetClosestPed
local PED_QUEUE_DELAY = 500
local PED_QUEUE_MAX = 64

local pedQueue = {}
local pedQueueSize = 0
local pedQueueRunning = false

local function flushPedQueue()
    local count = pedQueueSize

    for i = 1, count do
        local coords = pedQueue[i]
        local _, ped = GetClosestPed(coords.x, coords.y, coords.z, 1.0)

        if ped ~= 0 then
            prepareAmbientPed(ped)
        end

        pedQueue[i] = nil
    end

    pedQueueSize = 0
    pedQueueRunning = false
end

AddEventHandler('populationPedCreating', function(x, y, z)
    if pedQueueSize >= PED_QUEUE_MAX then return end

    pedQueueSize = pedQueueSize + 1
    pedQueue[pedQueueSize] = vec3(x, y, z)

    if pedQueueRunning then return end

    pedQueueRunning = true
    SetTimeout(PED_QUEUE_DELAY, flushPedQueue)
end)

CreateThread(function()
    local typeCount = #scenarioTypes
    local groupCount = #scenarioGroups

    while true do
        for i = 1, typeCount do
            SetScenarioTypeEnabled(scenarioTypes[i], false)
        end

        for i = 1, groupCount do
            SetScenarioGroupEnabled(scenarioGroups[i], false)
        end

        Wait(SCENARIO_INTERVAL)
    end
end)

CreateThread(function()
    local nextIdleReset = 0

    while true do
        local sleep = STUN_INTERVAL
        local ped = cache.ped

        if IsPedBeingStunned(ped, 0) then
            sleep = 0
            SetPedMinGroundTimeForStungun(ped, random(4000, 7000))
        end

        local now = GetGameTimer()

        if now >= nextIdleReset then
            nextIdleReset = now + IDLE_INTERVAL
            InvalidateIdleCam()
            InvalidateVehicleIdleCam()
        end

        Wait(sleep)
    end
end)

local function runArmedLoop()
    if armedLoop then return end

    armedLoop = true

    while cache.weapon and cache.weapon ~= UNARMED do
        local ped = cache.ped

        if IsPedArmed(ped, 6) then
            DisplayAmmoThisFrame(false)
            DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
            DisableControlAction(1, 142, true)
        end

        Wait(0)
    end

    armedLoop = false
end

lib.onCache('ped', function(ped)
    SetPedSuffersCriticalHits(ped, false)
end)

SetPedSuffersCriticalHits(cache.ped, false)

lib.onCache('weapon', function(weapon)
    if not weapon or weapon == UNARMED then return end

    if blacklistedWeapons[weapon] then
        RemoveWeaponFromPed(cache.ped, weapon)
        return
    end

    SetTimeout(0, runArmedLoop)
end)

if cache.weapon and cache.weapon ~= UNARMED then
    SetTimeout(0, runArmedLoop)
end

---@param blip number
---@param data table
local function decorateBlip(blip, data)
    SetBlipSprite(blip, data.id)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, data.colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.title)
    EndTextCommandSetBlipName(blip)

    local category = data.category

    if category then
        AddTextEntry('BLIP_CAT_' .. category.id, category.name)
        SetBlipCategory(blip, category.id)
    end
end

for i = 1, #blipList do
    local data = blipList[i]
    local coords = data.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    decorateBlip(blip, data)
    blips[i] = blip
end

for i = 1, #config.removeObjects do
    local entry = config.removeObjects[i]

    objectPoints[i] = lib.points.new({
        coords = entry.coords,
        distance = config.removeObjectDistance,
        onEnter = function()
            local object = GetClosestObjectOfType(entry.coords.x, entry.coords.y, entry.coords.z, 2.0, entry.model, false, false, false)

            if object ~= 0 then
                SetEntityAsMissionEntity(object, true, true)
                DeleteObject(object)
            end
        end,
    })
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for i = 1, #blips do
        RemoveBlip(blips[i])
    end

    for i = 1, #objectPoints do
        objectPoints[i]:remove()
    end
end)
