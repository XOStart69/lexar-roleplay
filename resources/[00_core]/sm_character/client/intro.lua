local config = require 'config.client'.intro
local world = require 'modules.client.world'
local nui = require 'modules.client.nui'

local FADE_WAIT <const> = 3000

local intro = {}
local running = false
local flying = false
local alive = false
local focused = false
local session = 0
local generation = 0

local function fly()
    generation += 1
    flying = true
    alive = true

    local mine = generation

    local function live()
        return flying and mine == generation
    end

    CreateThread(function()
        local index = 1
        local shots = config.shots

        while live() do
            local shot = shots[index]
            local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', shot.from.x, shot.from.y, shot.from.z, 0.0, 0.0, 0.0, shot.fov, true, 2)

            PointCamAtCoord(cam, shot.target.x, shot.target.y, shot.target.z)
            RenderScriptCams(true, false, 0, true, false)

            if focused then
                SetFocusPosAndVel(shot.from.x, shot.from.y, shot.from.z, 0.0, 0.0, 0.0)
            end

            Wait(500)

            if live() then
                DoScreenFadeIn(1500)
            end

            local began = GetGameTimer()
            local nextFocus = 0
            local fading = false

            while live() do
                local now = GetGameTimer()
                local elapsed = now - began

                if elapsed >= shot.duration then break end

                local position = shot.from + (shot.to - shot.from) * (elapsed / shot.duration)

                SetCamCoord(cam, position.x, position.y, position.z)
                PointCamAtCoord(cam, shot.target.x, shot.target.y, shot.target.z)

                if focused and now >= nextFocus then
                    SetFocusPosAndVel(position.x, position.y, position.z, 0.0, 0.0, 0.0)
                    nextFocus = now + 250
                end

                if not fading and #shots > 1 and elapsed >= shot.duration - 1500 then
                    DoScreenFadeOut(1500)
                    fading = true
                end

                Wait(0)
            end

            if fading and live() then
                local deadline = GetGameTimer() + FADE_WAIT

                while live() and not IsScreenFadedOut() and GetGameTimer() < deadline do
                    Wait(0)
                end
            end

            DestroyCam(cam, false)
            index = index % #shots + 1
        end

        if mine ~= generation then return end

        if focused then
            ClearFocus()
        end

        alive = false
    end)
end

function intro.start()
    if running then return end

    running = true
    focused = true
    session += 1
    world.lock(config.hour, config.minute, config.weather)

    local current = session

    SetTimeout(config.uiDelay, function()
        if not running or session ~= current then return end

        nui.send('intro', { visible = true, store = config.store, credits = config.credits })
        nui.focus(true)
    end)

    fly()
end

function intro.releaseFocus()
    if not focused then return end

    focused = false
    ClearFocus()
end

function intro.hold()
    if not flying then return end

    flying = false
    intro.releaseFocus()

    pcall(lib.waitFor, function()
        return not alive or nil
    end, nil, FADE_WAIT)
end

function intro.resume()
    if not running then return intro.start() end
    if flying then return end

    focused = true
    world.lock(config.hour, config.minute, config.weather)
    fly()
end

function intro.stop()
    running = false
    nui.send('intro', { visible = false })
    intro.hold()
end

return intro
