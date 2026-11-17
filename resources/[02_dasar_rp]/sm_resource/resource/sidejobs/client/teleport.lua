local teleports = localmodule 'config.teleport'

local GetGameTimer = GetGameTimer
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsScreenFadedOut = IsScreenFadedOut
local IsScreenFadedIn = IsScreenFadedIn
local HasCollisionLoadedAroundEntity = HasCollisionLoadedAroundEntity

local busy = false

---@param ped number
---@param timeout number
local function waitCollision(ped, timeout)
    local deadline = GetGameTimer() + timeout
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        Wait(50)
    end
end

---@param dest vector4
local function teleport(dest)
    if busy then return end
    busy = true

    local ped = cache.ped

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end

    RequestCollisionAtCoord(dest.x, dest.y, dest.z)
    SetEntityCoords(ped, dest.x, dest.y, dest.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, dest.w)
    FreezeEntityPosition(ped, true)
    waitCollision(ped, 3000)
    FreezeEntityPosition(ped, false)

    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(10) end

    busy = false
end

---@param from table
---@param to table
local function addPoint(from, to)
    ox_target:addSphereZone({
        coords = from.coords.xyz,
        radius = from.radius or 1.5,
        options = {
            {
                label = from.label,
                icon = from.icon or 'fas fa-door-open',
                distance = from.distance or 2.0,
                onSelect = function()
                    teleport(to.coords)
                end,
                canInteract = function()
                    return not busy and not IsPedInAnyVehicle(cache.ped, false)
                end
            }
        }
    })
end

for _, pair in pairs(teleports) do
    local a, b = pair[1], pair[2]
    if a and b then
        addPoint(a, b)
        addPoint(b, a)
    end
end
