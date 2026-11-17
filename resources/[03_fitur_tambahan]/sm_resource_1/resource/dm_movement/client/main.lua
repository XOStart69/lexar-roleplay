local config = localmodule 'config.shared'
local State = localmodule 'modules.state'
local Anim = localmodule 'modules.anim'
local Lean = localmodule 'modules.lean'
local Ballistics = localmodule 'modules.ballistics'
local Traversal = localmodule 'modules.traversal'

State.Lean = Lean
Lean.State = State
Traversal.Lean = Lean

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local sleep = 100

        State.ped = ped

        if State.traversing then
            sleep = 0
            Traversal.BlockControls()
            Traversal.Tick(ped)
        elseif not State.Available(ped) then
            Traversal.Unfreeze(ped)
            sleep = 500
        else
            Traversal.Unfreeze(ped)
            State.UpdateGround(ped)

            if IsPedJumping(ped) or IsPedFalling(ped) or IsEntityInAir(ped) then
                sleep = config.traversal.airInterval
                Traversal.Tick(ped)
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    local lastTime = GetGameTimer()

    while true do
        local ped = PlayerPedId()
        local currentTime = GetGameTimer()
        local sleep = 200
        local available = State.Available(ped)

        if config.lean.enabled then
            local canLean = available and State.CanLean(ped, true)

            if (canLean and Lean.Pressed()) or Lean.Active() or Lean.CameraActive() then
                sleep = 0
                DisableControlAction(0, 44, true)
                Lean.Update(ped, (currentTime - lastTime) / 1000.0, canLean)
            end
        elseif Lean.Active() or Lean.CameraActive() then
            Lean.Reset(ped)
        end

        if config.ballistics.enabled and available and IsPedArmed(ped, 4) and State.Aiming()
            and (Lean.Active() or not config.ballistics.onlyWhileLeaning) then
            if Ballistics.Enforce(ped) then
                sleep = 0
                Ballistics.Indicator()
            elseif sleep > config.ballistics.interval then
                sleep = config.ballistics.interval
            end
        elseif Ballistics.blocked then
            Ballistics.Clear()
        end

        lastTime = currentTime
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local ped = PlayerPedId()

    Traversal.Cancel()
    Lean.Reset(ped)
    Anim.Cleanup()

    if not DoesEntityExist(ped) then
        return
    end

    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
end)

exports('IsTraversing', function()
    return State.traversing
end)

exports('GetLean', function()
    return Lean.Amount()
end)

exports('IsBarrelBlocked', function()
    return Ballistics.blocked
end)

exports('SetEnabled', function(enabled)
    State.enabled = enabled and true or false

    if State.enabled then
        return
    end

    Traversal.Cancel()
    Lean.Reset(PlayerPedId())
end)
