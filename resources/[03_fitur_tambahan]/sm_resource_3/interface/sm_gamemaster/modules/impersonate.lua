local state = localmodule 'modules.state'
local control = localmodule 'modules.control'
local selection = localmodule 'modules.selection'
local nui = localmodule 'modules.nui'

local Wait = Wait
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local IsEntityAPed = IsEntityAPed
local IsPedHuman = IsPedHuman
local IsPedAPlayer = IsPedAPlayer
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetEntityModel = GetEntityModel
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehicleModelNumberOfSeats = GetVehicleModelNumberOfSeats
local GetPedDrawableVariation = GetPedDrawableVariation
local GetPedTextureVariation = GetPedTextureVariation
local GetPedPaletteVariation = GetPedPaletteVariation
local GetPedPropIndex = GetPedPropIndex
local GetPedPropTextureIndex = GetPedPropTextureIndex
local SetPedComponentVariation = SetPedComponentVariation
local SetPedPropIndex = SetPedPropIndex
local ClearPedProp = ClearPedProp
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local SetPlayerModel = SetPlayerModel
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityHeading = SetEntityHeading
local SetEntityVisible = SetEntityVisible
local SetEntityCollision = SetEntityCollision
local SetEntityInvincible = SetEntityInvincible
local FreezeEntityPosition = FreezeEntityPosition
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local TaskLeaveVehicle = TaskLeaveVehicle
local TaskWarpPedIntoVehicle = TaskWarpPedIntoVehicle
local DoScreenFadeOut = DoScreenFadeOut
local DoScreenFadeIn = DoScreenFadeIn
local IsScreenFadedOut = IsScreenFadedOut

local impersonate = {}

---@class GmDisguise
---@field target integer
---@field playerModel integer
---@field playerLook { components: integer[][], props: integer[][] }

---@type GmDisguise?
local data = nil

---@param ped integer
---@return { components: integer[][], props: integer[][] }
local function readLook(ped)
    local components = {}
    local props = {}

    for id = 0, 11 do
        components[id + 1] = { GetPedDrawableVariation(ped, id), GetPedTextureVariation(ped, id), GetPedPaletteVariation(ped, id) }
    end

    for id = 0, 8 do
        local index = GetPedPropIndex(ped, id)

        props[id + 1] = { index, index ~= -1 and GetPedPropTextureIndex(ped, id) or 0 }
    end

    return { components = components, props = props }
end

---@param ped integer
---@param look { components: integer[][], props: integer[][] }
local function applyLook(ped, look)
    for id = 0, 11 do
        local c = look.components[id + 1]

        SetPedComponentVariation(ped, id, c[1], c[2], c[3])
    end

    for id = 0, 8 do
        local p = look.props[id + 1]

        if p[1] ~= -1 then
            SetPedPropIndex(ped, id, p[1], p[2], true)
        else
            ClearPedProp(ped, id)
        end
    end
end

---@param hash integer
---@return boolean
local function loadModel(hash)
    RequestModel(hash)

    local tries = 0

    while not HasModelLoaded(hash) do
        tries += 1

        if tries > 250 then return false end

        Wait(20)
    end

    return true
end

local function fadeOut()
    DoScreenFadeOut(250)

    local tries = 0

    while not IsScreenFadedOut() and tries < 30 do
        tries += 1
        Wait(20)
    end
end

---@param ped integer
---@param vehicle integer
---@return integer
local function seatOf(ped, vehicle)
    local last = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2

    for seat = -1, last do
        if GetPedInVehicleSeat(vehicle, seat) == ped then return seat end
    end

    return -1
end

---@param ped integer
local function leaveVehicle(ped)
    local vehicle = selection.vehicleOf(ped)

    if vehicle == 0 then return end

    TaskLeaveVehicle(ped, vehicle, 16)

    local tries = 0

    while IsPedInAnyVehicle(ped, false) and tries < 50 do
        tries += 1
        Wait(20)
    end
end

---@param ped integer
---@param hidden boolean
local function setHidden(ped, hidden)
    SetEntityVisible(ped, not hidden, false)
    SetEntityCollision(ped, not hidden, not hidden)
    FreezeEntityPosition(ped, hidden)
    SetEntityInvincible(ped, hidden)
    SetBlockingOfNonTemporaryEvents(ped, hidden)
end

---@return boolean
function impersonate.active()
    return data ~= nil
end

---@param target integer
---@param leaveGm fun()
---@return boolean
function impersonate.start(target, leaveGm)
    if data then return false end
    if not DoesEntityExist(target) or not IsEntityAPed(target) then return false end
    if IsPedAPlayer(target) or not IsPedHuman(target) then return false end

    if not control.one(target) then
        nui.log('error', 'Gagal mengambil kontrol NPC')
        return false
    end

    local model = GetEntityModel(target)

    if not loadModel(model) then
        nui.log('error', 'Model NPC gagal dimuat')
        return false
    end

    local look = readLook(target)
    local coords = GetEntityCoords(target)
    local heading = GetEntityHeading(target)
    local vehicle = selection.vehicleOf(target)
    local seat = vehicle ~= 0 and seatOf(target, vehicle) or -1
    local playerPed = PlayerPedId()

    data = {
        target = target,
        playerModel = GetEntityModel(playerPed),
        playerLook = readLook(playerPed),
    }

    leaveGm()
    fadeOut()
    leaveVehicle(target)
    setHidden(target, true)

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()

    applyLook(ped, look)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, heading)

    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        control.one(vehicle)
        TaskWarpPedIntoVehicle(ped, vehicle, seat)
    end

    state.impersonating = true
    DoScreenFadeIn(250)

    lib.notify({ title = 'Gamemaster', description = 'Kamu menyamar sebagai NPC. Ketik /gamemaster untuk kembali.', type = 'inform' })

    return true
end

function impersonate.revert()
    local current = data

    if not current then return end

    fadeOut()

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local vehicle = selection.vehicleOf(ped)
    local seat = vehicle ~= 0 and seatOf(ped, vehicle) or -1

    leaveVehicle(ped)

    local target = current.target

    if DoesEntityExist(target) and control.one(target) then
        SetEntityCoordsNoOffset(target, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(target, heading)
        setHidden(target, false)

        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            TaskWarpPedIntoVehicle(target, vehicle, seat)
        end
    end

    if GetResourceState('sm_appearance') == 'started' then
        exports.sm_appearance:loadAppearance()
    elseif loadModel(current.playerModel) then
        SetPlayerModel(PlayerId(), current.playerModel)
        SetModelAsNoLongerNeeded(current.playerModel)
        applyLook(PlayerPedId(), current.playerLook)
    end

    data = nil
    state.impersonating = false
    DoScreenFadeIn(250)
end

function impersonate.abort()
    local current = data

    if not current then return end

    data = nil
    state.impersonating = false

    if DoesEntityExist(current.target) then
        setHidden(current.target, false)
    end

    if HasModelLoaded(current.playerModel) then
        SetPlayerModel(PlayerId(), current.playerModel)
        applyLook(PlayerPedId(), current.playerLook)
    end

    DoScreenFadeIn(0)
end

return impersonate
