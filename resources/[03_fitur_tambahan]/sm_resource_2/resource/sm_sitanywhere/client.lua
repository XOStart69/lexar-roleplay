local config = localmodule 'config'

local Wait = Wait
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local SetEntityCoords = SetEntityCoords
local smatch = string.match

local BEDS = config.beds
local HEADING_OFFSET = config.headingOffset
local DISTANCE = config.distance
local FIRST_PERSON = config.firstPersonOnSit
local SEAT_SCENARIO = 'PROP_HUMAN_SEAT_BENCH'
local LIE_DICT = 'amb@world_human_sunbathe@male@back@base'
local LIE_CLIP = 'base'
local DRIFT_LIMIT = 0.05

---@type 'sit'|'lie'|nil
local pose
local seatEntity
local returnCoords
local returnHeading
local previousCamMode

---@param entity number
---@return boolean
local function isBed(entity)
    return entity ~= 0 and BEDS[GetEntityModel(entity)] ~= nil
end

---@param entity number
local function lockSeat(entity)
    seatEntity = entity
    FreezeEntityPosition(entity, true)
end

local function rememberPosition()
    returnCoords = GetEntityCoords(cache.ped)
    returnHeading = GetEntityHeading(cache.ped)

    if FIRST_PERSON then
        previousCamMode = GetFollowPedCamViewMode()
        SetFollowPedCamViewMode(4)
    end
end

---@param entity number
---@param clicked? vector3
local function sit(entity, clicked)
    if pose or not DoesEntityExist(entity) then return end

    local ped = cache.ped
    local seat = GetEntityCoords(entity)
    local name = GetEntityArchetypeName(entity)
    local heading = GetEntityHeading(entity) + 180.0 + (HEADING_OFFSET[name] or 0.0)

    if clicked and smatch(name, 'bench') then
        seat = clicked
    end

    rememberPosition()
    lockSeat(entity)

    local z = GetEntityCoords(ped).z - 0.5
    TaskStartScenarioAtPosition(ped, SEAT_SCENARIO, seat.x, seat.y, z, heading, 0, true, true)
    pose = 'sit'
end

---@param entity number
---@param origin vector3
---@param heading number
local function holdBed(entity, origin, heading)
    CreateThread(function()
        while pose == 'lie' and seatEntity == entity and DoesEntityExist(entity) do
            if #(GetEntityCoords(entity) - origin) > DRIFT_LIMIT then
                SetEntityCoords(entity, origin.x, origin.y, origin.z, false, false, false, false)
                SetEntityHeading(entity, heading)
            end
            Wait(250)
        end
    end)
end

---@param entity number
local function lieDown(entity)
    if pose or not DoesEntityExist(entity) then return end
    if not pcall(lib.requestAnimDict, LIE_DICT, 5000) then return end

    local ped = cache.ped
    local bed = GetEntityCoords(entity)
    local bedHeading = GetEntityHeading(entity)
    local heading = BEDS[GetEntityModel(entity)] or bedHeading

    rememberPosition()
    lockSeat(entity)
    SetEntityCollision(entity, false, false)
    SetEntityInvincible(entity, true)

    SetEntityCollision(ped, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, bed.x, bed.y, bed.z + 0.35, false, false, false, true)
    SetEntityHeading(ped, heading)

    ClearPedTasks(ped)
    TaskPlayAnim(ped, LIE_DICT, LIE_CLIP, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    RemoveAnimDict(LIE_DICT)

    pose = 'lie'
    holdBed(entity, bed, bedHeading)
end

local function standUp()
    if not pose then return end

    local ped = cache.ped
    local wasLying = pose == 'lie'
    pose = nil

    ClearPedTasks(ped)

    if wasLying then
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        if returnCoords then
            SetEntityCoords(ped, returnCoords.x, returnCoords.y, returnCoords.z, false, false, false, true)
            SetEntityHeading(ped, returnHeading)
        end
    end

    local entity = seatEntity
    seatEntity = nil
    if entity and DoesEntityExist(entity) then
        FreezeEntityPosition(entity, false)
        SetEntityCollision(entity, true, true)
        SetEntityInvincible(entity, false)
    end

    if previousCamMode then
        SetFollowPedCamViewMode(previousCamMode)
        previousCamMode = nil
    end
end

ox_target:addModel(config.chairs, {
    {
        name = 'sm_sit',
        label = 'Duduk',
        icon = 'fa-solid fa-chair',
        distance = DISTANCE,
        canInteract = function(entity) return not pose and not isBed(entity) end,
        onSelect = function(data) sit(data.entity, data.coords) end,
    },
    {
        name = 'sm_liedown',
        label = 'Berbaring',
        icon = 'fa-solid fa-bed',
        distance = DISTANCE,
        canInteract = function(entity) return not pose and isBed(entity) end,
        onSelect = function(data) lieDown(data.entity) end,
    },
    {
        name = 'sm_standup',
        label = 'Berdiri',
        icon = 'fa-solid fa-person',
        distance = DISTANCE,
        canInteract = function() return pose ~= nil end,
        onSelect = standUp,
    },
})

RegisterCommand('neveradev:sit:stand_up', standUp, false)
RegisterCommand('neveradev:sit:stand_up_x', standUp, false)
RegisterCommand('neveradev:sit:stand_up_space', standUp, false)
RegisterKeyMapping('neveradev:sit:stand_up_x', 'Berdiri dari duduk (X)', 'keyboard', 'X')
RegisterKeyMapping('neveradev:sit:stand_up_space', 'Berdiri dari duduk (SPACE)', 'keyboard', 'SPACE')

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        standUp()
    end
end)
