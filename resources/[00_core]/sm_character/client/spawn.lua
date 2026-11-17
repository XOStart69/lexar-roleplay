local config = require 'config.client'
local camera = require 'modules.client.camera'
local utils = require 'modules.client.utils'
local world = require 'modules.client.world'
local nui = require 'modules.client.nui'
local phone = require 'client.phone'

local PRESPAWN_MS <const> = 2000
local SETTLE_MS <const> = 500
local APPEARANCE_START_TIMEOUT <const> = 4000
local APPEARANCE_DONE_TIMEOUT <const> = 15000
local APPEARANCE_SETTLE_MS <const> = 300
local RELEASE_KEY <const> = 38
local SPAWN_LIFT <const> = 1.0

local spawn = {}

---@class SpawnInfo
---@field name string
---@field child? boolean

---@type SpawnInfo?
local current
---@type fun()?
local cleanup
---@type table[]
local locations = {}
local busy = false

---@param coords vector4
---@return vector4
local function lifted(coords)
    return vec4(coords.x, coords.y, coords.z + SPAWN_LIFT, coords.w)
end

---@param ped number
local function reveal(ped)
    camera.destroy(0)
    world.unlock()
    ClearPedTasksImmediately(ped)
    SetEntityVisible(ped, true, false)

    Wait(SETTLE_MS)
    utils.fadeIn(1000)
end

---@param ped number
local function release(ped)
    NetworkEndTutorialSession()
    FreezeEntityPosition(ped, false)

    TriggerServerEvent('sm_characters:server:spawned')
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    current = nil
    cleanup = nil
    busy = false
end

local function waitAppearance()
    local state = LocalPlayer.state

    local started = pcall(lib.waitFor, function()
        return state.hide_itemattach == true or nil
    end, nil, APPEARANCE_START_TIMEOUT)

    if started then
        pcall(lib.waitFor, function()
            return state.hide_itemattach ~= true or nil
        end, nil, APPEARANCE_DONE_TIMEOUT)
    end

    Wait(APPEARANCE_SETTLE_MS)
end

local function waitRelease()
    lib.showTextUI('[E] Mulai bermain')

    while not IsControlJustPressed(0, RELEASE_KEY) do
        Wait(0)
    end

    lib.hideTextUI()
end

---@param isNew boolean
local function complete(isNew)
    pcall(lib.waitFor, function()
        return LocalPlayer.state.isLoggedIn or nil
    end, nil, 15000)

    DisplayRadar(true)
    config.hud.show()

    TriggerEvent('rhd_spawn:client:onSpawn', isNew)
    TriggerServerEvent('rhd_spawn:server:onSpawn', isNew)
end

---@param location { label: string, coords: vector4, freezeControl?: boolean }
local function arrive(location)
    utils.fadeOut(500)
    phone.close(true)

    if cleanup then
        cleanup()
    end

    camera.destroy(0)
    Wait(PRESPAWN_MS)

    local ped = PlayerPedId()

    utils.teleport(ped, lifted(location.coords))
    reveal(ped)

    nui.send('arrival', { label = location.label, duration = config.spawn.arrivalTitleMs })
    Wait(config.spawn.arrivalTitleMs + 600)

    if location.freezeControl then
        waitRelease()
    end

    release(ped)
    waitAppearance()
    complete(false)
end

---@param id string
local function onPick(id)
    if busy then return end

    busy = true

    local location = lib.callback.await('sm_characters:spawn', false, id)

    if not location then
        busy = false
        lib.notify({ description = 'Lokasi tidak valid, coba pilih lagi.', type = 'error' })
        phone.rerender(locations, { name = current?.name })
        return
    end

    arrive(location)
end

function spawn.preload()
    phone.preload()
end

---@param list table[]
---@param info SpawnInfo
---@param onArrive? fun()
---@param onHold? fun(): boolean
function spawn.phone(list, info, onArrive, onHold)
    current = info
    cleanup = onArrive
    locations = list
    busy = false
    phone.open(list, { name = info.name }, onPick, { child = info.child, steady = onHold })
end

---@param coords vector4
---@param gender 'male'|'female'
function spawn.newCharacter(coords, gender)
    utils.fadeOut(500)
    camera.destroy(0)
    Wait(PRESPAWN_MS)

    local ped = PlayerPedId()

    utils.teleport(ped, lifted(coords))
    reveal(ped)
    release(ped)

    local completed = false

    local function finished()
        if completed then return end

        completed = true

        CreateThread(function()
            complete(true)
        end)
    end

    exports.sm_appearance:createCharacter(gender, finished, finished)
end

RegisterNetEvent('sm_characters:client:forceSpawn', function(location)
    if GetInvokingResource() or not phone.isOpen() or busy then return end

    busy = true
    arrive(location)
end)

RegisterNetEvent('sm_characters:client:rerender', function(list)
    if GetInvokingResource() or not current then return end

    locations = list
    phone.render(list, { name = current.name })
end)

return spawn
