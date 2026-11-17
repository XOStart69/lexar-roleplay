local instances = {}

local garage_config = require 'config.garage'
local garage_auto_store_config = require 'data.garage_auto_store'

local function infoThread(self)

    if self.garageData then
        local garageCoords = self.coords
        local playerCoords = GetEntityCoords(cache.ped)
        local maxZDiff = self.garageData.locations.maxZDiff or 3.0

        if math.abs(playerCoords.z - garageCoords.z) > maxZDiff then
            if self.infoUi then
                infoUi.remove('rhd_garage:info')
                self.infoUi = nil
            end
            return
        end
    end

    local description
    local inVeh = cache.vehicle

    if self.isAutoStore then
        description = [[
Zona ini akan otomatis menyimpan kendaraan Anda saat
memasuki area dengan kendaraan.
        ]]
    else
        description = inVeh and not (self.garageData.category == 'depot') and
            'Tekan [kbd]E[/kbd] untuk simpan kendaraan' or not inVeh and
            'Tekan [kbd]E[/kbd] untuk akses garasi'
    end

    if not self.isAutoStore and utils.isDead() then
        description = nil
    end

    if not description or not self.canAccess then
        if self.infoUi then
            infoUi.remove('rhd_garage:info')
            self.infoUi = nil
        end
        return
    end

    if not self.infoUi or self.infoUi ~= description then
        infoUi.show({
            id = 'rhd_garage:info',
            title = self.garageId,
            icon = 'fa-solid fa-warehouse',
            description = description,
        })
        self.infoUi = description
    end
end

local function interactThread(self)
    if not self.canAccess then return end

    DisableControlAction(0, 38, true)

    if not self.busy and IsDisabledControlJustPressed(0, 38) then
        if utils.isDead() then
            return sm_core:Notify('Kamu tidak bisa melakukan ini saat mati', 'error')
        end

        local garageCoords = self.coords
        local playerCoords = GetEntityCoords(cache.ped)
        local maxZDiff = self.garageData.locations.maxZDiff or 3.0

        if math.abs(playerCoords.z - garageCoords.z) > maxZDiff then
            return
        end

        local vehicle = cache.vehicle
        if vehicle and not DoesEntityExist(vehicle) then
            vehicle = nil
        end
        self.busy = true

        if vehicle then
            Client.storeVehicle(self, vehicle)
        else
            self.busy = false
            Client.openGarage(self.garageId, self.garageData)
        end
    end
end

local function onEnter(self)
    self.infoUi = nil

    PlayerState:set('rhd_garage_zoneId', self.garageId, true)
    self.canAccess = utils.canAccess(self.garageData.access)

    if self.garageData.locations then
        local garageCoords = self.coords
        local playerCoords = GetEntityCoords(cache.ped)
        local maxZDiff = self.garageData.locations.maxZDiff or 3.0

        if math.abs(playerCoords.z - garageCoords.z) > maxZDiff then
            self.canAccess = false
        end
    end

    if cache.vehicle and self.garageData.autoStoreVehicle and self.canAccess then
        self.busy = true
        Client.storeVehicle(self, cache.vehicle, true)
    end
end

local function onExit(self)
    self.infoUi = nil
    infoUi.remove('rhd_garage:info')
    PlayerState:set('rhd_garage_zoneId', nil, true)
end

local function onRemove(self)
    if self.infoUi then
        infoUi.remove('rhd_garage:info')
        self.infoUi = nil
    end
    if self.blipId then
        RemoveBlip(self.blipId)
    end
    PlayerState:set('rhd_garage_zoneId', nil, true)
end

local function inside(self)
    if not self.garageData.hideInfoUi then
        self:infoThread()
    end
    self:interactThread()
end

---@param garageId GarageId
---@param garageData GarageData
local function prepareInstance(garageId, garageData)
    local instance
    local ltype = garageData.locations.type

    if ltype == 'zones' then
        instance = lib.zones.poly(garageData.locations.polygon)
    elseif ltype == 'points' then
        local coords = garageData.locations.coords
        local distance = garageData.locations.distance or 5.0
        instance = lib.points.new(coords, distance)
    end

    instance.garageId = garageId --[[@as GarageId]]
    instance.garageData = garageData --[[@as GarageData]]

    if garageData.blipType then
        local blipData = garage_config.blip_data[garageData.blipType]
        instance.blipId = utils.createGarageBlip(instance.coords, garageId, blipData, true)
    end

    function instance:updateAccess()
        self.canAccess = utils.canAccess(self.garageData.access)
    end

    instance.infoThread = infoThread
    instance.interactThread = interactThread
    instance.onEnter = onEnter
    instance.onExit = onExit

    if ltype == 'zones' then
        instance.inside = inside
    elseif ltype == 'points' then
        instance.nearby = inside
    end

    instance.onRemove = onRemove

    return instance
end

---@param garageId GarageId
---@param polygon GaragePolygon
local function prepareAutoStoreInstance(garageId, polygon)
    local instance = lib.zones.poly(polygon)

    instance.garageId = garageId --[[@as GarageId]]
    instance.isAutoStore = true

    function instance:onEnter()
        self.infoUi = nil
        if not cache.vehicle or self.busy then return end

        self.busy = true
        local coreInstance = instances[garageId]?.core

        if not coreInstance then
            return lib.print.warn(('Garage instance not found for auto store [garageId: %s]'):format(garageId))
        end

        local canAccess = utils.canAccess(coreInstance.garageData.access)
        if not canAccess then return end

        Client.storeVehicle(coreInstance, cache.vehicle, true)
    end

    function instance:inside()
        infoThread(self)
    end
    
    function instance:onExit()
        self.busy = false
        self.infoUi = nil
        infoUi.remove('rhd_garage:info')
    end

    return instance
end

---@param garageId GarageId
---@param data GaragePolygon | GaragePolygon[]
local function prepareAutoStoreInstances(garageId, data)
    if data.points then
        return { prepareAutoStoreInstance(garageId, data) }
    end

    local zones = {}

    for i = 1, #data do
        zones[i] = prepareAutoStoreInstance(garageId, data[i])
    end

    return zones
end

local function removeAutoStoreZones(zones)
    for i = 1, #zones do
        zones[i]:remove()
    end
end

local function checkInstance(garageId, type, data)
    if not instances[garageId] then
        instances[garageId] = {}
    end

    local fn = type == 'core' and prepareInstance or
                 type == 'autoStore' and prepareAutoStoreInstances

    if fn and not instances[garageId][type] then
        instances[garageId][type] = fn(garageId, data)
    end
end

---@param garages GarageConfig
local function prepareGarageLocations(garages)
    for garageId, garageData in pairs(garages) do
        checkInstance(garageId, 'core', garageData)

        local autoStoreConfig = garage_auto_store_config[garageId]
        if autoStoreConfig then
            checkInstance(garageId, 'autoStore', autoStoreConfig)
        end
    end
end

RegisterNetEvent('rhd_garage:client:loadGarageLocations', function (garages)
    if source == '' then return end
    prepareGarageLocations(garages)
end)

RegisterNetEvent('rhd_garage:client:addGarageLocation', function (garageId, garageData)
    if source == '' then return end
    prepareGarageLocations({ [garageId] = garageData })
end)

RegisterNetEvent('rhd_garage:client:addAutoStoreLocation', function (garageId, polygon)
    if source == '' then return end

    if garage_auto_store_config[garageId] then
        return lib.print.warn(('Auto store configuration already exists for garageId %s, skipping add'):format(garageId))
    end
    
    garage_auto_store_config[garageId] = polygon
    checkInstance(garageId, 'autoStore', polygon)
end)

RegisterNetEvent('rhd_garage:client:removeAutoStoreLocation', function (garageId)
    if source == '' then return end

    garage_auto_store_config[garageId] = nil

    local entry = instances[garageId]
    if not entry or not entry.autoStore then
        return lib.print.warn(('Auto store instance not found for garageId %s, skipping remove'):format(garageId))
    end

    removeAutoStoreZones(entry.autoStore)
    instances[garageId].autoStore = nil
end)

RegisterNetEvent('rhd_garage:client:removeGarageLocation', function (garageId)
    if source == '' then return end

    local entry = instances[garageId]
    if not entry then return end

    if entry.autoStore then
        removeAutoStoreZones(entry.autoStore)
    end

    if entry.core then
        if entry.core.onRemove then
            entry.core:onRemove()
        end

        entry.core:remove()
    end

    instances[garageId] = nil
end)

RegisterNetEvent('rhd_garage:client:autoStoreVehicleByPlate', function (plate, garageId)
    if source == '' then return end

    local entry = instances[garageId]
    if not entry or not entry.core then
        return lib.print.warn(('Auto store instance not found for garageId %s, cannot auto store vehicle [plate: %s]'):format(garageId, plate))
    end

    local vehicle = utils.findPlateOnClient(plate)

    if not (vehicle and DoesEntityExist(vehicle)) then
        return lib.print.warn(('Vehicle with plate %s not found for auto store in garageId %s'):format(plate, garageId))
    end

    Client.storeVehicle(entry.core, vehicle, true)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function (job)
    if source == '' then return end

    local zoneId = PlayerState.rhd_garage_zoneId
    if not zoneId then return end

    local entry = instances[zoneId]
    if not entry or not entry.core then return end

    entry.core:updateAccess()
end)

exports('GetGarages', function ()
    local out = {}
    for garageId, entry in pairs(instances) do
        out[garageId] = entry.core
    end
    return out
end)

_ENV.ClientLocations = {
    getGarages = function(garageId)
        if garageId then
            return instances[garageId]?.core
        end
        local out = {}
        for id, entry in pairs(instances) do
            out[id] = entry.core
        end
        return out
    end
}