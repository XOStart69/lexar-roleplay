local utils = {}

---@class PlayerIdentifier
---@field steam? string
---@field discord? string
---@field license? string
---@field license2? string
---@field ip? string

---@param key string
---@param value table
function utils.saveKvP(key, value)
    local id = ('%s:%s'):format(cache.resource, key)
    SetResourceKvp(id, json.encode(value))
end

---@param key string
function utils.getKvP(key)
    local id = ('%s:%s'):format(cache.resource, key)
    local value = GetResourceKvpString(id) or ""
    return json.decode(value)
end

---@param model string|integer
function utils.getVehicleNameByModel(model)
    local modelData = qb_core:GetVehiclesByName(model)
    local hashData = modelData or qb_core:GetVehiclesByHash(model)

    if not hashData then
        return 'Unknown Vehicles'
    end

    return ('%s %s'):format(hashData.brand, hashData.name)
end

if lib.context == 'server' then
    
    ---@param source number
    ---@param checkType 'ace' | 'identifier'
    ---@param groups? string|string[]
    ---@return boolean
    local function havePermissions(source, checkType, groups)
        if not groups then return false end
        if type(groups) == 'string' then groups = {groups} end

        if checkType == 'ace' then
            for i = 1, #groups do
                local group = groups[i]

                if IsPlayerAceAllowed(source --[[@as string]], group) then
                    return true
                end
            end
        elseif checkType == 'identifier' then
            local identifier = exports.sm_core:GetIdentifier(source) --[[@as PlayerIdentifier]]
            if not identifier then return false end

            for i = 1, #groups do
                local group = groups[i]
                local identType = group:match('^(%w+):(.+)$')

                if identifier[identType] == group then
                    return true
                end
            end
        end

        return false
    end

    local EXTRA_EVENT_ACTIONS = {
        ['sm_admin:installHarness'] = { 'admin.maxperformance' },
    }

    ---@type table<string, table<string, boolean>>?
    local eventActions

    ---@return table<string, table<string, boolean>>
    local function getEventActions()
        if eventActions then return eventActions end

        eventActions = {}

        for actionType, list in pairs(require 'config.action') do
            if type(list) == 'table' then
                for key, act in pairs(list) do
                    local event = type(act) == 'table' and act.localServerEvent
                    if event then
                        eventActions[event] = eventActions[event] or {}
                        eventActions[event][('%s.%s'):format(actionType, key)] = true
                    end
                end
            end
        end

        for event, keys in pairs(EXTRA_EVENT_ACTIONS) do
            eventActions[event] = eventActions[event] or {}
            for i = 1, #keys do
                eventActions[event][keys[i]] = true
            end
        end

        return eventActions
    end

    ---@param action any
    ---@return ActionData?
    local function resolveAction(action)
        if type(action) ~= 'table' or type(action.type) ~= 'string' or type(action.action) ~= 'string' then
            return nil
        end

        local list = require 'config.action'[action.type]
        return type(list) == 'table' and list[action.action] or nil
    end

    ---@param name string
    ---@param cb fun(tk: string, actionData: ActionProps, options: any, args: any)
    function utils.registerEvent(name, cb)
        return RegisterNetEvent(name, function(tk, actionData, options)
            local src = source
            local allowed = getEventActions()[name]
            local key = type(actionData) == 'table' and ('%s.%s'):format(tostring(actionData.type), tostring(actionData.action))

            if not allowed or not key or not allowed[key] then
                lib.print.warn(('[sm_admin] %s (%s) memanggil %s dengan action %s yang tidak cocok'):format(GetPlayerName(src), src, name, tostring(key)))
                return
            end

            local act = resolveAction(actionData)
            cb(tk, actionData, options, act and act.args)
        end)
    end

    ---@param source number
    ---@param opt ActionPerms
    function utils.havePerms(source, opt)
        if opt.perms then
            return havePermissions(source, 'ace', opt.perms)
        end

        return havePermissions(source, 'identifier', opt.onlyFor)
    end

    ---@param source number
    ---@param opt any
    ---@return boolean
    function utils.clientPermCheck(source, opt)
        if type(opt) ~= 'table' then return false end

        if opt.type then
            local act = resolveAction(opt)
            if not act then return false end
            return utils.havePerms(source, { perms = act.perms, onlyFor = act.onlyFor })
        end

        if type(opt.perms) == 'string' then
            return havePermissions(source, 'ace', opt.perms)
        end

        return false
    end

    function utils.validate(source, tk, action)
        if not exports.se_v2:validate(source, tk) then
            return
        end

        local act = resolveAction(action) --[[@as ActionData]]

        if not act then
            return
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        if not utils.havePerms(source, {perms = act.perms, onlyFor = act.onlyFor}) then
            lib.notify(source, { description = 'Kamu tidak ada akses!', type = 'error' })
            return
        end

        return act
    end

    ---@param plate string
    ---@return boolean Exist
    function utils.plate_exist(plate)
        local result = sql:scalar_async([[
            SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1
        ]], { plate })
        return result ~= nil
    end

    --- @param prefix string?
    --- @return string|nil VehiclePlate
    function utils.getRandomPlate(prefix)
        local platePrefix = prefix or lib.string.random('....')

        for _ = 1, 30 do
            local plate = platePrefix .. lib.string.random('....')
            if not utils.plate_exist(plate) then
                return plate
            end
        end

        return nil
    end

    ---@param plate string
    function utils.findVehicleByPlate(plate)
        local vehicles = GetAllVehicles()

        for i=1, #vehicles do
            local vehicle = vehicles[i]
            local vehPlate = GetVehicleNumberPlateText(vehicle)
            local trimPlate = qbLib.string.trim(vehPlate)

            if trimPlate == qbLib.string.trim(plate) then
                return vehicle
            end
        end

        return false
    end
elseif lib.context == 'client' then
    ---@param perms ActionPerms
    function utils.havePerms(perms)
        local havePermissions = lib.callback.await('sm_admin:havePermissions', false, perms)

        if not havePermissions then
            lib.notify({
                description = 'Kamu tidak memiliki permissions untuk melakukan ini.',
                type = 'error'
            })
            return
        end

        return true
    end

    function utils.validate(action)

        local act = require 'config.action'[action.type]?[action.action] --[[@as ActionData]]

        if not act then
            return
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        if not utils.havePerms({ type = action.type, action = action.action }) then
            lib.notify({ description = 'Kamu tidak ada akses!', type = 'error' })
            return
        end

        return act
    end
end

return utils