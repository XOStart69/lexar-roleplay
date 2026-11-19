---@class BoothServer
local booth = {}

local active = {}
local bySource = {}

local function fail(reason)
    return { ok = false, reason = reason }
end

local function zoneOf(id)
    return modules.zones.get(id)
end

local function boothOf(id)
    return modules.zones.booth(id)
end

local function holder(source)
    local id = bySource[source]

    return id and active[id] or nil
end

local function distTo(source, coords)
    local ped = GetPlayerPed(source)

    if not ped or ped == 0 then return 999.0 end

    return #(GetEntityCoords(ped) - coords)
end

local function entityOf(site)
    local veh = NetworkGetEntityFromNetworkId(site.net)

    if not veh or veh == 0 or not DoesEntityExist(veh) then return nil end

    return veh
end

local function selectionOf(site)
    return site.selection
end

---@param source number
---@param id string
---@param colors table
---@param net number
---@param class number
---@return table
function booth.register(source, id, colors, net, class)
    local entry = boothOf(id)

    if not entry then return fail('invalid') end
    if bySource[source] then return fail('busy') end
    if active[id] then return fail('taken') end

    local zone = zoneOf(id)

    if zone and not modules.jobs.allowed(source, zone) then return fail('denied') end
    if distTo(source, entry.vehicle.xyz) > entry.radius + 8.0 then return fail('far') end

    local veh = NetworkGetEntityFromNetworkId(net)

    if not veh or veh == 0 or not DoesEntityExist(veh) then return fail('vehicle') end

    active[id] = {
        source = source,
        net = net,
        class = class,
        base = colors,
        selection = {
            color1 = colors.color1,
            paintType1 = colors.paintType1,
            color2 = colors.color2,
            paintType2 = colors.paintType2,
            pearlescentColor = colors.pearlescentColor,
        },
    }

    bySource[source] = id

    return { ok = true }
end

---@param source number
---@param id string
---@return table
function booth.release(source, id)
    local site = active[id]

    if not site or site.source ~= source then return fail('invalid') end

    active[id] = nil
    bySource[source] = nil

    return { ok = true }
end

---@param source number
---@param id string
---@return table
function booth.open(source, id)
    local site = active[id]

    if not site then return fail('vehicle') end
    if site.source ~= source then return fail('occupied') end

    local entry = boothOf(id)

    if not entry then return fail('invalid') end
    if not entityOf(site) then return fail('vehicle') end
    if distTo(source, entry.vehicle.xyz) > entry.radius + 8.0 then return fail('far') end

    local zone = zoneOf(id)
    local prices = zone and modules.pricing.zone(zone) or nil

    return {
        ok = true,
        view = { selection = selectionOf(site), changed = false },
        process = prices ~= nil,
        billing = entry.billing == true,
        prices = prices,
    }
end

---@param source number
---@param id string
---@param selection table
---@param cursor? number
function booth.select(source, id, selection, cursor)
    local site = active[id]

    if not site or site.source ~= source or type(selection) ~= 'table' then return end

    site.selection = selection
    site.cursor = cursor
end

---@param source number
---@param id string
---@return table
function booth.customers(source, id)
    local site = active[id]

    if not site or site.source ~= source then return {} end

    local entry = boothOf(id)

    if not entry then return {} end

    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local target = tonumber(raw)

        if target ~= source and distTo(target, entry.vehicle.xyz) <= 12.0 then
            local Player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(target)

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

---@param source number
---@param id string
---@param method string
---@param customer? number
---@param selection table
---@return table
function booth.process(source, id, method, customer, selection)
    local site = active[id]

    if not site or site.source ~= source or type(selection) ~= 'table' then return fail('invalid') end

    local veh = entityOf(site)

    if not veh then return fail('vehicle') end

    local zone = zoneOf(id)
    local prices = zone and modules.pricing.zone(zone)

    if not prices then return fail('denied') end

    local total = modules.cart.total(prices, site.base, selection)

    if total > 0 then
        if method == 'customer' and customer then
            local ok = modules.billing.request(tonumber(customer), { label = zone.label }, total, function() end)

            if not ok then return fail('billing') end
        else
            local Player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(source)

            if not Player then return fail('invalid') end

            local account = method == 'cash' and 'cash' or 'bank'

            if not Player.Functions.RemoveMoney(account, total, 'custom booth') then
                return fail('billing')
            end
        end
    end

    SetVehicleColours(veh, selection.color1 or 0, selection.color2 or 0)
    SetVehicleModColor_1(veh, selection.paintType1 or 0, 0, 0)
    SetVehicleModColor_2(veh, selection.paintType2 or 0, 0)
    SetVehicleExtraColours(veh, selection.pearlescentColor or 0, 0)

    site.base = {
        color1 = selection.color1,
        paintType1 = selection.paintType1,
        color2 = selection.color2,
        paintType2 = selection.paintType2,
        pearlescentColor = selection.pearlescentColor,
    }

    local plate = (GetVehicleNumberPlateText(veh) or ''):gsub('^%s*(.-)%s*$', '%1')

    if selection.engineSound ~= nil then
        modules.swap.set(plate, selection.engineSound == false and nil or selection.engineSound)
    end

    modules.fitment.set(modules.wheels.key(veh), plate, modules.fitment.probe(veh))

    if selection.nitrousFlame ~= nil or selection.nitrousPurge ~= nil then
        modules.nitrous.ensure(plate, 100)
    end

    modules.logs.print(('booth %s oleh %s ($%d)'):format(id, source, total))

    return { ok = true, total = total }
end

---@param src number
---@return CustomZone?
function booth.of(src)
    local id = bySource[src]
    if not id then return end

    return zoneOf(id) or boothOf(id)
end

lib.callback.register('sm_custom:server:boothOpen', function(source, id)
    return booth.open(source, id)
end)

lib.callback.register('sm_custom:server:boothRelease', function(source, id)
    return booth.release(source, id)
end)

lib.callback.register('sm_custom:server:boothRegister', function(source, id, colors, net, class)
    return booth.register(source, id, colors, net, class)
end)

lib.callback.register('sm_custom:server:boothCustomers', function(source, id)
    return booth.customers(source, id)
end)

lib.callback.register('sm_custom:server:boothProcess', function(source, id, method, customer, selection)
    return booth.process(source, id, method, customer, selection)
end)

RegisterNetEvent('sm_custom:server:boothSelect', function(id, selection, cursor)
    booth.select(source, id, selection, cursor)
end)

RegisterNetEvent('sm_custom:server:boothClose', function(id)
    local source = source
    local site = active[id]

    if not site or site.source ~= source then return end

    bySource[source] = nil
end)

AddEventHandler('playerDropped', function()
    local source = source
    local id = bySource[source]

    if not id then return end

    active[id] = nil
    bySource[source] = nil
end)

return booth
