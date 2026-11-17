local State = require 'gardener.modules.client.state'
local utils = require 'modules.utils'

local Util = {}

local anims = {
    trim = { dict = 'anim@mp_radio@garage@medium', clip = 'idle_a', label = 'Memangkas semak...', duration = 4500, sound = 'trimAnimation.ogg' },
    takeBranch = { dict = 'veh@common@bicycle@ps', clip = 'pickup', label = 'Mengambil dahan...', duration = 900 },
    takeFromVehicle = { dict = 'anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal', clip = 'pickup', label = 'Mengambil perlengkapan...', duration = 3300 },
    putToVehicle = { dict = 'anim@amb@nightclub@mini@drinking@drinking_shots@ped_c@normal', clip = 'pickup', label = 'Mengembalikan perlengkapan...', duration = 2200 },
    ladderUp = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', label = 'Memasang tangga...', duration = 2500 },
}

---@param x number
---@param y number
---@param z number
---@return number groundZ
function Util.findGroundZ(x, y, z)
    local probe = utils.createProp('prop_anim_cash_note', vec3(x, y, z), false)
    if not probe then return z end

    PlaceObjectOnGroundProperly(probe)
    local groundZ = GetEntityCoords(probe).z
    DeleteEntity(probe)
    return groundZ
end

---@param vehicle number
---@param door number
function Util.toggleVehicleDoor(vehicle, door)
    if GetVehicleDoorLockStatus(vehicle) == 2 then return end

    if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
        SetVehicleDoorShut(vehicle, door, false)
    else
        SetVehicleDoorOpen(vehicle, door, false, false)
    end
end

---@param coords vector3
---@param text string
function Util.drawText3D(coords, text)
    SetTextScale(0.30, 0.30)
    SetTextFont(0)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawText(0.0, 0.0)
    DrawRect(0.0, 0.0125, 0.017 + #text / 250, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

---@param label string
---@param duration number
---@return boolean finished
function Util.progressBar(label, duration)
    if State.showBar then return false end

    State.showBar = true
    local finished = lib.progressBar({
        label = label,
        duration = duration,
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, combat = true },
    })
    State.showBar = false
    return finished == true
end

---@param sound string
function Util.playSound(sound)
    State.nuiMessage('playSound', { sound = sound })
end

---@param name 'trim' | 'takeBranch' | 'takeFromVehicle' | 'putToVehicle' | 'ladderUp'
---@return boolean finished
function Util.playAnim(name)
    local anim = anims[name]
    if not anim then return false end

    local playerPed = cache.ped
    utils.waitForAnim(anim.dict)
    ClearPedTasksImmediately(playerPed)
    TaskPlayAnim(playerPed, anim.dict, anim.clip, 8.0, -8.0, -1, 2, 0, false, false, false)
    if anim.sound then Util.playSound(anim.sound) end

    FreezeEntityPosition(playerPed, true)
    Util.progressBar(anim.label, anim.duration)
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)
    return true
end

---@return boolean finished
function Util.playLadderDownAnim()
    local playerPed = cache.ped
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, true)
    TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_HAMMERING', -1, false)
    Util.progressBar('Melipat tangga...', 2500)
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)
    local coords = GetEntityCoords(playerPed)
    ClearAreaOfObjects(coords.x, coords.y, coords.z, 1.0, 0)
    return true
end

local function ensureCarryAnim(dict, clip)
    if IsEntityPlayingAnim(cache.ped, dict, clip, 3) then return end

    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(100)
    end
    TaskPlayAnim(cache.ped, dict, clip, 4.0, 4.0, -1, 51, 0, false, false, false)
end

CreateThread(function()
    while true do
        Wait(1000)
        if State.isPlacingObject then
            ensureCarryAnim('anim@heists@box_carry@', 'idle')
        end
        if State.isPlacingWateringcan then
            ensureCarryAnim('anim@heists@narcotics@trash', 'idle')
        end
        if State.isPlacingLadder then
            ensureCarryAnim('anim@heists@box_carry@', 'walk')
        end
    end
end)

CreateThread(function()
    local sleep = 2000
    while true do
        Wait(sleep)
        if State.getStartJob() then
            sleep = 0
            if GetIsTaskActive(cache.ped, 160) and State.isCarryingAnything() then
                ClearPedTasks(cache.ped)
                ClearPedSecondaryTask(cache.ped)
                State.notify('Kamu tidak bisa masuk kendaraan sambil membawa barang', 'error')
            end
        else
            sleep = 2000
        end
    end
end)

return Util
