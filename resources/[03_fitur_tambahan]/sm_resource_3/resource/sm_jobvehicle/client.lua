local config = localmodule 'config'

local SHOPS = config.shops

---@type table<string, number>
local peds = {}
---@type table<string, boolean>
local nearby = {}
local busy = false

---@param shop table
---@param jobName string?
---@return boolean
local function isJobAllowed(shop, jobName)
    if not jobName then return false end
    if shop.job == jobName then return true end

    local jobs = shop.jobs
    if not jobs then return false end

    for i = 1, #jobs do
        if jobs[i] == jobName then return true end
    end

    return false
end

---@param vehicle table
---@param jobName string
---@return boolean
local function isVehicleAllowed(vehicle, jobName)
    local jobs = vehicle.allowedJobs
    if not jobs then return true end

    for i = 1, #jobs do
        if jobs[i] == jobName then return true end
    end

    return false
end

---@param required string|string[]
---@return boolean
local function hasRequiredItem(required)
    local counts = ox_inventory:Search('count', required)
    if type(counts) ~= 'table' then return (counts or 0) > 0 end

    for _, count in pairs(counts) do
        if count > 0 then return true end
    end

    return false
end

---@param vehicle number
---@param livery number
local function applyLivery(vehicle, livery)
    if GetNumVehicleMods(vehicle, 48) > 0 then
        SetVehicleMod(vehicle, 48, livery, false)
        return
    end

    if GetVehicleLiveryCount(vehicle) > 0 then
        SetVehicleMod(vehicle, 48, -1, false)
        SetVehicleLivery(vehicle, livery)
    end
end

---@param data { model: string, plate: string, livery: number, coords: vector4 }
local function spawnVehicle(data)
    local hash = joaat(data.model)
    if not lib.requestModel(hash, 10000) then return end

    local coords = data.coords
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, false)
    SetModelAsNoLongerNeeded(hash)

    if vehicle == 0 then return end

    SetVehicleNumberPlateText(vehicle, data.plate)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)

    if data.livery and data.livery >= 0 then
        applyLivery(vehicle, data.livery)
    end

    pcall(function()
        exports.LegacyFuel:SetFuel(vehicle, 100.0)
    end)

    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
end

---@param shop table
---@return number?
local function findSpawnIndex(shop)
    local spawns = shop.spawnLocations

    for i = 1, #spawns do
        local coords = spawns[i]

        if not IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
            return i
        end
    end
end

---@param shopKey string
---@param vehicleKey string
---@param vehicle table
local function purchase(shopKey, vehicleKey, vehicle)
    if busy then return end

    local confirm = lib.alertDialog({
        header = 'Purchase Vehicle',
        content = ('Are you sure you want to purchase %s for $%s?'):format(vehicle.label, vehicle.price),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Confirm',
            cancel = 'Cancel'
        }
    })

    if confirm ~= 'confirm' then return end

    local spawnIndex = findSpawnIndex(SHOPS[shopKey])

    if not spawnIndex then
        return lib.notify({ description = 'Spawn area is blocked, please clear the area!', type = 'error' })
    end

    busy = true

    local called, ok, result = pcall(lib.callback.await, 'sm_jobvehicle:server:purchase', false, shopKey, vehicleKey, spawnIndex)

    if not called or not ok or type(result) ~= 'table' then
        busy = false
        return lib.notify({ description = called and type(result) == 'string' and result or 'Error', type = 'error' })
    end

    local spawned, err = pcall(spawnVehicle, result)
    busy = false

    if not spawned then
        lib.print.error(err)
    end

    lib.notify({ description = 'Vehicle purchased successfully!', type = 'success' })
end

---@param shopKey string
local function openShop(shopKey)
    local shop = SHOPS[shopKey]
    local job = QBPlayerData.job

    if not job or not isJobAllowed(shop, job.name) then
        return lib.notify({ description = 'You are not authorized to use this shop!', type = 'error' })
    end

    local owned = lib.callback.await('sm_jobvehicle:server:owned', false) or {}
    local options = {}

    for vehicleKey, vehicle in pairs(shop.vehicles) do
        if isVehicleAllowed(vehicle, job.name) then
            local canPurchase = true
            local status = ''
            local description = ('Price: $%s'):format(vehicle.price)

            if vehicle.oneTimePurchase and owned[vehicle.model] then
                canPurchase = false
                status = ' - OWNED'
            end

            if job.grade.level < vehicle.requiredGrade then
                canPurchase = false
                status = (' - GRADE %s REQUIRED'):format(vehicle.requiredGrade)
            end

            if vehicle.requiredGrade > 0 then
                description = ('%s | Grade Required: %s'):format(description, vehicle.requiredGrade)
            end

            local required = vehicle.requiredItem

            if required then
                if not hasRequiredItem(required) then
                    canPurchase = false
                    status = ' - LACKING ITEM'
                end

                local first = type(required) == 'table' and required[1] or required
                local item = ox_items and ox_items[first]
                description = ('%s | Butuh: %s'):format(description, item and item.label or first)
            end

            options[#options + 1] = {
                title = vehicle.label .. status,
                description = description,
                icon = canPurchase and 'fas fa-car' or 'fas fa-ban',
                disabled = not canPurchase,
                arrow = canPurchase,
                onSelect = function()
                    purchase(shopKey, vehicleKey, vehicle)
                end,
            }
        end
    end

    local menuId = 'sm_jobvehicle:' .. shopKey

    lib.registerContext({
        id = menuId,
        title = shop.label,
        options = options,
    })

    lib.showContext(menuId)
end

---@param id string
local function removePed(id)
    local ped = peds[id]
    peds[id] = nil

    if ped and DoesEntityExist(ped) then
        ox_target:removeLocalEntity(ped)
        DeleteEntity(ped)
    end
end

---@param id string
---@param shopKey string
---@param shop table
---@param location table
local function spawnPed(id, shopKey, shop, location)
    local hash = joaat(location.model)
    if peds[id] or not lib.requestModel(hash, 10000) then return end
    if not nearby[id] or peds[id] then return end

    local coords = location.coords
    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1, coords.w, false, true)

    SetModelAsNoLongerNeeded(hash)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    peds[id] = ped

    ox_target:addLocalEntity(ped, {
        {
            name = id,
            icon = 'fas fa-car',
            label = shop.label,
            canInteract = function()
                local job = QBPlayerData.job
                return job ~= nil and isJobAllowed(shop, job.name)
            end,
            onSelect = function()
                openShop(shopKey)
            end
        }
    })
end

for shopKey, shop in pairs(SHOPS) do
    local locations = shop.pedLocations

    for i = 1, #locations do
        local location = locations[i]
        local id = ('sm_jobvehicle:%s:%d'):format(shopKey, i)

        lib.points.new({
            coords = location.coords.xyz,
            distance = config.pedDistance,
            onEnter = function()
                nearby[id] = true
                spawnPed(id, shopKey, shop, location)
            end,
            onExit = function()
                nearby[id] = nil
                removePed(id)
            end,
        })
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for id in pairs(peds) do
        removePed(id)
    end
end)
