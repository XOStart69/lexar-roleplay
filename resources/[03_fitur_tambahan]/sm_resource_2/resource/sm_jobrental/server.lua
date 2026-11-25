--[[
    sm_jobrental :: server
    Sewa kendaraan job: rent (validasi + pilih spawn) -> client spawn -> register(netId).
    Point `cid = true` (yacht donatur) memakai whitelist citizenid di bawah.
]]

local config = localmodule 'config'

-- SESUAIKAN: citizenid yang boleh menyewa untuk point bertanda cid = true
local CID_WHITELIST = {
    -- yacht_moscow = { 'ABC12345' },
    -- yacht_mikhayla = { 'DEF67890' },
    -- yacht_donatur = { 'GHI13579' },
}

local MAX_ACTIVE = 5
local SPOT_RADIUS = config.spotRadius or 3.0
local COOLDOWN = config.cooldown or 3000

---@type table<number, table[]>   src -> { { netId, key, model, label } }
local rentals = {}
local pending = {}
local last = {}

local function pointJobAllowed(point, player)
    if point.cid then
        local list = CID_WHITELIST[point.key] or {}
        for i = 1, #list do
            if list[i] == player.PlayerData.citizenid then return true end
        end
        return false
    end

    local job = player.PlayerData.job
    local grade = point.jobs and point.jobs[job.name]
    return grade ~= nil and (job.grade.level or 0) >= grade
end

local function findVehicle(point, model)
    for _, group in ipairs({ point.peds or {} }) do
        for i = 1, #group do
            for _, vehicle in ipairs(group[i].vehicles or {}) do
                if vehicle.model == model then return vehicle, group[i] end
            end
        end
    end
    -- point.zone memakai point.vehicles
    for _, vehicle in ipairs(point.vehicles or {}) do
        if vehicle.model == model then return vehicle end
    end
end

local function spotFree(coords)
    for _, vehicle in ipairs(GetAllVehicles()) do
        if #(GetEntityCoords(vehicle) - vector3(coords.x, coords.y, coords.z)) <= SPOT_RADIUS then
            return false
        end
    end
    return true
end

local function pickSpawn(point, model)
    for i = 1, #(point.spawns or {}) do
        local spawn = point.spawns[i]
        local ok = not spawn.models

        if spawn.models then
            for m = 1, #spawn.models do
                if spawn.models[m] == model then ok = true break end
            end
        end

        if ok and spotFree(spawn.coords) then return spawn.coords end
    end
end

local function makePlate(prefix)
    prefix = (prefix or 'RENT'):sub(1, 4)
    for _ = 1, 20 do
        local plate = prefix .. tostring(math.random(1000, 9999))
        if not MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate }) then
            return plate
        end
    end
    return prefix .. tostring(math.random(1000, 9999))
end

local function alive(entry)
    local entity = NetworkGetEntityFromNetworkId(entry.netId)
    return entity ~= 0 and DoesEntityExist(entity), entity
end

local function prune(src)
    local list = rentals[src] or {}
    local keep = {}
    for i = 1, #list do
        if alive(list[i]) then keep[#keep + 1] = list[i] end
    end
    rentals[src] = keep
    return keep
end

lib.callback.register('sm_jobrental:rent', function(src, key, model)
    key, model = tostring(key), tostring(model)
    local point = config.points[key]
    local player = qb_ecore:GetPlayer(src)
    if not point or not player then return false end
    point.key = key

    local now = GetGameTimer()
    if last[src] and now - last[src] < COOLDOWN then return false, 'Tunggu sebentar.' end
    last[src] = now

    if not pointJobAllowed(point, player) then return false, 'Kamu tidak punya izin.' end

    local vehicle = findVehicle(point, model)
    if not vehicle then return false, 'Kendaraan tidak tersedia.' end

    -- syarat item per job
    local rule = vehicle.jobs and vehicle.jobs[player.PlayerData.job.name]
    if rule and rule.items then
        local has = false
        for i = 1, #rule.items do
            if (exports.ox_inventory:GetItemCount(src, rule.items[i]) or 0) > 0 then has = true break end
        end
        if not has then return false, 'Item syarat tidak ada.' end
    end

    if #prune(src) >= MAX_ACTIVE then return false, 'Batas sewa tercapai.' end

    local spawn = pickSpawn(point, model)
    if not spawn then return false, 'Area spawn sedang terhalang.' end

    local plate = makePlate(point.platePrefix)
    pending[src] = { key = key, model = model, label = vehicle.label, plate = plate, at = now }

    return true, { x = spawn.x, y = spawn.y, z = spawn.z, w = spawn.w, plate = plate }
end)

lib.callback.register('sm_jobrental:register', function(src, netId)
    local request = pending[src]
    pending[src] = nil
    netId = tonumber(netId)

    if not request or not netId or GetGameTimer() - request.at > 30000 then return false end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) then return false end
    if GetEntityModel(entity) ~= joaat(request.model) then return false end

    local list = rentals[src] or {}
    list[#list + 1] = { netId = netId, key = request.key, model = request.model, label = request.label }
    rentals[src] = list

    local player = qb_ecore:GetPlayer(src)
    if player then
        TriggerEvent('sm_vehiclekeys:server:setVehicleOwner', request.plate, player.PlayerData.citizenid)
    end

    return true
end)

lib.callback.register('sm_jobrental:list', function(src, key)
    local out = {}
    for _, entry in ipairs(prune(src)) do
        if entry.key == tostring(key) then
            out[#out + 1] = { netId = entry.netId, label = entry.label }
        end
    end
    return out
end)

lib.callback.register('sm_jobrental:return', function(src, netId)
    netId = tonumber(netId)
    local list = prune(src)

    for i = 1, #list do
        if list[i].netId == netId then
            local _, entity = alive(list[i])
            if entity and entity ~= 0 then DeleteEntity(entity) end
            table.remove(list, i)
            return true
        end
    end

    return false
end)

AddEventHandler('playerDropped', function()
    local src = source
    rentals[src], pending[src], last[src] = nil, nil, nil
end)
