local tbl = lib.table
local array = lib.array

local actions = require 'config.action'
local utils = require 'modules.lib.utils'


local adminAct = tbl.map(tbl.deepclone(actions.admin), function (val)
    if val.onExecute then
        val.onExecute = nil
    end

    if val.canExecute then
        val.canExecute = nil
    end

    return val
end)

local playerAct = tbl.map(tbl.deepclone(actions.player), function (val)
    if val.onExecute then
        val.onExecute = nil
    end

    if val.canExecute then
        val.canExecute = nil
    end

    return val
end)


local vehicleAct = tbl.map(tbl.deepclone(actions.vehicle), function (val)
    if val.onExecute then
        val.onExecute = nil
    end

    if val.canExecute then
        val.canExecute = nil
    end

    return val
end)

---@param name string
---@param cb fun(data: any, cb: fun(...))
local function callback(name, cb)
    return RegisterRawNuiCallback(name, function(req, nuiCallback)
        local origin = req.headers and req.headers['Origin']
        local validOrigins = {
            ['https://cfx-nui-'..cache.resource] = true,
            ['https://'..cache.resource] = true
        }

        if origin and type(origin) == 'string' and origin ~= '' and not validOrigins[origin] then
            return nuiCallback({ status = 403, body = '{}' })
        end

        cb(json.decode(req.body), function(data)
            nuiCallback({ status = 200, body = json.encode(data) })
        end)
    end)
end

---@param resource string resources name
---@param export string export name
---@return fun(name: string, method: function)
local function useExport(resource, export, ...)
	return exports[resource][export](...)
end

local local_act = require 'modules.action'

--- NUI CALLBACK
callback('setFavorite', function (data, cb)
    local currentFavorite = utils.getKvP('actions') or {}

    if currentFavorite and array.isArray(currentFavorite) then
        local index = array.findIndex(currentFavorite, function (val)
            if val == data.action then
                return true
            end
        end)

        if index then
            table.remove(currentFavorite, index)
        else
            currentFavorite[#currentFavorite+1] = data.action
        end
    else
        currentFavorite[#currentFavorite+1] = data.action
    end

    utils.saveKvP('actions', currentFavorite)
    cb(true)
end)

callback('getActions', function (data, cb)
    cb({ actions = adminAct, favorites = {} })
end)

callback('getPlayers', function (data, cb)
    local players = lib.cblt.await('sm_admin:getPlayers', 1500)

    cb(players)
end)

callback('getTopMoneyPlayers', function (data, cb)
    local topmoney = lib.callback.await('sm_admin:getTopMoneyPlayers', 1500)

    cb(topmoney)
end)

callback('getPlayerActions', function (data, cb)
    cb({ player = playerAct, vehicle = vehicleAct })
end)

callback('getPlayerVehicles', function (data, cb)
    local playerVehicles = lib.callback.await('sm_admin:getPlayerVehicles', 1500, data.citizenid)

    cb(playerVehicles)
end)

callback('executeAction', function (data, cb)
    local actionId = data.id
    local actionType = data.type
    local options = data.options

    local AD = { action = actionId,  type = actionType }
    local action = utils.validate(AD)

    if not action then
        goto skip
    end

    if action.closeOnExecute then
        SendNUIMessage({
            action = 'closeMenu',
            data = {}
        })
    end

    if action.canExecute and not action.canExecute(options, action.args) then
        goto skip
    end

    if action.serverEvent then
        TriggerServerEvent(action.serverEvent, options, action.args)
    elseif action.localServerEvent then
        TriggerServerEvent(action.localServerEvent, Token(), AD, options, action.args)
    elseif action.event then
        TriggerEvent(action.event, options, action.args)
    elseif action.command then
        ExecuteCommand(action.command)
    elseif action.export then
        useExport(string.strsplit('.', action.export), options.args)
    elseif action.onExecute then
        action.onExecute(options, action.args)
    elseif action.localFunction then
        local_act[action.localFunction](AD, options, action.args)
    end

    ::skip::

    cb('ok')
end)

callback('exit', function (data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)