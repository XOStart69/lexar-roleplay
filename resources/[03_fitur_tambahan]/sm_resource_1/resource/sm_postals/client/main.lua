local config = localmodule 'config.shared'
local postals

local function getPostals()
    if not postals then
        postals = localmodule('data.postals')
    end

    return postals
end

RegisterNetEvent('sm_postals:setWaypoint', function(code)
    code = math.tointeger(code)

    if not code then
        lib.notify({ description = 'Kode pos tidak valid', type = 'error' })
        return
    end

    local postal = getPostals()[code]

    if not postal then
        lib.notify({ description = ('Kode pos %d tidak ada'):format(code), type = 'error' })
        return
    end

    SetNewWaypoint(postal.x, postal.y)
    lib.notify({ description = ('Titik ditetapkan ke kode pos %d'):format(code), type = 'success' })
end)

if not config.exportMode then return end

for code, coords in pairs(getPostals()) do
    lib.grid.addEntry({
        coords = coords,
        radius = 300,
        postal = code,
    })
end

local function isPostal(entry)
    return entry.postal ~= nil
end

---@param coords? vector3 | vector2
---@return number
local function getNearestPostal(coords)
    if not coords then
        coords = GetEntityCoords(cache.ped)
    end

    local point = vec2(coords.x, coords.y)
    local entries = lib.grid.getNearbyEntries(point, isPostal)
    local nearest, minDist = 0, math.huge

    for i = 1, #entries do
        local entry = entries[i]
        local dist = #(point - vec2(entry.coords.x, entry.coords.y))

        if dist < minDist then
            minDist = dist
            nearest = entry.postal
        end
    end

    return nearest
end

local exportWrapper = require 'export_wrapper'

exportWrapper('mnr_postals', 'getNearestPostal', getNearestPostal)
exportWrapper('sm_postals', 'getNearestPostal', getNearestPostal)
