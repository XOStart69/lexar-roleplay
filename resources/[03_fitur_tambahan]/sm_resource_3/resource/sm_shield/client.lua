local GetSelectedPedWeapon = GetSelectedPedWeapon
local SetCurrentPedWeapon = SetCurrentPedWeapon
local SetPedCanSwitchWeapon = SetPedCanSwitchWeapon
local IsPedRagdoll = IsPedRagdoll
local IsPedDeadOrDying = IsPedDeadOrDying
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local GetGameTimer = GetGameTimer
local Wait = Wait

local ANIM_DICT = 'beachanims@molly'
local ANIM_NAME = 'beachanim_surf_clip'
local PROP_MODEL = `prop_ballistic_shield`
local PROP_BONE = 18905
local UNARMED = `WEAPON_UNARMED`
local CHECK_INTERVAL = 250

local holding = false
local shieldProp = 0

local function removeShield()
    holding = false

    if shieldProp ~= 0 and DoesEntityExist(shieldProp) then
        DetachEntity(shieldProp, false, true)
        DeleteEntity(shieldProp)
    end

    shieldProp = 0

    local ped = cache.ped
    SetPedCanSwitchWeapon(ped, true)
    StopAnimTask(ped, ANIM_DICT, ANIM_NAME, 1.0)
end

---@param ped number
local function holdLoop(ped)
    local nextCheck = 0

    while holding do
        SetPedCanSwitchWeapon(ped, false)

        if GetSelectedPedWeapon(ped) ~= UNARMED then
            SetCurrentPedWeapon(ped, UNARMED, true)
        end

        local now = GetGameTimer()

        if now >= nextCheck then
            nextCheck = now + CHECK_INTERVAL

            if IsPedRagdoll(ped) or IsPedDeadOrDying(ped, true) then
                removeShield()
                break
            end

            if not IsEntityPlayingAnim(ped, ANIM_DICT, ANIM_NAME, 3) then
                TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 3.0, 3.0, -1, 49, 0, false, false, false)
            end
        end

        Wait(0)
    end
end

local function equipShield()
    if not lib.requestAnimDict(ANIM_DICT, 5000) then return end
    if not lib.requestModel(PROP_MODEL, 5000) then return end

    local ped = cache.ped
    holding = true

    SetCurrentPedWeapon(ped, UNARMED, true)
    TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 3.0, 3.0, -1, 49, 0, false, false, false)

    shieldProp = CreateObject(PROP_MODEL, GetEntityCoords(ped), true, true, false)
    AttachEntityToEntity(shieldProp, ped, GetPedBoneIndex(ped, PROP_BONE), 0.01, -0.1, -0.07, 1.83, 105.38, -10.14, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(PROP_MODEL)

    CreateThread(function()
        holdLoop(ped)
    end)
end

RegisterNetEvent('sm_shield:client:toggle', function()
    if holding then
        return removeShield()
    end

    if cache.vehicle then
        return lib.notify({ title = 'Shield', description = 'Tidak bisa memakai shield di dalam kendaraan.', type = 'error' })
    end

    equipShield()
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle and holding then
        removeShield()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not holding then return end

    removeShield()
end)
