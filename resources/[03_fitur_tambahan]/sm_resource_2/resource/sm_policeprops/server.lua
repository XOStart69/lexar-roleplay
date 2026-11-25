--[[
    sm_policeprops :: server
    Prop polisi/media + spike strip. Disinkronkan lewat GlobalState `smprop:<id>`
    (client men-spawn sendiri saat dekat). Akses, batas, cooldown, jarak dicek di sini.
]]

local config = localmodule 'config'

local SPIKE = config.spike
local SPIKE_KIND = 'spikestrip'

---@type table<string, table>
local props = {}
local counter = 0
local lastPlace = {}
local lastBurst = {}

local function setProp(id, data)
    GlobalState['smprop:' .. id] = data
end

local function kindConfig(kind)
    return kind == SPIKE_KIND and SPIKE or config.objects[kind]
end

local function hasAccess(player, groupName)
    local group = config.groups[groupName]
    local job = player.PlayerData.job
    if not group then return false end
    if group.requireDuty and not job.onduty then return false end

    local minGrade = group.jobs[job.name]
    return minGrade ~= nil and (job.grade.level or 0) >= minGrade
end

local function countOf(src, groupName, spikes)
    local total = 0
    for _, prop in pairs(props) do
        if prop.owner == src then
            local isSpike = prop.kind == SPIKE_KIND
            if spikes and isSpike then
                total = total + 1
            elseif not spikes and not isSpike and kindConfig(prop.kind).group == groupName then
                total = total + 1
            end
        end
    end
    return total
end

local function nearPed(src, x, y, z, radius)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and #(GetEntityCoords(ped) - vector3(x, y, z)) <= radius
end

local function itemFor(kind, cfg)
    if kind == SPIKE_KIND then return SPIKE.item end
    return cfg.item and kind or nil
end

local function place(src, kind, coords, heading, pitch, roll)
    local player = qb_ecore:GetPlayer(src)
    local cfg = kindConfig(kind)
    if not player or not cfg then return false, 'access' end
    if type(coords) ~= 'table' then return false, 'access' end

    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z then return false, 'access' end

    if not hasAccess(player, cfg.group) then return false, 'access' end

    local isSpike = kind == SPIKE_KIND
    local group = config.groups[cfg.group]
    local limit = isSpike and SPIKE.maxPerPlayer or group.maxPerPlayer
    if countOf(src, cfg.group, isSpike) >= limit then return false, 'limit' end

    local now = GetGameTimer()
    local cooldown = isSpike and 1000 or group.cooldown
    if lastPlace[src] and now - lastPlace[src] < cooldown then return false, 'cooldown' end

    if not nearPed(src, x, y, z, config.placeRadius + 5.0) then return false, 'access' end

    local item = itemFor(kind, cfg)
    if item and not exports.ox_inventory:RemoveItem(src, item, 1) then return false, 'item' end

    lastPlace[src] = now
    counter = counter + 1

    local id = tostring(counter)
    local data = {
        id = id, kind = kind, x = x, y = y, z = z,
        heading = tonumber(heading) or 0.0,
        pitch = tonumber(pitch) or 0.0,
        roll = tonumber(roll) or 0.0,
        owner = src,
    }

    props[id] = data
    setProp(id, data)

    if isSpike and SPIKE.lifetime then
        SetTimeout(SPIKE.lifetime, function()
            if props[id] then
                props[id] = nil
                setProp(id, nil)
            end
        end)
    end

    return true
end

lib.callback.register('sm_policeprops:getAll', function()
    local list = {}
    for _, prop in pairs(props) do list[#list + 1] = prop end
    return list
end)

lib.callback.register('sm_policeprops:place', function(src, kind, coords, heading, pitch, roll)
    if not config.objects[tostring(kind)] then return false, 'access' end
    return place(src, tostring(kind), coords, heading, pitch, roll)
end)

lib.callback.register('sm_policeprops:placeSpike', function(src, coords, heading)
    return place(src, SPIKE_KIND, coords, heading, 0.0, 0.0)
end)

lib.callback.register('sm_policeprops:pickup', function(src, id)
    local prop = props[tostring(id)]
    local player = qb_ecore:GetPlayer(src)
    if not prop or not player then return false end

    local cfg = kindConfig(prop.kind)
    if not cfg or not hasAccess(player, cfg.group) then return false, 'access' end
    if not nearPed(src, prop.x, prop.y, prop.z, config.pickupRadius + 3.0) then return false end

    local item = itemFor(prop.kind, cfg)
    if item then
        if not exports.ox_inventory:CanCarryItem(src, item, 1) then return false, 'space' end
        exports.ox_inventory:AddItem(src, item, 1)
    end

    props[prop.id] = nil
    setProp(prop.id, nil)

    return true
end)

RegisterTokenEvent('sm_policeprops:server:burst', function(id, netId, tire)
    local src = source
    local prop = props[tostring(id)]
    tire = tonumber(tire)
    if not prop or prop.kind ~= SPIKE_KIND or not tire or tire < 0 or tire > 5 then return end

    local now = GetGameTimer()
    local key = src .. ':' .. prop.id
    if lastBurst[key] and now - lastBurst[key] < SPIKE.burstCooldown then return end
    lastBurst[key] = now

    local vehicle = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if #(GetEntityCoords(vehicle) - vector3(prop.x, prop.y, prop.z)) > SPIKE.zoneRadius then return end

    for _, raw in ipairs(GetPlayers()) do
        local other = tonumber(raw)
        local ped = GetPlayerPed(other)

        if other ~= src and ped ~= 0 and #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) <= config.syncRadius * 2 then
            TriggerClientEvent('sm_policeprops:client:burst', other, netId, tire)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for id in pairs(props) do setProp(id, nil) end
end)

-- item pakai -> client membuka mode pasang
for kind, cfg in pairs(config.objects) do
    if cfg.item then
        qb_ecore:CreateUseableItem(kind, function(src)
            TriggerClientEvent('sm_policeprops:client:place', src, kind)
        end)
    end
end

qb_ecore:CreateUseableItem(SPIKE.item, function(src)
    TriggerClientEvent('sm_policeprops:client:useSpike', src)
end)
