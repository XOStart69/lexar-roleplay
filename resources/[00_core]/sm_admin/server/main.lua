local utils = require 'modules.lib.utils'
local Logs = require 'modules.lib.logs'

local QBCore = exports['qb-core']:GetCoreObject()

local blipSubs = {}

local function notify(source, description, kind)
    TriggerClientEvent('ox_lib:notify', source, { description = description, type = kind or 'inform' })
end

local function getPlayer(source)
    return QBCore.Functions.GetPlayer(tonumber(source))
end

local function ped(source)
    local p = GetPlayerPed(tonumber(source))

    if not p or p == 0 then return nil end

    return p
end

local function plateOf(source)
    local p = ped(source)

    if not p then return nil end

    local veh = GetVehiclePedIsIn(p, false)

    if not veh or veh == 0 then return nil end

    return (GetVehicleNumberPlateText(veh):gsub('%s+$', ''))
end

lib.callback.register('sm_admin:havePermissions', function(source, opt)
    return utils.clientPermCheck(source, opt)
end)

lib.callback.register('sm_admin:getPlayers', function()
    local list = {}

    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        local Player = getPlayer(src)

        if Player then
            list[#list + 1] = {
                id = src,
                name = GetPlayerName(tostring(src)),
                citizenid = Player.PlayerData.citizenid,
                job = Player.PlayerData.job.label,
                ping = GetPlayerPing(tostring(src)),
            }
        end
    end

    return list
end)

lib.callback.register('sm_admin:getTopMoneyPlayers', function()
    return sql:query_async([[
        SELECT citizenid, name, bank + cash AS total
        FROM players ORDER BY total DESC LIMIT 10
    ]])
end)

lib.callback.register('sm_admin:getPlayerVehicles', function(_, citizenid)
    if type(citizenid) ~= 'string' then return {} end

    return sql:query_async([[
        SELECT plate, vehicle, garage, state FROM player_vehicles WHERE citizenid = ?
    ]], { citizenid })
end)

RegisterNetEvent('sm_admin:blips:subscribe', function(state)
    blipSubs[source] = state == true
end)

-- ADMIN

utils.registerEvent('sm_admin:saveCurrentVehicle', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local Player = getPlayer(source)
    local model = options.model or options.vehicles

    if not Player or not model then return end

    local plate = options.plate

    if not plate or plate == '' then
        plate = utils.getRandomPlate()
    end

    if not plate then return notify(source, 'Gagal membuat plat', 'error') end

    sql:insert_async([[
        INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
        VALUES (?, ?, ?, ?, '{}', ?, ?, 1)
    ]], {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        model,
        GetHashKey(model),
        plate,
        options.garage,
    })

    Logs.Send(source, act.serverLog, { plate = plate, model = model, garage = options.garage })

    notify(source, ('Kendaraan %s disimpan ke garasi %s'):format(plate, tostring(options.garage)), 'success')
end)

utils.registerEvent('sm_admin:giveVehicle', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid)
    local model = options.model or options.vehicles

    if not target or not model then return notify(source, 'Player atau model tidak valid', 'error') end

    local plate = options.plate

    if not plate or plate == '' then
        plate = utils.getRandomPlate()
    end

    if not plate then return notify(source, 'Gagal membuat plat', 'error') end

    sql:insert_async([[
        INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state)
        VALUES (?, ?, ?, ?, '{}', ?, ?, 1)
    ]], {
        target.PlayerData.license,
        target.PlayerData.citizenid,
        model,
        GetHashKey(model),
        plate,
        options.garage,
    })

    Logs.Send(source, act.serverLog, { plate = plate, model = model }, target.PlayerData.source)

    notify(source, ('%s diberikan kendaraan %s'):format(target.PlayerData.charinfo.firstname, plate), 'success')
    notify(target.PlayerData.source, ('Kamu menerima kendaraan %s'):format(plate), 'success')
end)

utils.registerEvent('sm_admin:deltevehFromDB', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.plate then return end

    local exists = utils.plate_exist(options.plate)

    if not exists then return notify(source, 'Plat tidak ada di database', 'error') end

    sql:update_async('DELETE FROM player_vehicles WHERE plate = ?', { options.plate })

    Logs.Send(source, act.serverLog, { plate = options.plate })

    notify(source, ('Kendaraan %s dihapus'):format(options.plate), 'success')
end)

utils.registerEvent('sm_admin:setjob', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.player_id)

    if not target or not options.job then return notify(source, 'Data tidak valid', 'error') end

    target.Functions.SetJob(options.job, tonumber(options.job_grades) or 0)

    notify(source, ('Job %s diubah ke %s'):format(GetPlayerName(tostring(target.PlayerData.source)), options.job), 'success')
    notify(target.PlayerData.source, ('Job kamu diubah ke %s'):format(options.job), 'inform')
end)

utils.registerEvent('sm_admin:transferVehicle', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.plate then return end

    local target = getPlayer(options.playerid)

    if not target then return notify(source, 'Player tidak valid', 'error') end

    if not utils.plate_exist(options.plate) then return notify(source, 'Plat tidak ada', 'error') end

    sql:update_async('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', {
        target.PlayerData.citizenid,
        target.PlayerData.license,
        options.plate,
    })

    Logs.Send(source, act.serverLog, { plate = options.plate }, target.PlayerData.source)

    notify(source, ('Kendaraan %s dipindahkan'):format(options.plate), 'success')
end)

utils.registerEvent('sm_admin:migrasiGarasi', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.old_garage or not options.new_garage then return end

    local changed = sql:update_async('UPDATE player_vehicles SET garage = ? WHERE garage = ?', {
        options.new_garage,
        options.old_garage,
    })

    Logs.Send(source, act.serverLog, { from = options.old_garage, to = options.new_garage })

    notify(source, ('Migrasi garasi selesai (%s kendaraan)'):format(tostring(changed)), 'success')
end)

utils.registerEvent('sm_admin:giveItem', function(tk, actionData, options, args)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.item then return end

    local amount = math.max(math.floor(tonumber(options.amount) or 1), 1)

    if args then
        for _, raw in ipairs(GetPlayers()) do
            inventory:AddItem(tonumber(raw), options.item, amount)
        end

        Logs.Send(source, act.serverLog, { item = options.item, amount = amount })

        return notify(source, ('%s x%d dibagikan ke semua'):format(options.item, amount), 'success')
    end

    local target = getPlayer(options.playerid)

    if not target then return notify(source, 'Player tidak valid', 'error') end

    if not inventory:AddItem(target.PlayerData.source, options.item, amount) then
        return notify(source, 'Inventory target penuh', 'error')
    end

    Logs.Send(source, act.serverLog, { item = options.item, amount = amount }, target.PlayerData.source)

    notify(source, ('%s x%d diberikan'):format(options.item, amount), 'success')
end)

utils.registerEvent('sm_admin:removeitem', function(tk, actionData, options, args)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.item then return end

    local amount = math.max(math.floor(tonumber(options.amount) or 1), 1)

    if args then
        for _, raw in ipairs(GetPlayers()) do
            inventory:RemoveItem(tonumber(raw), options.item, amount)
        end

        Logs.Send(source, act.serverLog, { item = options.item, amount = amount })

        return notify(source, ('%s x%d dihapus dari semua'):format(options.item, amount), 'success')
    end

    local target = getPlayer(options.playerid)

    if not target then return notify(source, 'Player tidak valid', 'error') end

    inventory:RemoveItem(target.PlayerData.source, options.item, amount)

    Logs.Send(source, act.serverLog, { item = options.item, amount = amount }, target.PlayerData.source)

    notify(source, ('%s x%d dihapus'):format(options.item, amount), 'success')
end)

utils.registerEvent('sm_admin:giveMoney', function(tk, actionData, options, args)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local amount = math.max(math.floor(tonumber(options.amount) or 0), 1)
    local kind = options.money_type == 'bank' and 'bank' or 'cash'

    if args then
        for _, raw in ipairs(GetPlayers()) do
            local Player = getPlayer(raw)

            if Player then Player.Functions.AddMoney(kind, amount, 'admin give money all') end
        end

        Logs.Send(source, act.serverLog, { amount = amount, kind = kind })

        return notify(source, ('$%d %s dibagikan ke semua'):format(amount, kind), 'success')
    end

    local target = getPlayer(options.playerid)

    if not target then return notify(source, 'Player tidak valid', 'error') end

    target.Functions.AddMoney(kind, amount, 'admin give money')

    Logs.Send(source, act.serverLog, { amount = amount, kind = kind }, target.PlayerData.source)

    notify(source, ('$%d %s diberikan'):format(amount, kind), 'success')
end)

utils.registerEvent('sm_admin:openStash', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.stash_id then return end

    TriggerClientEvent('sm_admin:openStash', source, options.stash_id)
end)

utils.registerEvent('sm_admin:openTrunk', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.plate then return end

    TriggerClientEvent('sm_admin:openTrunk', source, options.plate)
end)

utils.registerEvent('sm_admin:reviveAll', function(tk, actionData)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    for _, raw in ipairs(GetPlayers()) do
        TriggerClientEvent('hospital:client:Revive', tonumber(raw))
    end

    Logs.Send(source, act.serverLog, { total = #GetPlayers() })

    notify(source, 'Semua player di-revive', 'success')
end)

utils.registerEvent('sm_admin:toggleCuff', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid)

    if not target then return end

    TriggerClientEvent('police:client:ToggleCuff', target.PlayerData.source)
end)

utils.registerEvent('sm_admin:setWeather', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.weather then return end

    TriggerClientEvent('sm_admin:setWeather', -1, options.weather)

    notify(source, 'Cuaca diubah ke ' .. options.weather, 'success')
end)

utils.registerEvent('sm_admin:setTime', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local hours = math.max(math.min(math.floor(tonumber(options.hours) or 12), 23), 0)
    local minutes = math.max(math.min(math.floor(tonumber(options.minutes) or 0), 59), 0)

    TriggerClientEvent('sm_admin:setTime', -1, hours, minutes)

    notify(source, ('Waktu diubah ke %02d:%02d'):format(hours, minutes), 'success')
end)

utils.registerEvent('sm_admin:setPlayerModel', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.model then return end

    local target = getPlayer(options.playerid)

    if not target then return end

    local model = type(options.model) == 'string' and joaat(options.model) or options.model

    local ok = lib.callback.await('sm_admin:setPlayerModel', target.PlayerData.source, model)

    notify(source, ok and 'Model diubah' or 'Model gagal dimuat', ok and 'success' or 'error')
end)

utils.registerEvent('sm_admin:addKeys', function(tk, actionData)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local plate = plateOf(source)

    if not plate then return notify(source, 'Kamu harus di dalam kendaraan', 'error') end

    TriggerClientEvent('sm_vehiclekeys:client:AddKeys', source, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)

    notify(source, ('Kunci %s ditambahkan'):format(plate), 'success')
end)

-- PLAYER

utils.registerEvent('sm_admin:heal', function(tk, actionData)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    TriggerClientEvent('sm_admin:heal', source)
end)

utils.registerEvent('sm_admin:revive', function(tk, actionData)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    TriggerClientEvent('hospital:client:Revive', source)
end)

utils.registerEvent('sm_admin:bring', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)
    local adminPed = ped(source)

    if not target or not adminPed then return end

    local coords = GetEntityCoords(adminPed)
    local targetPed = ped(target.PlayerData.source)

    if not targetPed then return end

    SetEntityCoords(targetPed, coords.x, coords.y, coords.z, false, false, false, false)
end)

utils.registerEvent('sm_admin:goto', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)
    local adminPed = ped(source)

    if not target or not adminPed then return end

    local targetPed = ped(target.PlayerData.source)

    if not targetPed then return end

    local coords = GetEntityCoords(targetPed)

    SetEntityCoords(adminPed, coords.x, coords.y, coords.z, false, false, false, false)
end)

utils.registerEvent('sm_admin:resetac', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)

    if not target then return end

    TriggerClientEvent('sm_antivdm:client:reset', target.PlayerData.source)

    notify(source, 'Anti combat direset', 'success')
end)

utils.registerEvent('sm_admin:toggleantitroll', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)

    if not target then return end

    TriggerClientEvent('sm_antivdm:client:toggle', target.PlayerData.source)

    notify(source, 'Anti troll di-toggle', 'success')
end)

utils.registerEvent('sm_admin:setplayername', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)

    if not target or not options.first_name then return notify(source, 'Nama depan wajib', 'error') end

    local info = target.PlayerData.charinfo

    info.firstname = options.first_name
    info.lastname = options.last_name or info.lastname
    info.birthdate = options.birthdate or info.birthdate
    info.nationality = options.nationality or info.nationality

    sql:update_async('UPDATE players SET charinfo = ? WHERE citizenid = ?', {
        json.encode(info),
        target.PlayerData.citizenid,
    })

    TriggerClientEvent('QBCore:Player:SetPlayerData', target.PlayerData.source, target.PlayerData)

    notify(source, 'Nama diubah', 'success')
end)

utils.registerEvent('sm_admin:setphonenumber', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.new_number then return end

    local target = getPlayer(options.playerid or options.player_id)

    if not target then return end

    target.Functions.SetMetaData('phonenumber', tonumber(options.new_number))

    notify(source, 'Nomor HP diubah', 'success')
end)

utils.registerEvent('sm_admin:jumpScare', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.url then return end

    TriggerClientEvent('sm_jumpscare:client:play', source, options.url, options.sound)
end)

utils.registerEvent('sm_admin:meledak', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)

    TriggerClientEvent('sm_admin:meledak', target and target.PlayerData.source or source)
end)

utils.registerEvent('sm_admin:terbang', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)

    TriggerClientEvent('sm_admin:terbang', target and target.PlayerData.source or source)
end)

utils.registerEvent('sm_admin:copyped', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)

    if not target then return end

    local appearance = lib.callback.await('sm_admin:getAppearance', target.PlayerData.source)

    if not appearance then return notify(source, 'Gagal mengambil appearance', 'error') end

    TriggerClientEvent('sm_admin:applyAppearance', source, appearance)
end)

utils.registerEvent('sm_admin:deletecharacter', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local target = getPlayer(options.playerid or options.player_id)

    if not target then return end

    local cid = target.PlayerData.citizenid

    sql:update_async('DELETE FROM players WHERE citizenid = ?', { cid })
    sql:update_async('DELETE FROM player_vehicles WHERE citizenid = ?', { cid })

    TriggerClientEvent('QBCore:Client:OnPlayerUnload', target.PlayerData.source)
    TriggerClientEvent('sm_character:client:reloadCharacters', target.PlayerData.source)

    notify(source, ('Karakter %s dihapus'):format(cid), 'success')
end)

-- VEHICLE

utils.registerEvent('sm_admin:changeGarage', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local plate = options.plate or plateOf(source)

    if not plate or not options.garage then return notify(source, 'Data tidak lengkap', 'error') end

    sql:update_async('UPDATE player_vehicles SET garage = ?, state = 1 WHERE plate = ?', { options.garage, plate })

    Logs.Send(source, act.serverLog, { plate = plate, garage = options.garage })

    notify(source, ('Garasi %s diubah ke %s'):format(plate, options.garage), 'success')
end)

utils.registerEvent('sm_admin:changePlate', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not options.new_plate then return end

    local plate = plateOf(source)

    if not plate then return notify(source, 'Kamu harus di dalam kendaraan', 'error') end

    if utils.plate_exist(options.new_plate) then return notify(source, 'Plat sudah dipakai', 'error') end

    local p = ped(source)
    local veh = p and GetVehiclePedIsIn(p, false)

    if not veh or veh == 0 then return end

    SetVehicleNumberPlateText(veh, options.new_plate)
    sql:update_async('UPDATE player_vehicles SET plate = ? WHERE plate = ?', { options.new_plate, plate })

    Logs.Send(source, act.serverLog, { from = plate, to = options.new_plate })

    notify(source, 'Plat diubah', 'success')
end)

utils.registerEvent('sm_admin:changeState', function(tk, actionData, options)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act then return end

    local plate = options.plate or plateOf(source)

    if not plate then return notify(source, 'Plat tidak ditemukan', 'error') end

    sql:update_async('UPDATE player_vehicles SET state = ? WHERE plate = ?', {
        math.floor(tonumber(options.new_state) or 1),
        plate,
    })

    notify(source, 'State kendaraan diubah', 'success')
end)

utils.registerEvent('sm_admin:installHarness', function(tk, actionData, data)
    local source = source
    local act = utils.validate(source, tk, actionData)

    if not act or not data then return end

    if inventory:AddItem(source, 'harness', 1) then
        notify(source, 'Harness dipasang', 'success')
    end
end)

lib.print.info('sm_admin server siap')
