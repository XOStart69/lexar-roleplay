local State = require 'pelumber.modules.client.state'
local Util = require 'pelumber.modules.client.util'
local utils = require 'modules.utils'

local Vehicle = {}

local TAKE_DICT = 'anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal'
local TAKE_CLIP = 'pickup'

---@type string[]?
local vehicleOptionNames = nil

local isInteracting = false

---@param veh number
---@return boolean
local function trunkOpen(veh)
    return GetVehicleDoorAngleRatio(veh, 2) > 0.0 or GetVehicleDoorAngleRatio(veh, 3) > 0.0
end

---@param veh number
local function toggleTrunk(veh)
    for _, doorIndex in ipairs({ 2, 3 }) do
        if GetVehicleDoorAngleRatio(veh, doorIndex) > 0.0 then
            SetVehicleDoorShut(veh, doorIndex, false)
        else
            SetVehicleDoorOpen(veh, doorIndex, false, false)
        end
    end
end

---@param entity? number
---@return boolean
local function isJobVehicle(entity)
    if not State.mission or not entity then return false end
    return entity == Util.getJobVehicle()
end

---@param entity? number
---@return boolean
local function canTakeFromTrunk(entity)
    if not isJobVehicle(entity) then return false end
    return not IsPedInAnyVehicle(cache.ped, false)
        and Util.getValidHandObject() == nil
        and not isInteracting
        and trunkOpen(entity --[[@as number]])
end

---@param entity? number
---@return boolean
local function canTakeSide(entity)
    if not isJobVehicle(entity) then return false end
    return not IsPedInAnyVehicle(cache.ped, false)
        and Util.getValidHandObject() == nil
        and not isInteracting
end

---@param entity? number
---@return boolean
local function canPutBack(entity)
    if not isJobVehicle(entity) then return false end
    return not IsPedInAnyVehicle(cache.ped, false)
        and Util.getValidHandObject() ~= nil
        and not isInteracting
end

---@param model string
---@param kind 'pipe'|'valve'
local function takeProp(model, kind)
    if isInteracting then return end
    if Util.getValidHandObject() then
        Util.notifyLocal('Kembalikan dulu peralatan yang sedang kamu bawa.', 'error')
        return
    end

    isInteracting = true

    local ped = cache.ped
    if utils.waitForAnim(TAKE_DICT) then
        TaskPlayAnim(ped, TAKE_DICT, TAKE_CLIP, 4.0, 4.0, 500, 48, 0, false, false, false)
    end
    Wait(500)

    local coords = GetEntityCoords(ped)
    local obj = utils.createProp(model, coords, false)
    if obj then
        Util.addPlayerHandObject(obj, model, kind, kind == 'pipe' and model or nil)
    else
        Util.notifyLocal('Gagal menyiapkan peralatan.', 'error')
    end

    SetTimeout(400, function() isInteracting = false end)
end

local function putBack()
    if isInteracting then return end
    if not Util.getValidHandObject() then return end

    isInteracting = true

    local ped = cache.ped
    if utils.waitForAnim(TAKE_DICT) then
        TaskPlayAnim(ped, TAKE_DICT, TAKE_CLIP, 4.0, 4.0, 400, 48, 0, false, false, false)
    end
    Wait(400)

    Util.resetPlayerHandObject()
    SetTimeout(400, function() isInteracting = false end)
end

local function buildOptions()
    local backOffset = vector3(0.0, -2.6, 0.5)
    local rightOffset = vector3(1.3, -1.0, 0.5)
    local leftOffset = vector3(-1.3, -1.0, 0.5)

    return {
        {
            name = 'sm_pelumber_veh_door',
            label = 'Buka/Tutup Bagasi',
            icon = 'fas fa-car',
            offset = backOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = function(entity)
                return isJobVehicle(entity)
                    and not IsPedInAnyVehicle(cache.ped, false)
                    and not isInteracting
            end,
            onSelect = function(data)
                if not data.entity then return end
                toggleTrunk(data.entity)
            end,
        },
        {
            name = 'sm_pelumber_veh_backPut1',
            label = 'Kembalikan Peralatan',
            icon = 'fas fa-car',
            offset = backOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canPutBack,
            onSelect = function(data)
                if not data.entity then return end
                putBack()
            end,
        },
        {
            name = 'sm_pelumber_veh_tpipe',
            label = 'Ambil Pipa T',
            icon = 'fas fa-car',
            offset = backOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canTakeFromTrunk,
            onSelect = function(data)
                if not data.entity then return end
                takeProp('veo_pipes_p', 'pipe')
            end,
        },
        {
            name = 'sm_pelumber_veh_valve',
            label = 'Ambil Katup',
            icon = 'fas fa-car',
            offset = backOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canTakeFromTrunk,
            onSelect = function(data)
                if not data.entity then return end
                takeProp('prop_oil_valve_01', 'valve')
            end,
        },
        {
            name = 'sm_pelumber_veh_backPut2',
            label = 'Kembalikan Peralatan',
            icon = 'fas fa-car',
            offset = rightOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canPutBack,
            onSelect = function(data)
                if not data.entity then return end
                putBack()
            end,
        },
        {
            name = 'sm_pelumber_veh_shortpipe',
            label = 'Ambil Pipa Pendek',
            icon = 'fas fa-car',
            offset = rightOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canTakeSide,
            onSelect = function(data)
                if not data.entity then return end
                takeProp('veo_pipes_d', 'pipe')
            end,
        },
        {
            name = 'sm_pelumber_veh_longpipe',
            label = 'Ambil Pipa Panjang',
            icon = 'fas fa-car',
            offset = rightOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canTakeSide,
            onSelect = function(data)
                if not data.entity then return end
                takeProp('veo_pipes_c', 'pipe')
            end,
        },
        {
            name = 'sm_pelumber_veh_backPut3',
            label = 'Kembalikan Peralatan',
            icon = 'fas fa-car',
            offset = leftOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canPutBack,
            onSelect = function(data)
                if not data.entity then return end
                putBack()
            end,
        },
        {
            name = 'sm_pelumber_veh_shortbend',
            label = 'Ambil Belokan Pendek',
            icon = 'fas fa-car',
            offset = leftOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canTakeSide,
            onSelect = function(data)
                if not data.entity then return end
                takeProp('veo_pipes_e', 'pipe')
            end,
        },
        {
            name = 'sm_pelumber_veh_longbend',
            label = 'Ambil Belokan Panjang',
            icon = 'fas fa-car',
            offset = leftOffset,
            absoluteOffset = true,
            distance = 1.8,
            canInteract = canTakeSide,
            onSelect = function(data)
                if not data.entity then return end
                takeProp('veo_pipes_f', 'pipe')
            end,
        },
    }
end

function Vehicle.setup()
    local mission = State.mission
    if vehicleOptionNames or not mission or not mission.vehicleNetId then return end

    local options = buildOptions()
    vehicleOptionNames = {}
    for i = 1, #options do
        vehicleOptionNames[i] = options[i].name
    end
    exports.ox_target:addGlobalVehicle(options)
end

function Vehicle.teardown()
    if vehicleOptionNames then
        exports.ox_target:removeGlobalVehicle(vehicleOptionNames)
        vehicleOptionNames = nil
    end
end

return Vehicle
