--[[
    sm_roxnav :: server
    Editor jalan Roxwood: simpan polyline, aktif/nonaktif per segmen, versi global untuk sinkron klien.
]]

local QBCore = exports['qb-core']:GetCoreObject()

local MAX_POINTS = 600
local MAX_PATHS = 400
local MIN_STEP = 1.0
local COMMAND = 'roxnavedit'

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_roxnav_paths` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `points` longtext NOT NULL,
    `disabled` text DEFAULT NULL,
    `author` varchar(64) DEFAULT NULL,
    `created` bigint(20) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local paths = {}
local version = 0
local editors = {}

local function isAdmin(src)
    return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
end

local function bump()
    version = version + 1
    GlobalState.roxnavEdits = version
end

local function pack()
    local list = {}

    for id, path in pairs(paths) do
        list[#list + 1] = { id = id, points = path.points, disabled = path.disabled }
    end

    table.sort(list, function(a, b) return a.id < b.id end)

    return { version = version, list = list }
end

local function decodePoints(raw)
    local ok, data = pcall(json.decode, raw or '[]')
    if not ok or type(data) ~= 'table' then return {} end
    return data
end

local function decodeDisabled(raw)
    local map = {}
    if type(raw) ~= 'string' or raw == '' then return map end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return map end

    for key, value in pairs(data) do
        if value then map[tonumber(key)] = true end
    end

    return map
end

local function encodeDisabled(map)
    local keys = {}

    for index in pairs(map) do
        keys[#keys + 1] = index
    end

    table.sort(keys)

    local out = {}
    for i = 1, #keys do
        out[i] = ('"%d":true'):format(keys[i])
    end

    return '{' .. table.concat(out, ',') .. '}'
end

local function sanitizePoints(points)
    if type(points) ~= 'table' then return end

    local out = {}
    local last

    for i = 1, #points do
        local point = points[i]
        if type(point) == 'table' then
            local x, y, z = tonumber(point.x), tonumber(point.y), tonumber(point.z)
            if x and y and z then
                if not last or ((x - last.x) ^ 2 + (y - last.y) ^ 2) >= MIN_STEP * MIN_STEP then
                    out[#out + 1] = { x = x, y = y, z = z }
                    last = out[#out]
                end
            end
        end

        if #out >= MAX_POINTS then break end
    end

    if #out < 2 then return end
    return out
end

local function pathCount()
    local total = 0
    for _ in pairs(paths) do total = total + 1 end
    return total
end

CreateThread(function()
    MySQL.query.await(SCHEMA)

    local rows = MySQL.query.await('SELECT * FROM sm_roxnav_paths') or {}

    for i = 1, #rows do
        local row = rows[i]
        paths[row.id] = {
            points = decodePoints(row.points),
            disabled = decodeDisabled(row.disabled),
        }
    end

    bump()
    print(('^2[sm_roxnav] %d jalur dimuat^7'):format(#rows))
end)

lib.callback.register('sm_roxnav:edits', function()
    return pack()
end)

lib.callback.register('sm_roxnav:addPath', function(src, points)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return { ok = false, error = 'Data pemain tidak siap' } end
    if not isAdmin(src) and not editors[src] then return { ok = false, error = 'Hanya admin' } end

    local list = sanitizePoints(points)
    if not list then return { ok = false, error = 'Minimal 2 titik valid' } end
    if pathCount() >= MAX_PATHS then return { ok = false, error = 'Jalur penuh' } end

    local id = MySQL.insert.await('INSERT INTO sm_roxnav_paths (points, disabled, author, created) VALUES (?, ?, ?, ?)', {
        json.encode(list), '{}', player.PlayerData.citizenid, os.time()
    })

    if not id then return { ok = false, error = 'Gagal menyimpan' } end

    paths[id] = { points = list, disabled = {} }
    bump()

    return { ok = true, edits = pack() }
end)

lib.callback.register('sm_roxnav:toggleSegment', function(src, data)
    if not isAdmin(src) and not editors[src] then return { ok = false, error = 'Hanya admin' } end
    if type(data) ~= 'table' then return { ok = false, error = 'Data tidak valid' } end

    local id = tonumber(data.path or data.id or data.pathId)
    local index = tonumber(data.segment or data.index or data.idx)
    local path = id and paths[id]

    if not path then return { ok = false, error = 'Jalur tidak ditemukan' } end
    if not index or index < 1 or index >= #path.points then return { ok = false, error = 'Segmen tidak valid' } end

    if type(data.disabled) == 'boolean' then
        path.disabled[index] = data.disabled or nil
    elseif path.disabled[index] then
        path.disabled[index] = nil
    else
        path.disabled[index] = true
    end

    MySQL.update('UPDATE sm_roxnav_paths SET disabled = ? WHERE id = ?', { encodeDisabled(path.disabled), id })
    bump()

    return { ok = true, edits = pack() }
end)

RegisterCommand(COMMAND, function(src)
    if src == 0 then return end
    if not isAdmin(src) then
        return lib.notify(src, { title = 'Editor Jalan', description = 'Hanya admin.', type = 'error' })
    end

    editors[src] = true
    TriggerClientEvent('sm_roxnav:client:editor', src)
end, false)

AddEventHandler('playerDropped', function()
    editors[source] = nil
end)