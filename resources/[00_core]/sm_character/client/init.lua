local config = require 'config.client'
local intro = require 'client.intro'
local select = require 'client.select'
local utils = require 'modules.client.utils'
local world = require 'modules.client.world'
local nui = require 'modules.client.nui'

require 'client.partner'
require 'client.debug'

local nuiReady = false
local loading = false
local previewing = false
---@type { done: boolean, payload: table|false }?
local background

local function guard()
    CreateThread(function()
        while NetworkIsInTutorialSession() do
            HideHudAndRadarThisFrame()
            SetEntityInvincible(cache.ped, true)
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            Wait(0)
        end

        SetEntityInvincible(cache.ped, false)
    end)
end

local function enterSession()
    NetworkStartSoloTutorialSession()

    pcall(lib.waitFor, function()
        return NetworkIsInTutorialSession() or nil
    end, nil, 10000)

    local ped = cache.ped

    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    DisplayRadar(false)
    config.hud.hide()
    guard()
end

local function prefetch()
    ---@type { done: boolean, payload: table|false }
    local job = { done = false, payload = false }

    background = job

    CreateThread(function()
        local ok, payload = pcall(select.load)

        if not ok then
            lib.print.error(('gagal mengambil data karakter: %s'):format(payload))
        end

        job.payload = ok and payload or false
        job.done = true
    end)
end

---@return table|false
local function fetch()
    local job = background

    background = nil

    if job then
        pcall(lib.waitFor, function()
            return job.done or nil
        end, nil, false)

        if job.payload then return job.payload end
    end

    return select.load()
end

---@return boolean
local function open()
    local began = GetGameTimer()
    local payload = fetch()
    if not payload then return false end

    local view = select.prepare(payload)

    intro.stop()
    nui.send('loading', { visible = false })
    select.show(view)
    lib.print.info(('memuat karakter: total %d ms'):format(GetGameTimer() - began))

    return true
end

---@return boolean
local function load()
    if loading then return false end

    loading = true
    nui.send('loading', { visible = true })
    utils.fadeOut(400)
    intro.hold()

    local ok, result = pcall(open)

    loading = false

    if ok and result then return true end

    if not ok then
        lib.print.error(('gagal memuat pemilihan karakter: %s'):format(result))
    end

    if select.isActive() then
        select.close()
    end

    nui.send('loading', { visible = false, error = true })
    intro.resume()

    return false
end

local function endPreview()
    local ped = PlayerPedId()

    utils.fadeOut(400)
    intro.stop()
    RenderScriptCams(false, false, 0, true, false)
    world.unlock()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    nui.focus(false)
    config.hud.show()
    previewing = false
    utils.fadeIn(800)
end

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    cb(1)
end)

RegisterNUICallback('start', function(_, cb)
    cb(1)

    if previewing then
        return endPreview()
    end

    load()
end)

RegisterNetEvent('sm_characters:client:previewIntro', function()
    if GetInvokingResource() or previewing or select.isActive() or not LocalPlayer.state.isLoggedIn then return end

    local ped = cache.ped

    previewing = true
    utils.fadeOut(500)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    config.hud.hide()
    intro.start()
end)

RegisterNetEvent('sm_characters:client:logout', function()
    if GetInvokingResource() then return end

    utils.fadeOut(500)
    enterSession()
    load()
end)

RegisterNetEvent('sm_characters:client:refresh', function()
    if GetInvokingResource() or not select.isActive() then return end

    utils.fadeOut(300)
    select.close()
    load()
end)

CreateThread(function()
    pcall(function()
        exports.spawnmanager:setAutoSpawn(false)
    end)

    while not NetworkIsSessionStarted() do
        Wait(100)
    end

    if LocalPlayer.state.isLoggedIn then return end

    DoScreenFadeOut(0)
    enterSession()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    pcall(lib.waitFor, function()
        return nuiReady or nil
    end, nil, 30000)

    intro.start()
    prefetch()
end)
