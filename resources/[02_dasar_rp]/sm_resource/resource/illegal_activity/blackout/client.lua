local action = {}

local cs
local si

local scene = require 'resource.illegal_activity.utils.scene'
local config = require 'resource.illegal_activity.blackout.config'
local items = require 'modules.items.client'

local function playSound(coords)
    local SoundId = GetSoundId()
    local SoundName = 'alarm_loop'
    local SoundRef = 'DLC_SM_Escort_Sounds'

    PlaySoundFromCoord(
        SoundId,
        SoundName,
        coords.x, coords.y, coords.z,
        SoundRef, false, 20, false
    )
    ReleaseSoundId(SoundId)

    si = SoundId
end

local function stopSound(SoundId)
    if not SoundId then return end

    StopSound(SoundId)
end

local function validate(stage)
    local data = config[stage]
    if not data then return end

    if data.requireItems and not items.checkRequired(data.requireItems) then
        return
    end

    local allowed = lib.callback.await('illegal_blackout:cooldown', false, stage)

    if not allowed then
        return
    end

    local success = scene[data.scene.name] and scene[data.scene.name]({
        coords = data.scene.coords,
        minigame = function()
            local minigame = data.scene.minigame

            if minigame and not minigame() then return false end

            return lib.callback.await('illegal_blackout:consume', false, stage)
        end,
        card = false,
    })

    if not success then
        return
    end

    cs = stage

    return true
end

local function execute(stage)
    if not validate(stage) then return end
    TriggerServerEvent('illegal_blackout:execute')
end

local function fixGarduListrik()
    local success = bl_ui.waveMatch(3, {
        duration = 50000,
    })

    if not success then
        return
    end

    cs = 'perbaikan'
    TriggerServerEvent('illegal_blackout:perbaikan')
end

lib.callback.register('illegal_blackout:cs', function ()
    local stage = cs cs = nil
    return stage
end)

local function applyState(stage)
    for k, v in pairs(stage) do
        config[k]?.enable = v
    end
end

RegisterNetEvent('illegal_blackout:syncstate', function(stage)
    if source == '' then return end
    applyState(stage)
end)

RegisterNetEvent('illegal_blackout:syncsound', function(state, coords)
    if source == '' then return end

    if state then
        stopSound(si)
        playSound(coords)
    else
        stopSound(si)
    end
end)

RegisterNetEvent('illegal_blackout:setBlackout', function(state)
    if source == '' then return end

    SetArtificialLightsState(state)
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local state = lib.callback.await('illegal_blackout:gc', false)
    if state then applyState(state) end
end)

CreateThread(function ()
    for stage, data in pairs(config) do
        if data.target then
            local target = data.target

            local options = {
                {
                    label = target.label,
                    icon = 'fas fa-circle-info',
                    distance = target.distance,
                    onSelect = function ()
                        execute(stage)
                    end,
                    canInteract = function ()
                        return not GlobalState.blackOut and config[stage].enable
                    end
                },
            }

            if stage == 'shutdown' then
                options[#options+1] = {
                    label = 'Perbaiki listrik',
                    icon = 'fas fa-circle-info',
                    distance = target.distance,
                    onSelect = function ()
                        fixGarduListrik()
                    end,
                    groups = 'police',
                    canInteract = function ()
                        return GlobalState.blackOut
                    end
                }
            end
            
            ox_target:addSphereZone({
                coords = target.coords,
                radius = target.radius or 0.5,
                options = options
            })
        end
    end
end)