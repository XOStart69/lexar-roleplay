--[[
    sm_zonasantai :: server
    Stress turun berkala selama pemain berada di dalam zona (cek posisi di server).
]]

local config = localmodule 'config'

local last = {}

local function inPolygon(x, y, points)
    local inside = false
    local j = #points

    for i = 1, #points do
        local xi, yi, xj, yj = points[i].x, points[i].y, points[j].x, points[j].y
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end

    return inside
end

local function inAnyZone(coords)
    for i = 1, #config.zones do
        local zone = config.zones[i]
        local baseZ = zone.points[1].z
        local half = (zone.thickness or 20.0) / 2

        if math.abs(coords.z - baseZ) <= half + 5.0 and inPolygon(coords.x, coords.y, zone.points) then
            return true
        end
    end
    return false
end

RegisterTokenEvent('sm_zonasantai:relax', function()
    local src = source
    local now = GetGameTimer()

    if last[src] and now - last[src] < config.interval * 800 then return end

    local player = qb_ecore:GetPlayer(src)
    local ped = GetPlayerPed(src)
    if not player or ped == 0 or not inAnyZone(GetEntityCoords(ped)) then return end

    last[src] = now

    local stress = tonumber(player.PlayerData.metadata.stress) or 0
    local value = math.max(0, stress - (config.stressAmount or 1))

    if value ~= stress then player.Functions.SetMetaData('stress', value) end
end)

AddEventHandler('playerDropped', function()
    last[source] = nil
end)
