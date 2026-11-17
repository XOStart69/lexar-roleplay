local Config = localmodule 'config.sirens'
local stateHandler = require 'modules.entityStateHandler.client'

local Audio = Config.audio
local Vehicles = Config.vehicles

local Wait = Wait
local Entity = Entity
local GetEntityModel = GetEntityModel
local IsEntityDead = IsEntityDead
local DisableControlAction = DisableControlAction
local PlaySoundFromEntity = PlaySoundFromEntity
local PlaySoundFrontend = PlaySoundFrontend

for i = 1, #Config.banks do
    RequestScriptAudioBank(Config.banks[i], false)
end

local DisabledControls = { 80, 81, 82, 83, 84, 85, 86, 172 }
local DisabledCount = #DisabledControls

local emergency = nil
local sounds = { horn = {}, siren = {} }

---@return table? vehicleState, integer[]? soundList
local function driverState()
    local vehicle = cache.vehicle
    if not emergency or vehicle ~= emergency or cache.seat ~= -1 or IsEntityDead(vehicle) then return end

    return Entity(vehicle).state, Vehicles[GetEntityModel(vehicle)]
end

local function beep()
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

---@param state boolean
local function toggleHorn(state)
    local vehState = driverState()
    if vehState then
        vehState:set('sirenHorn', state, true)
    end
end

local function toggleSiren()
    local vehState = driverState()
    if not vehState then return end

    local isOn = not vehState.sirenOn

    vehState:set('sirenOn', isOn, true)
    vehState:set('soundId', isOn and 1 or 0, true)

    if not isOn then
        vehState:set('sirenMode', 'HOLD', true)
        vehState:set('sirenSound', false, true)
    end

    beep()
end

local function toggleMode()
    local vehState = driverState()
    if not vehState or not vehState.sirenOn then return end

    local newMode = vehState.sirenMode == 'HOLD' and 'TAP' or 'HOLD'
    vehState:set('sirenMode', newMode, true)
    beep()

    if newMode == 'HOLD' then
        vehState:set('sirenSound', false, true)
        return
    end

    vehState:set('soundId', 2, true)
    vehState:set('sirenSound', 2, true)
end

local function sirenPressed()
    local vehState, list = driverState()
    if not vehState then return end

    local mode = vehState.sirenMode

    if mode == 'TAP' then
        if not vehState.sirenOn then return end

        local nextId = (vehState.soundId or 1) + 1
        if nextId > #list then nextId = 2 end

        vehState:set('soundId', nextId, true)
        vehState:set('sirenSound', nextId, true)
    elseif mode == 'HOLD' then
        vehState:set('sirenSound', 2, true)
    end
end

local function sirenReleased()
    local vehState = driverState()
    if vehState and vehState.sirenMode == 'HOLD' then
        vehState:set('sirenSound', false, true)
    end
end

---@param id integer
local function changeSound(id)
    local vehState, list = driverState()
    if not vehState or vehState.sirenMode ~= 'TAP' or not vehState.sirenOn or not list[id] then return end

    vehState:set('soundId', id, true)
    vehState:set('sirenSound', id, true)
end

---@param vehicle number
local function blockControls(vehicle)
    CreateThread(function()
        while emergency == vehicle and cache.vehicle == vehicle and cache.seat == -1 do
            for i = 1, DisabledCount do
                DisableControlAction(0, DisabledControls[i], true)
            end
            Wait(0)
        end
    end)
end

local function checkVehicle()
    local vehicle = cache.vehicle

    if not vehicle or cache.seat ~= -1 or not Vehicles[GetEntityModel(vehicle)] then
        emergency = nil
        return
    end

    if emergency == vehicle then return end

    emergency = vehicle

    local vehState = Entity(vehicle).state
    if not vehState.sirenMode then
        vehState:set('sirenMode', 'HOLD', true)
    end

    blockControls(vehicle)
end

lib.onCache('vehicle', function()
    SetTimeout(100, checkVehicle)
end)

lib.onCache('seat', function()
    SetTimeout(100, checkVehicle)
end)

---@param kind string
---@param entity number
local function releaseSound(kind, entity)
    local id = sounds[kind][entity]
    if not id then return end

    StopSound(id)
    ReleaseSoundId(id)
    sounds[kind][entity] = nil
end

---@param kind string
---@param entity number
---@param index integer?
local function playSound(kind, entity, index)
    local list = Vehicles[GetEntityModel(entity)]
    local audio = list and index and Audio[list[index]]
    if not audio then return end

    local id = GetSoundId()
    sounds[kind][entity] = id
    PlaySoundFromEntity(id, audio.name, entity, audio.ref, false, 0)
end

stateHandler.entityStateHandler('sirenOn', function(entity, _, value)
    if not Vehicles[GetEntityModel(entity)] then return end

    SetVehicleHasMutedSirens(entity, true)
    SetVehicleSiren(entity, value == true)
end)

stateHandler.entityStateHandler('sirenHorn', function(entity, _, value)
    releaseSound('horn', entity)

    if value == true then
        playSound('horn', entity, 1)
    end
end)

stateHandler.entityStateHandler('sirenSound', function(entity, _, value)
    releaseSound('siren', entity)

    if math.type(value) == 'integer' then
        playSound('siren', entity, value)
    end
end)

lib.addKeybind({
    name = 'toggle_sirens',
    description = 'Toggle Siren',
    defaultKey = 'Q',
    onPressed = toggleSiren
})

lib.addKeybind({
    name = 'sirens_horn',
    description = 'Siren Horn',
    defaultKey = 'E',
    onPressed = function() toggleHorn(true) end,
    onReleased = function() toggleHorn(false) end
})

lib.addKeybind({
    name = 'sirens_mode',
    description = 'Change Siren Mode',
    defaultKey = 'LMENU',
    onPressed = toggleMode
})

lib.addKeybind({
    name = 'sirens_sound',
    description = 'Play Siren (HOLD)',
    defaultKey = 'R',
    onPressed = sirenPressed,
    onReleased = sirenReleased
})

for i = 1, 6 do
    local id = i + 1

    lib.addKeybind({
        name = ('siren_sound_%d'):format(i),
        description = ('Siren Sound %d'):format(i),
        defaultKey = tostring(i),
        onPressed = function() changeSound(id) end
    })
end

CreateThread(function()
    local DoesEntityExist = DoesEntityExist

    while true do
        for kind, list in pairs(sounds) do
            for entity in pairs(list) do
                if not DoesEntityExist(entity) then
                    releaseSound(kind, entity)
                end
            end
        end
        Wait(10000)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for kind, list in pairs(sounds) do
        for entity in pairs(list) do
            releaseSound(kind, entity)
        end
    end
end)
