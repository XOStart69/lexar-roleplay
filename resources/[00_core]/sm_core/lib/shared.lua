local qbExport = require 'export-functions'

local qbFn = setmetatable({}, {
    __newindex = function (self, key, fn)
        rawset(self, key, fn)

        if type(fn) == "function" then
            exports(key, fn)
            qbExport(key, fn)
        end
    end
})

local isServer = lib.context == 'server'

---@param pool string
---@param ignoreList? integer[]
---@return integer[]
local function getEntities(pool, ignoreList) -- luacheck: ignore
    ignoreList = ignoreList or {}
    local ents = GetGamePool(pool)
    local entities = {}
    local ignoreMap = {}
    for i = 1, #ignoreList do
        ignoreMap[ignoreList[i]] = true
    end

    for i = 1, #ents do
        local entity = ents[i]
        if not ignoreMap[entity] then
            entities[#entities + 1] = entity
        end
    end
    return entities
end

---@param entities integer[]
---@param coords vector3? if unset uses player coords
---@return integer closestObj or -1
---@return number closestDistance or -1
local function getClosestEntity(entities, coords) -- luacheck: ignore
    coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
    local closestDistance = -1
    local closestEntity = -1
    for i = 1, #entities do
        local entity = entities[i]
        local entityCoords = GetEntityCoords(entity)
        local distance = #(entityCoords - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestEntity = entity
            closestDistance = distance
        end
    end
    return closestEntity, closestDistance
end

---@param entity number
---@return vector4
function qbFn.GetCoords(entity)
    local coords = GetEntityCoords(entity, false)
    local heading = GetEntityHeading(entity)
    return vector4(coords.x, coords.y, coords.z, heading)
end

if isServer then
    ---@param source any
    ---@param idtype? string
    ---@return string|Identifier
    function qbFn.GetIdentifier(source, idtype)
        if GetConvarInt('sv_fxdkMode', 0) == 1 then return 'license:fxdk' end
        return PlayerIdentifier(source, idtype) --[[@as string]]
    end

    ---@param identifier string
    ---@return number
    function qbFn.GetSource(identifier)
        return qbLib.table.find(QBCore.Players, function (val, key)
            return val.PlayerData.license == identifier and tonumber(key)
        end) or 0
    end

    ---@param source Source
    ---@return string?
    function qbFn.GetCitizenId(source)
        return QBCore.Player.GetPlayerData(source, 'citizenid')
    end

    function qbFn.CreateAccountNumber()
        return 'US0' .. math.random(1, 9) .. 'SMCore' .. math.random(1111, 9999) .. math.random(1111, 9999) .. math.random(11, 99)
    end

    function qbFn.CreatePhoneNumber()
        return math.random(100, 999) .. math.random(1000000, 9999999)
    end

    ---@param source Source
    ---@return string?
    function qbFn.GetLicense(source)
        return QBCore.Player.GetPlayerData(source, 'license')
    end

    ---@param source any
    ---@return table?
    function qbFn.GetPlayer(source)
        local src

        if tonumber(source) ~= nil then
            src = tonumber(source)
        else
            src = qbFn.GetSource(source)
        end

        local player = QBCore.Players[src]
        if not player then return end

        return PreparePlayerTable(player)
    end

    ---@param citizenid string
    ---@return table?
    function qbFn.GetPlayerByCitizenId(citizenid)
        local player = qbLib.table.find(QBCore.Players, function (val, key)
            return val.PlayerData.citizenid == citizenid
        end)

        if not player then
            return
        end

        return PreparePlayerTable(player)
    end

    ---@param number number
    ---@return table?
    function qbFn.GetPlayerByPhone(number)
        local player = qbLib.table.find(QBCore.Players, function (val, key)
            return val.PlayerData.charinfo.phone == number
        end)

        if not player then
            return
        end

        return PreparePlayerTable(player)
    end

    ---@param account string
    ---@return table?
    function qbFn.GetPlayerByAccount(account)
        local player = qbLib.table.find(QBCore.Players, function (val, key)
            return val.PlayerData.charinfo.account == account
        end)

        if not player then
            return
        end

        return PreparePlayerTable(player)
    end

    ---@param property string
    ---@param value string
    ---@return table?
    function qbFn.GetPlayerByCharInfo(property, value)
        local player = qbLib.table.find(QBCore.Players, function (val, key)
            local charinfo = val.PlayerData.charinfo
            return charinfo[property] ~= nil and charinfo[property] == value
        end)

        if not player then
            return
        end

        return PreparePlayerTable(player)
    end

    ---@return table
    function qbFn.GetPlayers()
        local sources = {}
        for k in pairs(QBCore.Players) do
            sources[#sources + 1] = k
        end
        return sources
    end

    ---@return table
    function qbFn.GetQBPlayers()
        return QBCore.Players
    end

    ---@return table, table
    function qbFn.GetBucketObjects()
        return QBCore.Player_Buckets, QBCore.Entity_Buckets
    end

    ---@param source any
    ---@param bucket number
    ---@return boolean
    function qbFn.SetPlayerBucket(source, bucket)
        if not (source or bucket) then return false end

        Player(source).state:set('instance', bucket, true)
        SetPlayerRoutingBucket(source --[[@as string]], bucket)
        QBCore.Player_Buckets[source] = bucket
        return true
    end

    ---@param entity number
    ---@param bucket number
    ---@return boolean
    function qbFn.SetEntityBucket(entity, bucket)
        if not (entity or bucket) then return false end

        SetEntityRoutingBucket(entity, bucket)
        QBCore.Entity_Buckets[entity] = bucket
        return true
    end

    ---@param bucket number
    ---@return table|boolean
    function qbFn.GetPlayersInBucket(bucket)
        local curr_bucket_pool = {}
        if not (QBCore.Player_Buckets or next(QBCore.Player_Buckets)) then
            return false
        end

        for k, v in pairs(QBCore.Player_Buckets) do
            if v == bucket then
                curr_bucket_pool[#curr_bucket_pool + 1] = k
            end
        end

        return curr_bucket_pool
    end

    ---@param bucket number
    ---@return table|boolean
    function qbFn.GetEntitiesInBucket(bucket)
        local curr_bucket_pool = {}
        if not (QBCore.Entity_Buckets or next(QBCore.Entity_Buckets)) then
            return false
        end

        for k, v in pairs(QBCore.Entity_Buckets) do
            if v == bucket then
                curr_bucket_pool[#curr_bucket_pool + 1] = k
            end
        end

        return curr_bucket_pool
    end

    ---@deprecated use qbx.spawnVehicle from modules/lib.lua
    ---@return number?
    function qbFn.SpawnVehicle(source, model, coords, warp)
        local ped = GetPlayerPed(source)

        local _, veh = qbLib.spawnVehicle({
            model = model --[[@as integer]],
            coords = coords,
            warp = warp and ped,
            spawnSource = source --[[@as Source]]
        })

        return veh
    end

    ---@param source any
    ---@param model any
    ---@param coords vector4
    ---@param warp boolean
    ---@return number
    function qbFn.CreateAutomobile(source, model, coords, warp)
        model = type(model) == 'string' and joaat(model) or model

        ---@diagnostic disable-next-line: cast-local-type
        if not coords then coords = GetEntityCoords(GetPlayerPed(source)) end
        local heading = coords.w and coords.w or 0.0
        local CreateAutomobileNative = `CREATE_AUTOMOBILE`

        ---@diagnostic disable-next-line: param-type-mismatch
        local veh = Citizen.InvokeNative(CreateAutomobileNative, model, coords.x, coords.y, coords.z, heading, true, true)
        while not DoesEntityExist(veh) do Wait(0) end
        if warp then TaskWarpPedIntoVehicle(GetPlayerPed(source), veh, -1) end
        return veh
    end

    ---@deprecated use qbLib.spawnVehicle from modules/lib.lua
    function qbFn.CreateVehicle(source, model, _, coords, warp)
        model = type(model) == 'string' and joaat(model) or (model --[[@as integer]])
        local ped = GetPlayerPed(source)

        local netId = qbLib.spawnVehicle({
            model = model,
            spawnSource = coords or ped,
            warp = warp and ped or nil,
        })

        return NetworkGetEntityFromNetworkId(netId)
    end

    local serverCb = require 'lib.callback.server'
    qbFn.TriggerClientCallback = serverCb.TriggerClientCallback
    qbFn.CreateCallback = serverCb.CreateCallback

    ---@param item string
    ---@param data function
    function qbFn.CreateUseableItem(item, data)
        QBCore.UsableItems[item] = data
    end

    ---@param item string
    ---@return any
    function qbFn.CanUseItem(item)
        return QBCore.UsableItems[item]
    end

    ---@param source any
    ---@param item string
    function qbFn.UseItem(source, item)
        if GetResourceState('qb-inventory') == 'missing' then return end
        exports['qb-inventory']:UseItem(source, item)
    end

    ---@deprecated use setKickReason or deferrals for connecting players, and the DropPlayer native directly otherwise
    qbFn.Kick = function(source, reason, setKickReason, deferrals)
        reason = ('\n %s \n ðŸ”¸ Check our Discord for further information: %s'):format(reason, QBConfig.Server.Discord)
        if setKickReason then
            setKickReason(reason)
        end
        CreateThread(function()
            if deferrals then
                deferrals.update(reason)
                Wait(2500)
            end
            if source then
                DropPlayer(source --[[@as string]], reason)
            end
            for _ = 0, 4 do
                while true do
                    if source then
                        if GetPlayerPing(source --[[@as string]]) >= 0 then
                            break
                        end
                        Wait(100)
                        CreateThread(function()
                            DropPlayer(source --[[@as string]], reason)
                        end)
                    end
                end
                Wait(5000)
            end
        end)
    end

    ---@param source any
    ---@return boolean
    function qbFn.IsWhitelisted(source)
        if not QBConfig.Server.Whitelist then return true end
        if IsPlayerAceAllowed(source --[[@as string]], QBConfig.Server.WhitelistPermission) then return true end
        return false
    end

    ---@deprecated use cfg ACEs instead
    ---@param source Source
    ---@param permission string
    function qbFn.AddPermission(source, permission)
        if not IsPlayerAceAllowed(source --[[@as string]], permission) then
            lib.addPrincipal('player.' .. source, 'group.' .. permission)
            lib.addAce('player.' .. source, 'group.' .. permission)
            TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
            TriggerEvent('QBCore:Server:OnPermissionUpdate', source)
        end
    end

    ---@deprecated use cfg ACEs instead
    ---@param source Source
    ---@param permission string
    function qbFn.RemovePermission(source, permission)
        if permission then
            if IsPlayerAceAllowed(source --[[@as string]], permission) then
                lib.removePrincipal('player.' .. source, 'group.' .. permission)
                lib.removeAce('player.' .. source, 'group.' .. permission)
                TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
                TriggerEvent('QBCore:Server:OnPermissionUpdate', source)
            end
        else
            local hasUpdated = false

            ---@diagnostic disable-next-line: deprecated
            for _, v in pairs(QBConfig.Server.Permissions) do
                if IsPlayerAceAllowed(source --[[@as string]], v) then
                    lib.removePrincipal('player.' .. source, 'group.' .. v)
                    lib.removeAce('player.' .. source, 'group.' .. v)
                    hasUpdated = true
                end
            end
            if hasUpdated then
                TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
                TriggerEvent('QBCore:Server:OnPermissionUpdate', source)
            end
        end
    end

    -- Checking for Permission Level
    ---@deprecated use IsPlayerAceAllowed
    ---@param source Source
    ---@param permission string|string[]
    ---@return boolean
    function qbFn.HasPermission(source, permission)
        if type(permission) == 'string' then
            if IsPlayerAceAllowed(source --[[@as string]], permission) then return true end
        elseif type(permission) == 'table' then
            for _, permLevel in pairs(permission) do
                if IsPlayerAceAllowed(source --[[@as string]], permLevel) then return true end
            end
        end

        return false
    end

    ---@deprecated use cfg ACEs instead
    ---@param source Source
    ---@return table<string, boolean>
    function GetPermission(source)
        local perms = {}

        ---@diagnostic disable-next-line: deprecated
        for _, v in pairs (QBConfig.Server.Permissions) do
            if IsPlayerAceAllowed(source --[[@as string]], v) then
                perms[v] = true
            end
        end
        return perms
    end

    ---@param license string
    ---@return boolean
    function qbFn.IsLicenseInUse(license)
        local players = GetPlayers()

        for _, player in pairs(players) do
            local playerLicense = PlayerIdentifier(player, QBConfig.LicenseType)
            if playerLicense == license then return true end
        end

        return false
    end

    qbFn.Notify = require 'lib.interface.server'.Notify

else
    local clientCb = require 'lib.callback.client'
    qbFn.CreateClientCallback = clientCb.CreateClientCallback
    qbFn.TriggerCallback = clientCb.TriggerCallback

    ---@param cb? function
    ---@return table?
    function qbFn.GetPlayerData(cb)
        if not cb then return QBCore.PlayerData end
        cb(QBCore.PlayerData)
    end

    ---@param items string|table
    ---@param amount? number
    ---@return boolean
    function qbFn.HasItem(items, amount)
        return exports['qb-inventory']:HasItem(items, amount)
    end

    ---@deprecated use lib.requestAnimDict from ox_lib, and the TaskPlayAnim and RemoveAnimDict natives directly
    qbFn.PlayAnim = function(animDict, animName, upperbodyOnly, duration)
        local flags = upperbodyOnly and 16 or 0
        local runTime = duration or -1
        lib.playAnim(cache.ped, animDict, animName, 8.0, 3.0, runTime, flags, 0.0, false, false, true)
    end

    ---@deprecated use qbLib.isWearingGloves from modules/lib.lua
    qbFn.IsWearingGloves = qbLib.isWearingGloves

    qbFn.Notify = require 'lib.interface.client'.Notify
    qbFn.Progressbar = require 'lib.interface.client'.Progressbar

    ---@return table
    function qbFn.GetVehicles()
        return GetGamePool('CVehicle')
    end

    ---@return table
    function qbFn.GetObjects()
        return GetGamePool('CObject')
    end

    ---@return table
    function qbFn.GetPlayers()
        return GetActivePlayers()
    end

    ---@deprecated use lib.getNearbyPlayers from ox_lib
    qbFn.GetPlayersFromCoords = function(coords, radius)
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
        local players = lib.getNearbyPlayers(coords, radius or 5, true)

        -- This is for backwards compatability as beforehand it only returned the PlayerId, where Lib returns PlayerPed, PlayerId and PlayerCoords
        for i = 1, #players do
            players[i] = players[i].id
        end

        return players
    end

    ---@deprecated use lib.getClosestPlayer from ox_lib
    qbFn.GetClosestPlayer = function(coords) -- luacheck: ignore
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
        local playerId, _, playerCoords = lib.getClosestPlayer(coords, 5, false)
        local closestDistance = playerCoords and #(playerCoords - coords) or nil
        return playerId or -1, closestDistance or -1
    end

    ---@deprecated use the GetGamePool('CPed') native directly
    qbFn.GetPeds = function(ignoreList)
        return getEntities('CPed', ignoreList)
    end

    ---@deprecated use lib.getClosestPed from ox_lib
    ---Use GetClosestPlayer if wanting to ignore non-player peds
    qbFn.GetClosestPed = function(coords, ignoreList)
        return getClosestEntity(getEntities('CPed', ignoreList), coords)
    end

    ---@deprecated use lib.getClosestVehicle from ox_lib
    qbFn.GetClosestVehicle = function(coords)
        return getClosestEntity(GetGamePool('CVehicle'), coords)
    end

    ---@deprecated use lib.getClosestObject from ox_lib
    qbFn.GetClosestObject = function(coords)
        return getClosestEntity(GetGamePool('CObject'), coords)
    end

    ---@deprecated use lib.requestModel from ox_lib
    qbFn.LoadModel = lib.requestModel

    qbFn.SpawnVehicle = require 'lib.vehicle.client'.SpawnVehicle

    qbFn.DeleteVehicle = qbLib.deleteVehicle

    ---@param vehicle number
    ---@return string?
    function qbFn.GetPlate(vehicle)
        if not (vehicle and DoesEntityExist(vehicle)) then return end
        return qbLib.string.trim(GetVehicleNumberPlateText(vehicle))
    end

    qbFn.GetVehicleLabel = qbLib.getVehicleDisplayName

    qbFn.GetVehicleProperties = require 'lib.vehicle.client'.GetVehicleProperties
    qbFn.SetVehicleProperties = require 'lib.vehicle.client'.SetVehicleProperties

    ---@deprecated use lib.requestAnimSet from ox_lib
    qbFn.LoadAnimSet = lib.requestAnimSet

    ---@deprecated use lib.requestAnimDict from ox_lib
    qbFn.RequestAnimDict = lib.requestAnimDict

    ---@deprecated use the GetWorldPositionOfEntityBone native and calculate distance directly
    qbFn.GetClosestBone = function(entity, list)
        local playerCoords = GetEntityCoords(cache.ped)

        ---@type integer | {id: integer} | {id: integer, type: string, name: string}, vector3, number
        local bone, coords, distance
        for _, element in pairs(list) do
            local boneCoords = GetWorldPositionOfEntityBone(entity, element.id or element)
            local boneDistance = #(playerCoords - boneCoords)
            if not coords or distance > boneDistance then
                bone = element
                coords = boneCoords
                distance = boneDistance
            end
        end
        if not bone then
            bone = {id = GetEntityBoneIndexByName(entity, 'bodyshell'), type = 'remains', name = 'bodyshell'}
            coords = GetWorldPositionOfEntityBone(entity, bone.id)
            distance = #(coords - playerCoords)
        end
        return bone, coords, distance
    end

    ---@deprecated use the GetWorldPositionOfEntityBone native and calculate distance directly
    qbFn.GetBoneDistance = function(entity, boneType, bone)
        local boneIndex = boneType == 1 and GetPedBoneIndex(entity, bone --[[@as integer]]) or GetEntityBoneIndexByName(entity, bone --[[@as string]])
        local boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
        local playerCoords = GetEntityCoords(cache.ped)
        return #(playerCoords - boneCoords)
    end

    ---@deprecated use the AttachEntityToEntity native directly
    qbFn.AttachProp = function(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
        local modelHash = type(model) == 'string' and joaat(model) or model
        local bone = GetPedBoneIndex(ped, boneId)
        lib.requestModel(modelHash)
        local prop = CreateObject(modelHash, 1.0, 1.0, 1.0, true, true, false)
        AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, true, true, false, true, not vertex and 2 or 0, true)
        SetModelAsNoLongerNeeded(modelHash)
        return prop
    end

    ---@deprecated use lib.getNearbyVehicles from ox_lib
    qbFn.SpawnClear = function(coords, radius)
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
        radius = radius or 5
        local vehicles = GetGamePool('CVehicle')
        local closeVeh = {}
        for i = 1, #vehicles do
            local vehicleCoords = GetEntityCoords(vehicles[i])
            local distance = #(vehicleCoords - coords)
            if distance <= radius then
                closeVeh[#closeVeh + 1] = vehicles[i]
            end
        end
        return #closeVeh == 0
    end

    ---@deprecated use lib.requestNamedPtfxAsset from ox_lib
    qbFn.LoadParticleDictionary = lib.requestNamedPtfxAsset

    qbFn.StartParticleAtCoord = require 'lib.particle.client'.StartParticleAtCoord
    qbFn.StartParticleOnEntity = require 'lib.particle.client'.StartParticleOnEntity

    ---@param coords vector3
    ---@return table
    function qbFn.GetStreetNametAtCoords(coords)
        local streetname1, streetname2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        return { main = GetStreetNameFromHashKey(streetname1), cross = GetStreetNameFromHashKey(streetname2) }
    end

    qbFn.GetZoneAtCoords = qbLib.getZoneName

    qbFn.GetCardinalDirection = qbLib.getCardinalDirection

    ---@deprecated use the GetClockMinutes and GetClockHours natives and format the output directly
    qbFn.GetCurrentTime = function()
        local obj = {}
        obj.min = GetClockMinutes()
        obj.hour = GetClockHours()

        if obj.hour <= 12 then
            obj.ampm = 'AM'
        elseif obj.hour >= 13 then
            obj.ampm = 'PM'
            obj.formattedHour = obj.hour - 12
        end

        if obj.min <= 9 then
            obj.formattedMin = ('0%s'):format(obj.min)
        end

        return obj
    end

    ---@deprecated use the GetGroundZFor_3dCoord native directly
    qbFn.GetGroundZCoord = function(coords)
        if not coords then return end

        local retval, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
        if retval then
            return vec3(coords.x, coords.y, groundZ)
        end

        lib.print.verbose('Couldn\'t find Ground Z Coordinates given 3D Coordinates:', coords)
        return coords
    end

    ---@param entity number
    ---@return number, number, vector3, vector3, boolean, number
    function qbFn.GetGroundHash(entity)
        local coords = GetEntityCoords(entity)
        local num = StartShapeTestCapsule(coords.x, coords.y, coords.z + 4, coords.x, coords.y, coords.z - 2.0, 1, 1, entity, 7)
        local retval, success, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultEx(num)
        return materialHash, entityHit, surfaceNormal, endCoords, success, retval
    end
end

QBCore.Functions = qbFn