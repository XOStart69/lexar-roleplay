local isRagdoll = false

local function toggle()
    if PState.isInAnimation then
        return
    end

    if not IsPedOnFoot(cache.ped) then
        return
    end

    isRagdoll = not isRagdoll

    if isRagdoll then
        while isRagdoll do
            SetPedRagdollForceFall(cache.ped)
            ResetPedRagdollTimer(cache.ped)
            SetPedToRagdoll(cache.ped, 1000, 1000, 3, false, false, false)
            ResetPedRagdollTimer(cache.ped)
            Wait(100)
        end
    end
end

_ENV.ragdoll = {
    toggle = toggle
}