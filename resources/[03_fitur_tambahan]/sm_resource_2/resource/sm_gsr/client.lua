local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local IsPedShooting = IsPedShooting

local CLEAR_MS = config.clearMinutes * 60000
local particle = config.particle

local ignored = {}
for i = 1, #config.ignoredWeapons do
    ignored[config.ignoredWeapons[i]] = true
end

local lastShot = -CLEAR_MS
local watching = false

local function watchShooting()
    if watching then return end
    watching = true

    CreateThread(function()
        while cache.weapon and not ignored[cache.weapon] do
            if IsPedShooting(cache.ped) then
                lastShot = GetGameTimer()
            end
            Wait(0)
        end
        watching = false
    end)
end

lib.onCache('weapon', function(weapon)
    if weapon and not ignored[weapon] then
        SetTimeout(0, watchShooting)
    end
end)

lib.callback.register('sm_gsr:client:status', function()
    return GetGameTimer() - lastShot < CLEAR_MS
end)

RegisterNetEvent('sm_gsr:client:particle', function(targetServerId)
    local player = GetPlayerFromServerId(targetServerId)
    if player == -1 then return end
    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return end

    lib.requestNamedPtfxAsset(particle.dict)
    UseParticleFxAssetNextCall(particle.dict)
    local handle = StartParticleFxLoopedOnPedBone(particle.name, ped, 0.02, 0.02, -0.008, 0.0, 0.0, 0.0,
        GetPedBoneIndex(ped, particle.bone), particle.scale, false, false, false)

    SetTimeout(particle.duration, function()
        StopParticleFxLooped(handle, false)
        RemoveNamedPtfxAsset(particle.dict)
    end)
end)

local function checkNearest()
    local player = lib.getClosestPlayer(GetEntityCoords(cache.ped), config.checkDistance)
    if not player then
        return lib.notify({ description = 'Tidak ada orang di dekat kamu!', type = 'error' })
    end
    TriggerTokenEvent('sm_gsr:server:check', GetPlayerServerId(player))
end

RegisterCommand('gsrcheck', checkNearest, false)

exports('getGSR', checkNearest)
require 'export_wrapper' ('sm_pfeat', 'getGSR', checkNearest)
