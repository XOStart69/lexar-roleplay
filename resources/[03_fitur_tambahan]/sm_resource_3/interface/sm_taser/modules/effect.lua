local config = localmodule 'config'
local util = localmodule 'modules.util'

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetCloudTimeAsInt = GetCloudTimeAsInt
local DoesEntityExist = DoesEntityExist
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedRagdoll = IsPedRagdoll
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local SetPedToRagdoll = SetPedToRagdoll
local ApplyForceToEntity = ApplyForceToEntity
local DisableAllControlActions = DisableAllControlActions
local EnableControlAction = EnableControlAction
local GetEntityFromStateBagName = GetEntityFromStateBagName
local mrandom = math.random
local mmin = math.min
local type = type

local RAGDOLL_TICK = 1000
local NPC_RECOVERY_WAIT = 3000
local UNARMED = `WEAPON_UNARMED`
local ENABLED_CONTROLS = { 1, 2, 199, 200, 245, 249 }
local ENABLED_COUNT = #ENABLED_CONTROLS
local TWITCH_FORCE = config.twitchForce
local SHAKE_ANIMS = config.shakeAnims
local NPC_AFTER = config.npc.after

local effect = {
    selfTased = false,
    onSelf = nil,
}

local active = {}
local running = {}

local function applyTwitch(ped)
    ApplyForceToEntity(ped, 1,
        (mrandom() * 2.0 - 1.0) * TWITCH_FORCE,
        (mrandom() * 2.0 - 1.0) * TWITCH_FORCE,
        mrandom() * TWITCH_FORCE * 0.5,
        0.0, 0.0, 0.0, mrandom(0, 10), false, true, true, false, true)
end

---@param ped number
---@param shooter number
local function npcAfter(ped, shooter)
    local timeout = GetGameTimer() + NPC_RECOVERY_WAIT

    while DoesEntityExist(ped) and IsPedRagdoll(ped) and timeout > GetGameTimer() do
        Wait(100)
    end

    if not DoesEntityExist(ped) or not NetworkHasControlOfEntity(ped) or IsPedDeadOrDying(ped, true) then return end

    if NPC_AFTER == 'cower' then
        TaskCower(ped, 15000)
        return
    end

    if NPC_AFTER ~= 'flee' then return end

    local player = GetPlayerFromServerId(shooter)
    local shooterPed = player ~= -1 and GetPlayerPed(player) or 0

    if shooterPed ~= 0 then
        TaskSmartFleePed(ped, shooterPed, 100.0, -1, false, false)
    else
        TaskWanderStandard(ped, 10.0, 10)
    end
end

---@param ped number
---@param isSelf boolean
local function setSelf(ped, isSelf)
    if ped ~= cache.ped then return end

    effect.selfTased = isSelf

    if effect.onSelf then
        effect.onSelf(isSelf, active[ped])
    end
end

---@param ped number
local function run(ped)
    local isSelf = ped == cache.ped
    local isNpc = not IsPedAPlayer(ped)
    local isMission = isNpc and IsEntityAMissionEntity(ped)
    local couldRagdoll = CanPedRagdoll(ped)
    local shakeAnim = util.findAnim(SHAKE_ANIMS)
    local locked = false
    local nextRagdoll = 0
    local nextTwitch = 0
    local info

    SetPedCanRagdoll(ped, true)

    if isSelf then
        setSelf(ped, true)

        if config.player.holster and GetSelectedPedWeapon(ped) ~= UNARMED then
            TriggerEvent('ox_inventory:disarm', true)
        end
    else
        if isMission then
            SetBlockingOfNonTemporaryEvents(ped, true)
        end

        ClearPedTasks(ped)
    end

    while true do
        info = active[ped]

        local now = GetGameTimer()

        if not info or now >= info.endsAt then break end
        if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then break end
        if not NetworkHasControlOfEntity(ped) then break end

        if now < info.shakeEnd then
            if shakeAnim and not IsEntityPlayingAnim(ped, shakeAnim.dict, shakeAnim.clip, 3) then
                TaskPlayAnim(ped, shakeAnim.dict, shakeAnim.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
            end
        elseif info.mode == 'lock' then
            if not locked then
                locked = true
                util.stopAnim(ped, shakeAnim)
            end

            if now >= nextRagdoll or not IsPedRagdoll(ped) then
                local duration = mmin(RAGDOLL_TICK + 500, info.endsAt - now)
                SetPedToRagdoll(ped, duration, duration, 0, false, false, false)
                nextRagdoll = now + RAGDOLL_TICK
            end

            if TWITCH_FORCE > 0 and now < info.twitchEnd and now >= nextTwitch then
                applyTwitch(ped)
                nextTwitch = now + mrandom(60, 140)
            end
        end

        if isSelf then
            DisableAllControlActions(0)

            for i = 1, ENABLED_COUNT do
                EnableControlAction(0, ENABLED_CONTROLS[i], true)
            end
        end

        Wait(0)
    end

    local completed = info ~= nil and GetGameTimer() >= info.endsAt

    running[ped] = nil
    active[ped] = nil

    if isSelf then
        setSelf(ped, false)
    end

    if not DoesEntityExist(ped) then return end

    util.stopAnim(ped, shakeAnim)

    if isMission then
        SetBlockingOfNonTemporaryEvents(ped, false)
    end

    if not couldRagdoll then
        SetTimeout(NPC_RECOVERY_WAIT, function()
            if DoesEntityExist(ped) and not IsPedRagdoll(ped) then
                SetPedCanRagdoll(ped, false)
            end
        end)
    end

    if isNpc and locked and completed then
        npcAfter(ped, info.shooter)
    end
end

---@param data table
---@return table
local function buildInfo(data)
    local start = GetGameTimer()

    if data.mode == 'lock' then
        local shakeEnd = start + data.shake

        return {
            mode = 'lock',
            shooter = data.shooter,
            shakeEnd = shakeEnd,
            twitchEnd = shakeEnd + data.twitch,
            endsAt = shakeEnd + data.ground,
            total = data.shake + data.ground,
        }
    end

    local shakeEnd = start + data.flinch

    return {
        mode = 'flinch',
        shooter = data.shooter,
        shakeEnd = shakeEnd,
        twitchEnd = shakeEnd,
        endsAt = shakeEnd,
        total = data.flinch,
    }
end

AddStateBagChangeHandler('smTaser', nil, function(bagName, _, value)
    if type(value) ~= 'table' then return end

    local ped = GetEntityFromStateBagName(bagName)
    if ped == 0 or not NetworkHasControlOfEntity(ped) then return end

    local info = buildInfo(value)
    local elapsed = GetCloudTimeAsInt() - (value.at or 0)

    if elapsed * 1000 > info.total + 2000 then return end

    local current = active[ped]

    if current and current.mode == 'lock' and info.mode == 'flinch' and GetGameTimer() < current.endsAt then
        return
    end

    active[ped] = info

    if running[ped] then
        if ped == cache.ped and effect.onSelf then
            effect.onSelf(true, info)
        end

        return
    end

    running[ped] = true

    CreateThread(function()
        run(ped)
    end)
end)

return effect
