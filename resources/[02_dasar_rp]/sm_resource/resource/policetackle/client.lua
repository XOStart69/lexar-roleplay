local config = localmodule 'config.shared'
local isTackling = false
local canTackle = false
local cooldown = false

local allowedJobs = config.allowedJobs
local IsControlPressed = IsControlPressed
local HasEntityCollidedWithAnything = HasEntityCollidedWithAnything

local function hasAllowedJob()
    local job = QBPlayerData.job
    return job and allowedJobs[job.name] or false
end

local function playAnim(dict, name, duration, flag)
    lib.requestAnimDict(dict, 2000)
    TaskPlayAnim(cache.ped, dict, name, 8.0, 8.0, -1, flag, 0, false, false, false)
    Wait(GetAnimDuration(dict, name) * duration)
end

local function doTackle()
    local tackled = false
    local anim = config.anim

    CreateThread(function()
        while isTackling and not tackled do
            if canTackle and HasEntityCollidedWithAnything(cache.ped) then
                local coords = GetEntityCoords(cache.ped)
                local closest = lib.getClosestPlayer(coords, config.tackleRange, false)

                if closest then
                    tackled = true
                    TriggerTokenEvent('policesm:server:TacklePlayer', GetPlayerServerId(closest), coords)
                end
            end

            Wait(0)
        end
    end)

    playAnim(anim.dict, anim.tackle, 200, 2)
    canTackle = true
    Wait(GetAnimDuration(anim.dict, anim.tackle) * 300)
    canTackle = false
    Wait(GetAnimDuration(anim.dict, anim.tackle) * 500)

    playAnim(anim.dict, anim.getup, 500, 1)
    StopAnimTask(cache.ped, anim.dict, anim.getup, 1.0)
    RemoveAnimDict(anim.dict)

    isTackling = false
    cooldown = true

    SetTimeout(config.cooldown, function()
        cooldown = false
    end)
end

RegisterNetEvent('policesm:client:GetTackled', function()
    local ped = cache.ped

    if IsPedRagdoll(ped) then return end
    if IsPedInAnyVehicle(ped, false) then return end

    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, true)

    SetPedToRagdollWithFall(ped, config.ragdollDuration, config.ragdollDuration, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
end)

lib.addKeybind({
    name = 'tackle',
    description = 'Tackle',
    defaultKey = config.key,
    onPressed = function()
        if isTackling or cooldown then return end
        if not IsControlPressed(1, 21) then return end
        if not hasAllowedJob() then return end

        isTackling = true
        doTackle()
    end,
})