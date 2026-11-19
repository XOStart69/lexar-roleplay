local QBCore = exports['qb-core']:GetCoreObject()

local sessions = {}
local presets = {}

local function player(source)
    return QBCore.Functions.GetPlayer(source)
end

local function zoneOf(id)
    return modules.zones.get(id)
end

local function fail(reason)
    return { ok = false, reason = reason }
end

local function distance(source, coords)
    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return 999.0 end

    return #(GetEntityCoords(ped) - coords)
end

local function customers(source)
    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)

        if target ~= source then
            local Player = player(target)

            if Player then
                local info = Player.PlayerData.charinfo

                list[#list + 1] = {
                    id = target,
                    name = ('%s %s'):format(info.firstname or '?', info.lastname or ''),
                }
            end
        end
    end

    return list
end

RegisterNetEvent('sm_custom:server:open', function(netId, zoneId, class)
    local source = source
    local zone = zoneOf(zoneId)

    if not zone or type(netId) ~= 'number' then return end
    if distance(source, zone.coords) > zone.radius + 10.0 then return end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return end

    local member = modules.jobs.allowed(source, zone)
    local prices = modules.pricing.zone(zone)

    sessions[source] = {
        zone = zoneId,
        net = netId,
        class = class,
        base = lib.getVehicleProperties(entity),
    }

    TriggerClientEvent('sm_custom:client:opened', source, {
        zone = zoneId,
        menu = zone.menu,
        prices = member and prices or nil,
        billing = zone.billing == true,
        install = zone.install == true,
        member = member,
    })
end)

RegisterNetEvent('sm_custom:server:close', function()
    sessions[source] = nil
end)

RegisterNetEvent('sm_custom:server:spray', function()
    local source = source
    local site = sessions[source]

    if not site then return end

    local entity = NetworkGetEntityFromNetworkId(site.net)

    if not entity or entity == 0 then return end

    SetVehicleFixed(entity)
    SetVehicleDirtLevel(entity, 0.0)
end)

lib.callback.register('sm_custom:server:customers', function(source)
    return customers(source)
end)

lib.callback.register('sm_custom:server:discount', function(_, code)
    return modules.discount.check(code)
end)

RegisterNetEvent('sm_custom:server:presets', function(action, data)
    local source = source
    local Player = player(source)

    if not Player or type(action) ~= 'string' then return end

    local cid = Player.PlayerData.citizenid

    if action == 'save' then
        if type(data) ~= 'table' then return end

        presets[cid] = presets[cid] or {}

        if #presets[cid] >= 10 then table.remove(presets[cid], 1) end

        presets[cid][#presets[cid] + 1] = data

        return
    end

    TriggerClientEvent('sm_custom:client:presets', source, presets[cid] or {})
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)

lib.print.info('sm_custom server siap')
