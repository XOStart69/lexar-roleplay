local GetGameTimer = GetGameTimer
local Wait = Wait

local FADE_MS = 650
local Z_START = 950.0
local Z_STEP = 25.0
local STEP_TIMEOUT_MS = 1000

local busy = false

---@param description string
---@param kind 'success'|'error'
local function notify(description, kind)
    lib.notify({ title = 'Teleport', description = description, type = kind })
end

---@param condition fun(): boolean
---@param timeout number
local function waitUntil(condition, timeout)
    local deadline = GetGameTimer() + timeout
    while not condition() and GetGameTimer() < deadline do
        Wait(0)
    end
end

local groundPed = 0

local function sceneLoaded()
    return not IsNetworkLoadingScene()
end

local function collisionLoaded()
    return HasCollisionLoadedAroundEntity(groundPed)
end

---@param ped number
---@param x number
---@param y number
---@return boolean found
---@return number groundZ
local function findGround(ped, x, y)
    groundPed = ped
    for z = Z_START, 0.0, -Z_STEP do
        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        waitUntil(sceneLoaded, STEP_TIMEOUT_MS)
        NewLoadSceneStop()

        SetPedCoordsKeepVehicle(ped, x, y, z)
        RequestCollisionAtCoord(x, y, z)
        waitUntil(collisionLoaded, STEP_TIMEOUT_MS)

        local found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if found then
            return true, groundZ
        end
        Wait(0)
    end

    return false, 0.0
end

local function goToMarker()
    if busy then return end

    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then
        return notify('Tolong set waypoint dulu.', 'error')
    end

    busy = true

    local ped = cache.ped
    local target = GetBlipInfoIdCoord(blip)
    local origin = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    local frozen = vehicle ~= 0 and vehicle or ped

    DoScreenFadeOut(FADE_MS)
    waitUntil(IsScreenFadedOut, FADE_MS + 500)
    FreezeEntityPosition(frozen, true)

    local found, groundZ = findGround(ped, target.x, target.y)

    if found then
        SetPedCoordsKeepVehicle(ped, target.x, target.y, groundZ)
    else
        SetPedCoordsKeepVehicle(ped, origin.x, origin.y, origin.z - 1.0)
    end

    FreezeEntityPosition(frozen, false)
    DoScreenFadeIn(FADE_MS)
    busy = false

    if found then
        notify('Berpindah ke waypoint.', 'success')
    else
        notify('Kesalahan saat melakukan teleport.', 'error')
    end
end

RegisterNetEvent('QBCore:Command:GoToMarker', goToMarker)
