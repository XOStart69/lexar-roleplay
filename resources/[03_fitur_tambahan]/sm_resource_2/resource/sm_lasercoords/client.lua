local infoui = exports.rhd_infoui

local GetGameplayCamRot = GetGameplayCamRot
local GetGameplayCamCoord = GetGameplayCamCoord
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local GetEntityCoords = GetEntityCoords
local DrawLine = DrawLine
local DrawMarker = DrawMarker
local IsControlJustReleased = IsControlJustReleased
local Wait = Wait
local rad, sin, cos, abs = math.rad, math.sin, math.cos, math.abs

local INFO_ID = 'sm_lasercoords:info'
local DISTANCE = 20.0
local KEY_CONFIRM = 38
local KEY_CANCEL = 73
local R, G, B, A = 0, 204, 201, 200

local active = false

---@return boolean hit
---@return vector3 coords
local function raycast()
    local rot = GetGameplayCamRot(2)
    local from = GetGameplayCamCoord()
    local rx, rz = rad(rot.x), rad(rot.z)
    local horizontal = abs(cos(rx))
    local to = from + vector3(-sin(rz) * horizontal, cos(rz) * horizontal, sin(rx)) * DISTANCE

    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, -1, cache.ped, 0)
    local _, hit, coords = GetShapeTestResult(handle)

    return hit, coords
end

local function start()
    if active then return end
    active = true

    infoui:show({
        id = INFO_ID,
        title = 'Laser Coords',
        icon = 'fa-solid fa-crosshairs',
        description = '[kbd]E[/kbd] Salin koordinat\n[kbd]X[/kbd] Batal',
    })

    CreateThread(function()
        while active do
            local hit, coords = raycast()

            if hit then
                local origin = GetEntityCoords(cache.ped)
                DrawLine(origin.x, origin.y, origin.z, coords.x, coords.y, coords.z, R, G, B, A)
                DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, R, G, B, A, false, true, 2, false, nil, nil, false)
            end

            if IsControlJustReleased(0, KEY_CONFIRM) then
                if hit then
                    lib.setClipboard(('vec3(%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z))
                    lib.notify({ description = 'Koordinat disalin ke clipboard', type = 'success' })
                end
                active = false
            elseif IsControlJustReleased(0, KEY_CANCEL) then
                active = false
            end

            Wait(0)
        end

        infoui:remove(INFO_ID)
    end)
end

RegisterNetEvent('sm_lasercoords:client:start', start)
