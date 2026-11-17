local plants = lib.class('plants')
local pt = {}
local blips = {}
local renderedPlants = {}
local isPlanting = false

local serverTimeOffset = 0

local function getServerTime()
    return math.floor(GetGameTimer() / 1000) + serverTimeOffset
end

local allpoly = {}

local function toV3(data, z)
    if data then
        local retval = {}
        for i = 1, #data do
            retval[i] = vec3(data[i].x, data[i].y, z)
        end
        return retval
    end
end

local function serverPlayerState(key, value)
    LocalPlayer.state:set(key, value, true)
end

local poly = {
    create = function(id, tipe, data, dalam, luar)
        if allpoly[id] then allpoly[id]:remove() end
        if tipe == 'poly' then
            if data.points then
                allpoly[id] = lib.zones.poly({
                    points = toV3(data.points, data.data.minZ),
                    thickness = (data.data.maxZ - data.data.minZ),
                    onExit = function()
                        serverPlayerState('PosisiZona', nil)
                        luar(data.data)
                    end,
                    onEnter = function()
                        serverPlayerState('PosisiZona', id)
                        dalam(data.data)
                    end,
                    debug = data.data?.debugPoly
                })
            end
        elseif tipe == 'box' then
            if data.point then
                allpoly[id] = lib.zones.box({
                    coords = data.point,
                    size = vec3(data.length, data.width, (data.data.maxZ - data.data.minZ)),
                    rotation = data.data?.heading,
                    onExit = function()
                        serverPlayerState('PosisiZona', nil)
                        luar(data.data)
                    end,
                    onEnter = function()
                        serverPlayerState('PosisiZona', id)
                        dalam(data.data)
                    end,
                    debug = data.data?.debugPoly
                })
            end
        elseif tipe == 'circle' then
            if data.point then
                allpoly[id] = lib.zones.sphere({
                    coords = data.point,
                    radius = data.radius,
                    onExit = function()
                        serverPlayerState('PosisiZona', nil)
                        luar(data.data)
                    end,
                    onEnter = function()
                        serverPlayerState('PosisiZona', id)
                        dalam(data.data)
                    end,
                    debug = data.data?.debugPoly
                })
            end
        end
    end
}

local function createBlip(name, coords, sprite, colour, scale)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale or 1.0)
    SetBlipColour(blip, colour)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)
    SetBlipCategory(blip, 24)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)

    blips[#blips + 1] = blip
    return blip
end

local function enableBlips()
    AddTextEntry("BLIP_CAT_" .. 24, "Lahan")
    for k, v in pairs(cfg.farmer.zones) do
        if v.label and v.data and v.data.center then
            -- strip the "Lahan: " prefix on the map (header already says "Lahan"),
            -- but keep the full label everywhere else (menus/context use v.label)
            local blipName = (v.label:gsub('^Lahan:%s*', ''))
            blips[k] = createBlip(blipName, v.data.center, 237, 43, 0.7)
        end
    end
end

local function disableBlips()
    for _, v in pairs(blips) do
        RemoveBlip(v)
    end
    blips = {}
end

function plants:constructor(data)
    self.id = data.id
    self.model = data.model
    self.panen = data.panen
    self.coords = vec3(data.coords.x, data.coords.y, data.coords.z)
    self.index = data.index
    self.distance = cfg.farmer.nanem[self.index] and cfg.farmer.nanem[self.index].drawDistance or 5.0
    self.land = data.land
    self.src = data.src

    self.point = lib.points.new({
        coords = self.coords,
        distance = self.distance,
        onEnter = function ()
            renderedPlants[self.id] = self.coords
            self.inside = true
            local model = lib.requestModel(self.model, 30000)
            self.entity = CreateObject(model, self.coords.x, self.coords.y, self.coords.z, false, false)
            SetModelAsNoLongerNeeded(self.model)
            PlaceObjectOnGroundProperly(self.entity)
            SetEntityNoCollisionEntity(cache.ped, self.entity, false)
            FreezeEntityPosition(self.entity, true)
            self.zone = exports.ox_target:addSphereZone({
                coords = self.coords,
                radius = 1.0,
                options = {
                    {
                        label = 'Panen Tanaman',
                        icon = 'fas fa-seedling',
                        distance = cfg.farmer.jarakAntarTanaman,
                        canInteract = function ()
                            return getServerTime() > self.panen and self.inside
                        end,
                        onSelect = function ()
                            local bisa, notif = cfg.farmer.nanem[self.index].validasi('harvesting')
                            if not bisa then
                                lib.notify({title = 'Tanaman', description = notif, type = 'error', duration = 5000})
                                return
                            end
                            if lib.skillCheckActive() then lib.cancelSkillCheck() end
                            local cek = cfg.farmer.nanem[self.index].minigame()
                            if not cek then return end

                            local hasil = cfg.farmer.nanem[self.index].hasil
                            local items = exports.ox_inventory:Items()
                            local label = items[hasil] and items[hasil].label or hasil

                            local completed = lib.progressBar({
                                duration = cfg.farmer.progress.duration.harvesting,
                                label = (cfg.farmer.progress.label.harvesting):format(label),
                                anim = cfg.farmer.progress.anim.harvesting,
                                disable = {move = true, car = true, combat = true},
                                useWhileDead = false,
                                canCancel = true,
                            })

                            ClearPedTasksImmediately(cache.ped)

                            if completed then
                                TriggerTokenEvent('sm_farmer:panen', self.id, self.land)
                            end
                        end
                    },
                    {
                        label = 'Cek Tanaman',
                        icon = 'fas fa-seedling',
                        distance = cfg.farmer.jarakAntarTanaman,
                        canInteract = function ()
                            return getServerTime() < self.panen and self.inside
                        end,
                        onSelect = function ()
                            lib.notify({
                                title = 'Tanaman',
                                description = 'Siap panen dalam ' .. self.panen - getServerTime() .. ' detik.'
                            })
                        end
                    }
                }
            })
        end,
        onExit = function ()
            renderedPlants[self.id] = nil
            self.inside = false
            if self.zone then
                exports.ox_target:removeZone(self.zone)
                self.zone = nil
            end
            if self.entity then
                DeleteObject(self.entity)
                self.entity = nil
            end
        end,
        nearby = function ()
            if getServerTime() > self.panen then
                DrawMarker(
                    2,
                    self.coords.x, self.coords.y, self.coords.z + 1.2,
                    0.0, 0.0, 0.0,
                    180.0, 0.0, 0.0,
                    0.25, 0.25, 0.25,
                    46, 204, 113, 180,
                    true,
                    true,
                    2,
                    false,
                    nil, nil,
                    false
                )
            end
        end
    })

    self.deleteObject = function ()
        if self.entity then
            DeleteObject(self.entity)
            self.entity = nil
        end
    end

    self.remove = function ()
        self.deleteObject()
        if self.zone then
            exports.ox_target:removeZone(self.zone)
            self.zone = nil
        end
        self.point:remove()
        renderedPlants[self.id] = nil
        pt[self.land][self.id] = nil
    end

    pt[self.land][self.id] = self
end

local function isThereNearPlant(coords, land)
    if not pt[land] then return false end
    for _, v in pairs(pt[land]) do
        if #(coords - v.coords) < cfg.farmer.jarakAntarTanaman then
            return true
        end
    end
    return false
end

RegisterNetEvent('sm_farmer:startPlanting', function(index, slot)
    if isPlanting then return end
    isPlanting = true

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local land = LocalPlayer.state.PosisiZona
    local crop = cfg.farmer.nanem[index]

    if not land or land ~= crop.land then
        local items = exports.ox_inventory:Items()
        local label = items[crop.hasil] and items[crop.hasil].label or crop.hasil
        lib.notify({
            title = 'Petani',
            description = 'Kamu tidak berada di area penanaman ' .. label,
            type = 'error'
        })
        isPlanting = false
        return
    end

    local fwd = GetEntityForwardVector(ped)
    local plantCoords = vec3(coords.x + fwd.x, coords.y + fwd.y, coords.z)

    if isThereNearPlant(plantCoords, land) then
        lib.notify({
            title = 'Petani',
            description = 'Jaga jarakmu dengan tanaman lain',
            type = 'error'
        })
        isPlanting = false
        return
    end

    local bisa, notif = crop.validasi('planting')
    if not bisa then
        if notif then
            lib.notify({title = 'Tanaman', type = 'error', description = notif, duration = 5000})
        end
        isPlanting = false
        return
    end

    local items = exports.ox_inventory:Items()
    local label = items[crop.bibit] and items[crop.bibit].label or crop.bibit
    local cek1 = lib.progressBar({
        duration = cfg.farmer.progress.duration.planting,
        label = (cfg.farmer.progress.label.planting):format(label),
        anim = cfg.farmer.progress.anim.planting,
        disable = {move = true, car = true, combat = true},
        useWhileDead = false,
        canCancel = true,
    })

    if not cek1 then
        ClearPedTasksImmediately(ped)
        isPlanting = false
        return
    end

    ClearPedTasks(ped)
    Wait(5000)

    lib.requestModel('prop_wateringcan002', 10000)

    local cek2 = lib.progressBar({
        duration = 5000,
        label = 'Menyiram ' .. label .. '...',
        anim = {
            dict = 'bz@watercan@animation',
            clip = 'bz_watercan',
            flag = 49,
        },
        prop = {
            model = 'prop_wateringcan002',
            bone = 57005,
            pos = vec3(0.27, 0.0, -0.23),
            rot = vec3(-75.0, 41.0, 36.0)
        },
        disable = {move = true, car = true, combat = true},
        useWhileDead = false,
        canCancel = true,
    })

    ClearPedTasksImmediately(ped)

    if not cek2 then
        isPlanting = false
        return
    end

    TriggerServerEvent('sm_farmer:confirmPlanting', index, land, plantCoords, slot)
    isPlanting = false
end)

RegisterNetEvent('sm_farmer:addPlants', function (land, data, serverTime)
    if source == '' then return end
    if serverTime then
        serverTimeOffset = serverTime - math.floor(GetGameTimer() / 1000)
    end
    data.land = land
    plants:new(data)
end)

RegisterNetEvent('sm_farmer:removePlants', function (land, id)
    if source == '' then return end
    if not pt[land] or not pt[land][id] then return end
    pt[land][id]:remove()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function ()
    TriggerServerEvent('sm_farmer:onPlayerJoined')
end)

RegisterNetEvent('sm_farmer:loadPlants', function (data, serverTime)
    if serverTime then
        serverTimeOffset = serverTime - math.floor(GetGameTimer() / 1000)
    end
    for _, v in pairs(data) do
        Wait(50)
        for _, b in pairs(v) do
            plants:new(b)
        end
    end
end)

CreateThread(function()
    enableBlips()
    if LocalPlayer.state.PosisiZona and cfg.farmer.zones[LocalPlayer.state.PosisiZona] then
        infoUI.show({
            id = 'farmer_zone',
            title = 'Area Lahan Tani',
            icon = 'fa-solid fa-wheat-awn',
            description = cfg.farmer.zones[LocalPlayer.state.PosisiZona].label
        })
    end
    for k, v in pairs(cfg.farmer.zones) do
        pt[k] = {}
        poly.create(k, 'poly', v, function()
            if v.label then
                infoUI.show({
                    id = 'farmer_zone',
                    title = 'Area Lahan Tani',
                    icon = 'fa-solid fa-wheat-awn',
                    description = v.label
                })
            end
        end, function()
            infoUI.remove('farmer_zone')
        end)
    end

    if cache.serverId then
        TriggerServerEvent('sm_farmer:onPlayerJoined')
    end
end)

AddEventHandler('onResourceStop', function (res)
    if res ~= cache.resource then return end

    if LocalPlayer.state.PosisiZona and cfg.farmer.zones[LocalPlayer.state.PosisiZona] then
        infoUI.remove('farmer_zone')
    end

    disableBlips()

    for _, v in pairs(pt) do
        for _, j in pairs(v) do
            j.deleteObject()
        end
    end

    for _, zone in pairs(allpoly) do
        zone:remove()
    end
end)
