local infoui = exports.rhd_infoui

local DoesEntityExist = DoesEntityExist
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local GetGameTimer = GetGameTimer
local Wait = Wait

local TRUCK_MODEL = `flattemu`
local INFO_ID = 'sm_tow:select'
local MAX_TOW_DISTANCE = 10.0
local SELECT_TIMEOUT_MS = 30000
local CONTROL_TIMEOUT_MS = 2000
local ATTACH_OFFSET = vector3(0.0, -2.35, 0.20)
local DROP_DISTANCE = 8.0

local truck = 0
local towed = 0
local selectingUntil = 0

---@param entity number
---@return boolean
local function requestControl(entity)
    if NetworkHasControlOfEntity(entity) then return true end

    local deadline = GetGameTimer() + CONTROL_TIMEOUT_MS
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) do
        if GetGameTimer() > deadline or not DoesEntityExist(entity) then
            return false
        end
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end

    return true
end

local function stopSelecting()
    selectingUntil = 0
    infoui:remove(INFO_ID)
end

---@param entity number
local function selectTruck(entity)
    truck = entity
    selectingUntil = GetGameTimer() + SELECT_TIMEOUT_MS
    infoui:show({
        id = INFO_ID,
        title = 'Derek',
        icon = 'fa-solid fa-truck-pickup',
        description = 'Arahkan target ke kendaraan yang mau diderek',
    })
    SetTimeout(SELECT_TIMEOUT_MS, function()
        if selectingUntil ~= 0 and GetGameTimer() >= selectingUntil then
            stopSelecting()
        end
    end)
end

---@param vehicle number
local function towVehicle(vehicle)
    stopSelecting()

    if not DoesEntityExist(truck) or #(GetEntityCoords(truck) - GetEntityCoords(vehicle)) > MAX_TOW_DISTANCE then
        return lib.notify({ description = 'Kendaraan terlalu jauh dari truk derek', type = 'error' })
    end

    if not requestControl(vehicle) then
        return lib.notify({ description = 'Kendaraan sedang dipakai, coba lagi', type = 'error' })
    end

    AttachEntityToEntity(vehicle, truck, GetEntityBoneIndexByName(truck, 'bodyshell'),
        ATTACH_OFFSET.x, ATTACH_OFFSET.y, ATTACH_OFFSET.z, 0.0, 0.0, 0.0,
        true, true, false, true, 0, true
    )
    towed = vehicle
end

local function dropVehicle()
    local vehicle = towed
    towed = 0

    if not DoesEntityExist(vehicle) then return end
    if not requestControl(vehicle) then
        towed = vehicle
        return lib.notify({ description = 'Gagal menurunkan kendaraan, coba lagi', type = 'error' })
    end

    local coords = GetEntityCoords(truck)
    local heading = GetEntityHeading(truck)
    local headingRad = math.rad(heading)

    DetachEntity(vehicle, true, true)
    SetEntityCoords(vehicle,
        coords.x - math.sin(headingRad) * DROP_DISTANCE,
        coords.y - math.cos(headingRad) * DROP_DISTANCE,
        coords.z, false, false, false, true
    )
    SetEntityHeading(vehicle, heading)
    SetVehicleOnGroundProperly(vehicle)
end

ox_target:addModel(TRUCK_MODEL, {
    {
        name = 'sm_tow:select',
        label = 'Derek kendaraan',
        icon = 'fa-solid fa-truck-pickup',
        distance = 2.5,
        canInteract = function()
            return towed == 0
        end,
        onSelect = function(data)
            selectTruck(data.entity)
        end,
    },
    {
        name = 'sm_tow:drop',
        label = 'Turunkan kendaraan',
        icon = 'fa-solid fa-arrow-down',
        distance = 2.5,
        canInteract = function(entity)
            return towed ~= 0 and entity == truck
        end,
        onSelect = dropVehicle,
    },
})

ox_target:addGlobalVehicle({
    {
        name = 'sm_tow:attach',
        label = 'Derek kendaraan ini',
        icon = 'fa-solid fa-truck-pickup',
        distance = 2.5,
        canInteract = function(entity)
            return selectingUntil ~= 0 and towed == 0 and entity ~= truck
        end,
        onSelect = function(data)
            towVehicle(data.entity)
        end,
    },
})
