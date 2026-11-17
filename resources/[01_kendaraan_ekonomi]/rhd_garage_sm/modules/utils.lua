_ENV.utils = {}
local isServer = lib.context == 'server'
local garage_config =  require 'config.garage'

local depot_price = garage_config.depot_price
local garage_class = garage_config.category_class

---@param gclass GarageVehicleClass | GarageVehicleClass[]
---@return number[] VehicleClass
function utils.convertClass(gclass)
    local class = {}
    local typec = type(gclass)

    if typec == 'string' and garage_class[gclass] then
        class = lib.array.merge(class, garage_class[gclass])
    elseif typec == 'table' and gclass[1] then
        for i=1, #gclass do
            local gc = gclass[i]
            if garage_class[gc] then
                class = lib.array.merge(class, garage_class[gc])
            end
        end
    end
    return class
end

---@param key string
---@return table|nil
function utils.kvpGet(key)
    local raw = GetResourceKvpString(key)
    if not raw or raw == '' then return nil end
    local ok, val = pcall(json.decode, raw)
    return ok and val or nil
end

---@param key  string
---@param data table
function utils.kvpSet(key, data)
    local ok, encoded = pcall(json.encode, data)
    if ok then SetResourceKvp(key, encoded) end
end

if not isServer then
    local tempVehicle = {}

    ---@param val number
    ---@return number? Value
    local function prefixValue(val)
        if type(val) ~= 'number' then return end
        return math.min(100, math.max(0, math.floor(val)))
    end

    ---@param vehicle integer
    ---@return table VehiclePerformance
    local function getPerformanceStats(vehicle)
        local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
        local fInitialDriveForce = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce")
        local fBrakeForce = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeForce")
        local fTractionCurveMax = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax")
        local fTractionCurveMin = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin")
        local fSteeringLock = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fSteeringLock")
        local fSuspensionUpperLimit = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionUpperLimit")
        local fSuspensionLowerLimit = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionLowerLimit")

        local maxSpeedKMH = (fInitialDriveMaxFlatVel * 0.75) * 3.6
        local suspensionTravel = fSuspensionUpperLimit - fSuspensionLowerLimit

        local stats = {
            speed = prefixValue((maxSpeedKMH / 530.0) * 100),
            acceleration = prefixValue((fInitialDriveForce / 1.3) * 100),
            braking = prefixValue((fBrakeForce / 2.0) * 100),
            handling = prefixValue(((fSteeringLock / 42.0) * 0.7 + ((fTractionCurveMax + fTractionCurveMin) / 5.5) * 0.3) * 100),
            offroad = prefixValue((suspensionTravel / 0.35) * 100),
            drift = prefixValue((1.0 - (fTractionCurveMin / math.max(fTractionCurveMax, 0.001))) * 100),
        }

        return stats
    end

    ---@param data {plate: string, model: string|integer}
    ---@return table? VehicleStats
    function utils.getVehicleStats(data)
        local model = data.model
        local plate = data.plate

        local coords = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)
        
        if not pcall(lib.requestModel, model) then
            return nil
        end

        local tempIndex = #tempVehicle + 1
        local vehEntity = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
        FreezeEntityPosition(vehEntity, true)
        SetEntityAlpha(vehEntity, 25, false)
        SetEntityCollision(vehEntity, false, false)
        SetVehicleNumberPlateText(vehEntity, plate)

        tempVehicle[tempIndex] = vehEntity
        local performance = getPerformanceStats(vehEntity)
        local server_data = lib.cblt.await(
            'rhd_garage:server:fetchServerVehicleDetails', false, plate
        )

        if not performance then
            return
        end

        performance.fuel = server_data.fuel
        performance.engine = server_data.engine
        performance.body = server_data.body

        if performance.fuel > 100 then performance.fuel = 100 end
        if performance.engine > 100 then performance.engine = 100 end
        if performance.body > 100 then performance.body = 100 end

        local vehdata = qb_vehicles.hash(model) or qb_vehicles(model --[[@as string]])

        local details = {
            name = vehdata.name,
            model = model,
            plate = plate,
            stats = performance,
            trunkItems = lib.array.filter(server_data.trunkItems, function (val)
                return val
            end),
            gloveboxItems = lib.array.filter(server_data.gloveboxItems, function (val)
                return val
            end),
        }

        DeleteEntity(vehEntity)

        local attempt = 0
        repeat
            pcall(DeleteEntity, vehEntity)
            Wait(500)
            attempt = attempt + 1
        until not DoesEntityExist(vehEntity) or attempt >= 5

        return details
    end

    
    ---@param model integer | string
    ---@param coords table | vector3
    ---@return number|boolean? vehicle
    ---@return string? error
    function utils.spawnCar(model, coords, networked)
        model = type(model) == "number" and model or joaat(model)

        local vector = vec(coords.x, coords.y, coords.z, coords.w or 0.0)
        local isNetworked = networked == nil or networked

        local playerCoords = GetEntityCoords(cache.ped)
        if not vector or not playerCoords then
            return false, 'Invalid coordinates'
        end

        local dist = #(playerCoords - vector.xyz)

        if dist > 424 then -- Onesync infinity Range (https://docs.fivem.net/docs/scripting-reference/onesync/)
            return false, 'Out of range'
        end

        local promise = promise.new()

        local function results(res)
            if promise then
                promise:resolve(res)
            end
        end

        CreateThread(function()
            if not pcall(lib.requestModel, model, 15000) then
                return results(nil)
            end
            
            local vehicle = CreateVehicle(model, vector.x, vector.y, vector.z, vector.w, isNetworked, true)

            if networked then
                local id = NetworkGetNetworkIdFromEntity(vehicle)
                SetNetworkIdCanMigrate(id, true)
                SetEntityAsMissionEntity(vehicle, true, true)
            end
            
            SetVehicleHasBeenOwnedByPlayer(vehicle, true)
            SetVehicleNeedsToBeHotwired(vehicle, false)
            SetModelAsNoLongerNeeded(model)
            SetVehRadioStation(vehicle, "OFF")

            RequestCollisionAtCoord(vector.x, vector.y, vector.z)
            while not HasCollisionLoadedAroundEntity(vehicle) do
                Wait(0)
            end

            results(vehicle)
        end)

        if promise then
            local vehicle = Citizen.Await(promise)
            
            if not vehicle or not DoesEntityExist(vehicle) then
                return false, 'Failed to load vehicle model'
            end

            return vehicle
        end
    end

    ---@param coords vector3
    ---@param blipData BlipData
    ---@param category boolean
    function utils.createGarageBlip(coords, garage, blipData, category)
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, blipData?.sprite or 285)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, blipData?.color or 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(garage)
        EndTextCommandSetBlipName(blip)

        if category then
            SetBlipCategory(blip, 10)
        end
    end

    ---@param jobs GarageGroupAccess
    function utils.checkJobs(playerJob, jobs)
        if not playerJob then return false end

        local jn = playerJob.name
        local jt = playerJob.type
        local jg = playerJob.grade.level


        local tt = type(jobs)

        if tt == 'string' then
            return jn == jobs or jt == jobs
        end

        if tt == 'table' then
            if lib.array.isArray(jobs) then
                return lib.table.contains(jobs, jn) or lib.table.contains(jobs, jt)
            end

            local requirement = jobs[jn] or jobs[jt]
            if not requirement then return false end

            local rt = type(requirement)

            if rt == 'number' then
                return jg >= requirement
            end

            if rt == 'table' and lib.array.isArray(requirement) then
                return lib.table.contains(requirement, jg)
            end

            return false
        end

        return false
    end

    ---@param check GarageAccessBy
    function utils.canAccess(check)
        if not check then
            return true
        end

        local jobs = check.groups
        local citizenids = check.citizenids

        ---@cast citizenids -nil

        local job = QBPlayerData.job or sm_core:GetPlayerData()?.job
        local citizenid = QBPlayerData.citizenid or sm_core:GetPlayerData()?.citizenid

        local tc = type(citizenids)
        local haveAccess = tc == 'string' and citizenid == citizenids

        if not haveAccess and tc == 'table' and lib.array.isArray(citizenids) then
            haveAccess = lib.array.includes(citizenids, citizenid)
        end

        if not haveAccess and jobs then
            haveAccess = utils.checkJobs(job, jobs)
        end

        return haveAccess
    end

    ---@return boolean
    function utils.isDead()
        local metadata = QBPlayerData.metadata or sm_core:GetPlayerData()?.metadata
        if metadata and (metadata.isdead or metadata.inlaststand) then
            return true
        end
        return IsEntityDead(cache.ped)
    end

    ---@param plate string
    ---@return integer|nil
    function utils.findPlateOnClient(plate)
        local vehicles = GetGamePool('CVehicle')
        return lib.array.find(vehicles, function (veh)
            return qbLib.string.trim(GetVehicleNumberPlateText(veh)):upper() == plate:upper()
        end)
    end
else
    ---@param plate string
    ---@return integer|nil
    function utils.findPlateOnServer(plate)
        local vehicles = GetAllVehicles()
        return lib.array.find(vehicles, function (veh)
            return qbLib.string.trim(GetVehicleNumberPlateText(veh)):upper() == plate:upper()
        end)
    end

    ---@param model string
    ---@param default number
    ---@return number
    function utils.calculateDepotPrice(model, default)
        local vehdata = qb_vehicles.hash(model) or qb_vehicles(model)
        local category = vehdata and vehdata.category

        local price = 0

        if type(default) == "number" and default >= 1 then
            price = default
        else
            price = depot_price[category] or 5000
        end

        return price
    end

    ---@param coords vector3
    ---@param heading number
    ---@param distance? number
    ---@return vector4? spawn_point
    function utils.getNearbySpawnPoints(coords, heading, distance)
        local angles = { 0, 90, 180, 270, 45, 135, 225, 315 }
        distance = distance or 3.0

        local spawn_point
        for _, angle in ipairs(angles) do
            local rad = math.rad(heading + angle)
            local x = coords.x + (math.sin(rad) * distance)
            local y = coords.y + (math.cos(rad) * distance)
            local z = coords.z

            local testCoords = vec(x, y, z, heading + angle)

            if not lib.getNearbyVehicles(vec3(x, y, z), distance, true)[1] then
                spawn_point = testCoords
                break
            end
        end
        return spawn_point
    end
end