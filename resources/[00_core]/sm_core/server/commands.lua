-- Rekonstruksi sm_core/server/commands.lua
-- Daftar command mengikuti locale/en.lua (command.*). Memakai lib.addCommand dari ox_lib.
-- Izin admin lewat ACE group (lihat server.cfg: group.god > group.admin > group.mod).

QBCore.Commands = QBCore.Commands or {}

local ADMIN = 'group.admin'
local notify = function(src, text, kind) QBCore.Functions.Notify(src, text, kind or 'inform') end

---Shim API lama qb-core: QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission)
function QBCore.Commands.Add(name, help, arguments, argsrequired, callback, permission)
    local params = {}
    for i = 1, #(arguments or {}) do
        local arg = arguments[i]
        params[i] = { name = arg.name, help = arg.help, type = 'string', optional = not argsrequired }
    end

    local restricted = false
    if permission and permission ~= 'user' then restricted = 'group.' .. permission end

    lib.addCommand(name, { help = help, params = params, restricted = restricted }, function(source, args, raw)
        local list = {}
        for i = 1, #params do list[#list + 1] = args[params[i].name] end
        callback(source, list, raw)
    end)
end

function QBCore.Commands.Refresh() end -- suggestion sudah ditangani ox_lib

---------------------------------------------------------------- helpers
local function hasPlayerInside(vehicle)
    for seat = -1, 6 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped and ped ~= 0 and IsPedAPlayer(ped) then return true end
    end
    return false
end

local function getPlayer(src, id)
    local player = QBCore.Functions.GetPlayer(id)
    if not player then notify(src, Lang:t('error.not_online'), 'error') end
    return player
end

---------------------------------------------------------------- teleport
lib.addCommand('tp', {
    help = Lang:t('command.tp.help'),
    params = {
        { name = 'x', type = 'string', help = Lang:t('command.tp.params.x.help'), optional = true },
        { name = 'y', type = 'number', help = Lang:t('command.tp.params.y.help'), optional = true },
        { name = 'z', type = 'number', help = Lang:t('command.tp.params.z.help'), optional = true },
    },
    restricted = ADMIN,
}, function(source, args)
    if args.x and not args.y then
        local target = tonumber(args.x)
        if not target or not GetPlayerName(tostring(target)) then
            return notify(source, Lang:t('error.not_online'), 'error')
        end
        local coords = GetEntityCoords(GetPlayerPed(tostring(target)))
        TriggerClientEvent('qb_event_client:tptocoords', source, { coords.x, coords.y, coords.z })
    elseif args.x and args.y and args.z then
        local x = tonumber(args.x)
        if not x then return notify(source, Lang:t('error.wrong_format'), 'error') end
        TriggerClientEvent('qb_event_client:tptocoords', source, { x, args.y, args.z })
    else
        notify(source, Lang:t('error.missing_args'), 'error')
    end
end)

lib.addCommand('tpm', { help = Lang:t('command.tpm.help'), restricted = ADMIN }, function(source)
    TriggerClientEvent('qb_event_client:gotoMarker', source)
end)

---------------------------------------------------------------- server control
lib.addCommand('togglepvp', { help = Lang:t('command.togglepvp.help'), restricted = ADMIN }, function()
    QBConfig.Server.PVP = not QBConfig.Server.PVP
    TriggerClientEvent('QBCore:Client:PvpHasToggled', -1, QBConfig.Server.PVP)
end)

lib.addCommand('addpermission', {
    help = Lang:t('command.addpermission.help'),
    params = {
        { name = 'id', type = 'playerId', help = Lang:t('command.addpermission.params.id.help') },
        { name = 'permission', type = 'string', help = Lang:t('command.addpermission.params.permission.help') },
    },
    restricted = 'group.god',
}, function(_, args)
    QBCore.Functions.AddPermission(args.id, args.permission)
end)

lib.addCommand('removepermission', {
    help = Lang:t('command.removepermission.help'),
    params = {
        { name = 'id', type = 'playerId', help = Lang:t('command.removepermission.params.id.help') },
        { name = 'permission', type = 'string', help = Lang:t('command.removepermission.params.permission.help') },
    },
    restricted = 'group.god',
}, function(_, args)
    QBCore.Functions.RemovePermission(args.id, args.permission)
end)

lib.addCommand('openserver', { help = Lang:t('command.openserver.help'), restricted = ADMIN }, function(source)
    if not QBConfig.Server.Closed then
        return notify(source, Lang:t('error.server_already_open'), 'error')
    end
    QBConfig.Server.Closed = false
    notify(source, Lang:t('success.server_opened'), 'success')
end)

lib.addCommand('closeserver', {
    help = Lang:t('command.closeserver.help'),
    params = { { name = 'reason', type = 'longString', help = Lang:t('command.closeserver.params.reason.help'), optional = true } },
    restricted = ADMIN,
}, function(source, args)
    if QBConfig.Server.Closed then
        return notify(source, Lang:t('error.server_already_closed'), 'error')
    end

    local reason = args.reason or 'Server Closed'
    QBConfig.Server.Closed = true
    QBConfig.Server.ClosedReason = reason

    for _, id in ipairs(GetPlayers()) do
        if not IsPlayerAceAllowed(id, 'qbadmin.join') then
            DropPlayer(id, reason)
        end
    end
    notify(source, Lang:t('success.server_closed'), 'success')
end)

---------------------------------------------------------------- vehicles / entities
lib.addCommand('car', {
    help = Lang:t('command.car.help'),
    params = { { name = 'model', type = 'string', help = Lang:t('command.car.params.model.help') } },
    restricted = ADMIN,
}, function(source, args)
    TriggerClientEvent('qb_event_client:spawnVehicle', source, args.model)
end)

lib.addCommand('dv', { help = Lang:t('command.dv.help'), restricted = ADMIN }, function(source)
    TriggerClientEvent('qb_event_client:deleteVehicle', source)
end)

lib.addCommand('dvall', { help = Lang:t('command.dvall.help'), restricted = ADMIN }, function()
    for _, vehicle in ipairs(GetAllVehicles()) do
        if not hasPlayerInside(vehicle) then DeleteEntity(vehicle) end
    end
end)

lib.addCommand('dvp', { help = Lang:t('command.dvp.help'), restricted = ADMIN }, function()
    for _, ped in ipairs(GetAllPeds()) do
        if not IsPedAPlayer(ped) then DeleteEntity(ped) end
    end
end)

lib.addCommand('dvo', { help = Lang:t('command.dvo.help'), restricted = ADMIN }, function()
    for _, object in ipairs(GetAllObjects()) do DeleteEntity(object) end
end)

---------------------------------------------------------------- money
lib.addCommand('givemoney', {
    help = Lang:t('command.givemoney.help'),
    params = {
        { name = 'id', type = 'playerId', help = Lang:t('command.givemoney.params.id.help') },
        { name = 'moneytype', type = 'string', help = Lang:t('command.givemoney.params.moneytype.help') },
        { name = 'amount', type = 'number', help = Lang:t('command.givemoney.params.amount.help') },
    },
    restricted = ADMIN,
}, function(source, args)
    local player = getPlayer(source, args.id)
    if player then player.Functions.AddMoney(args.moneytype, args.amount, 'command:givemoney') end
end)

lib.addCommand('setmoney', {
    help = Lang:t('command.setmoney.help'),
    params = {
        { name = 'id', type = 'playerId', help = Lang:t('command.setmoney.params.id.help') },
        { name = 'moneytype', type = 'string', help = Lang:t('command.setmoney.params.moneytype.help') },
        { name = 'amount', type = 'number', help = Lang:t('command.setmoney.params.amount.help') },
    },
    restricted = ADMIN,
}, function(source, args)
    local player = getPlayer(source, args.id)
    if player then player.Functions.SetMoney(args.moneytype, args.amount, 'command:setmoney') end
end)

---------------------------------------------------------------- job / gang
lib.addCommand('job', { help = Lang:t('command.job.help') }, function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local job = player.PlayerData.job
    notify(source, Lang:t('info.job_info', { value = job.label, value2 = job.grade.name, value3 = tostring(job.onduty) }))
end)

lib.addCommand('setjob', {
    help = Lang:t('command.setjob.help'),
    params = {
        { name = 'id', type = 'playerId', help = Lang:t('command.setjob.params.id.help') },
        { name = 'job', type = 'string', help = Lang:t('command.setjob.params.job.help') },
        { name = 'grade', type = 'number', help = Lang:t('command.setjob.params.grade.help'), optional = true },
    },
    restricted = ADMIN,
}, function(source, args)
    local player = getPlayer(source, args.id)
    if not player then return end
    if not player.Functions.SetJob(args.job, args.grade or 0) then
        notify(source, Lang:t('error.wrong_format'), 'error')
    end
end)

lib.addCommand('gang', { help = Lang:t('command.gang.help') }, function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    local gang = player.PlayerData.gang
    notify(source, Lang:t('info.gang_info', { value = gang.label, value2 = gang.grade.name }))
end)

lib.addCommand('setgang', {
    help = Lang:t('command.setgang.help'),
    params = {
        { name = 'id', type = 'playerId', help = Lang:t('command.setgang.params.id.help') },
        { name = 'gang', type = 'string', help = Lang:t('command.setgang.params.gang.help') },
        { name = 'grade', type = 'number', help = Lang:t('command.setgang.params.grade.help'), optional = true },
    },
    restricted = ADMIN,
}, function(source, args)
    local player = getPlayer(source, args.id)
    if not player then return end
    if not player.Functions.SetGang(args.gang, args.grade or 0) then
        notify(source, Lang:t('error.wrong_format'), 'error')
    end
end)

---------------------------------------------------------------- chat
lib.addCommand('ooc', {
    help = Lang:t('command.ooc.help'),
    params = { { name = 'message', type = 'longString' } },
}, function(source, args)
    TriggerClientEvent('chat:addMessage', -1, {
        color = QBConfig.Commands.OOCColor,
        multiline = true,
        args = { 'OOC | ' .. GetPlayerName(tostring(source)), args.message },
    })
end)

lib.addCommand('me', {
    help = Lang:t('command.me.help'),
    params = { { name = 'message', type = 'longString', help = Lang:t('command.me.params.message.help') } },
}, function(source, args)
    local origin = GetEntityCoords(GetPlayerPed(tostring(source)))
    local name = GetPlayerName(tostring(source))

    for _, id in ipairs(GetPlayers()) do
        local coords = GetEntityCoords(GetPlayerPed(id))
        if #(coords - origin) <= 15.0 then
            TriggerClientEvent('chat:addMessage', tonumber(id), {
                color = { 200, 160, 255 }, multiline = true, args = { name, args.message },
            })
        end
    end
end)
