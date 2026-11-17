---@class BUS: OxClass
local BUS = lib.class('BUS')

local npcModels = localmodule 'data.npc'
local routeConfig = localmodule 'data.route'
local blipModule = require 'modules.blipHandle.client'

local function getRandomCoordsInPolygon(polygon)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, p in ipairs(polygon.points) do
        if p.x < minX then minX = p.x end
        if p.y < minY then minY = p.y end
        if p.x > maxX then maxX = p.x end
        if p.y > maxY then maxY = p.y end
    end

    for _ = 1, 100 do
        local x = minX + math.random() * (maxX - minX)
        local y = minY + math.random() * (maxY - minY)
        local coords = vec3(x, y, polygon.coords.z)

        if polygon:contains(coords) then
            local found, z = GetGroundZFor_3dCoord(x, y, polygon.coords.z + 5.0, false)
            return vec3(x, y, found and z or polygon.coords.z)
        end
    end

    return polygon.coords
end

local function getFreeSeats(vehicle)
    local model = GetEntityModel(vehicle)
    local passengerCount = GetVehicleModelNumberOfSeats(model) - 1
    local freeSeats = {}

    for i = 0, passengerCount - 1 do
        if IsVehicleSeatFree(vehicle, i) then
            freeSeats[#freeSeats + 1] = i
        end
    end

    return freeSeats
end

local function createPassenger(count, polygon)
    local pedEntities = {}

    for i = 1, count do
        local model = npcModels[math.random(#npcModels)]
        local coords = getRandomCoordsInPolygon(polygon)

        lib.requestModel(model)

        local ped = CreatePed(4, model, coords.x, coords.y, coords.z, false, false)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, 0)
        SetEntityProofs(ped, true, true, true, true, true, true, true, true)

        table.insert(pedEntities, ped)
    end

    return pedEntities
end

local missionInfo = [[
Route: %d/%d
Penumpang: %d/%d
Total pendapatan: $%d

Jagalah keselamatan penumpang.
]]

function BUS:constructor(vehicle, routeIndex)
    self.routeData = routeConfig[routeIndex].locations

    self.vehicle = vehicle
    self.routeBlip = nil
    self.routeIndex = 1
    self.routeType = nil
    self.busy = false

    self.passenger = {}
    self.pedEntities = {}
    self.totalRewards = 0

    if not self.routeData then
        error(('Invalid route index %d for bus job!'):format(routeIndex))
    end

    local function createRoute(index)
        local route = self.routeData[index]

        self.busy = false

        if not self.routeType then
            self.routeType = 'ambil'
        elseif self.routeType == 'ambil' then
            self.routeType = 'turunkan'
        elseif self.routeType == 'turunkan' then
            self.routeType = 'ambil'
        end

        infoUI.show({
            id = 'busjob:mission',
            title = 'Pekerjaan Bus',
            icon = 'fa-solid fa-bus',
            description = missionInfo:format(
                self.routeIndex, #self.routeData,
                #self.passenger, route.npc.max,
                self.totalRewards
            ),
        })

        if self.routeType == 'ambil' then
            self.routePedZone = lib.zones.poly(route.npc.polygon)

            self.routePoints = lib.points.new({
                coords = self.routePedZone.coords,
                distance = 50,
                onEnter = function ()
                    if #self.pedEntities == 0 then
                        local count = math.random(route.npc.min, route.npc.max)
                        self.pedEntities = createPassenger(count, self.routePedZone)
                    end
                end,
                nearby = function (data)
                    if cache.vehicle ~= self.vehicle then
                        return
                    end

                    DrawMarker(20,
                        data.coords.x,
                        data.coords.y,
                        data.coords.z + 3.5,
                        0.0, 0.0, 0.0,
                        0, 0.0, 0.0,
                        3.0, 3.0, 1.0,
                        101, 255, 111, 255,
                        false, true, 2,
                        false, false, false, false
                    )

                    if data.currentDistance < 10.0 and not self.busy and GetEntitySpeed(self.vehicle) < 1 then
                        self.busy = true

                        FreezeEntityPosition(self.vehicle, true)
                        qb_ecore:Notify('Tunggu penumpang masuk ke kendaraan.')

                        local freeSeats = getFreeSeats(self.vehicle)
                        local skipped = 0
                        
                        for i = 1, #self.pedEntities do
                            local entity = self.pedEntities[i]
                            local seat = freeSeats[i]

                            if seat then
                                TaskEnterVehicle(entity, self.vehicle, -1, seat, 2.0, 1, 0)

                                CreateThread(function ()
                                    local timeout = 10000
                                    while timeout > 0 and not IsPedInVehicle(entity, self.vehicle) do
                                        Wait(100)
                                        timeout -= 100
                                    end
                                    self.passenger[#self.passenger + 1] = entity
                                end)
                            else
                                skipped += 1
                                pcall(DeleteEntity, entity)
                            end
                        end

                        repeat
                            Wait(100)
                        until #self.passenger + skipped == #self.pedEntities

                        if skipped > 0 then
                            qb_ecore:Notify(('%d penumpang tidak bisa ikut karena kendaraan penuh!'):format(skipped), 'error')
                        end

                        self.pedEntities = {}
                        FreezeEntityPosition(self.vehicle, false)

                        self.routePoints:remove()
                        self.routePedZone:remove()

                        self.routePoints = nil
                        self.routePedZone = nil

                        Wait(500)
                        createRoute(self.routeIndex)
                    end
                end
            })
        elseif self.routeType == 'turunkan' then
            self.routePoints = lib.points.new({
                coords = route.destination.xyz,
                distance = 50,
                nearby = function (data)
                    if cache.vehicle ~= self.vehicle then
                        return
                    end

                    DrawMarker(20,
                        data.coords.x,
                        data.coords.y,
                        data.coords.z + 3.5,
                        0.0, 0.0, 0.0,
                        0, 0.0, 0.0,
                        3.0, 3.0, 1.0,
                        101, 255, 111, 255,
                        false, true, 2,
                        false, false, false, false
                    )

                    if data.currentDistance < 5.0 and not self.busy and GetEntitySpeed(self.vehicle) < 1 then
                        self.busy = true

                        FreezeEntityPosition(self.vehicle, true)
                        qb_ecore:Notify('Tunggu sampai penumpang turun.')

                        local rewards = 0
                        local unloaded = 0

                        for i=1, #self.passenger do
                            local entity = self.passenger[i]

                            TaskLeaveVehicle(entity, self.vehicle, 0)
                            rewards += route.npc.price

                            CreateThread(function ()
                                local timeout = 10000
                                while timeout > 0 and IsPedInVehicle(entity, self.vehicle) do
                                    Wait(100)
                                    timeout -= 100
                                end
                                Wait(500)
                                DeleteEntity(entity)
                                unloaded += 1
                            end)
                        end

                        repeat
                            Wait(100)
                        until unloaded == #self.passenger

                        self.passenger = {}
                        self.totalRewards += rewards
                        FreezeEntityPosition(self.vehicle, false)
                        TriggerTokenEvent('sm_busjob:updateWork')

                        self.routePoints:remove()
                        self.routePoints = nil

                        Wait(500)

                        if self.routeIndex + 1 > #self.routeData then
                            if self.routeBlip then
                                self.routeBlip:remove()
                                self.routeBlip = nil
                            end
                            qb_ecore:Notify('Rute selesai, kembali ke kantor untuk mendapatkan upahanmu!', 'success')
                        else
                            self.routeIndex += 1
                            createRoute(self.routeIndex)
                        end
                    end
                end
            })
        end

        if not self.routeBlip then
            self.routeBlip = blipModule:new({
                coords = self.routePoints.coords,
                label = 'Penumpang bus',
                sprite = 280,
                color = 8,
                route = true
            })
        else
            self.routeBlip:setCoords(self.routePoints.coords)
            self.routeBlip:setRoute(true)
        end
    end

    createRoute(self.routeIndex)

    return self
end

function BUS:reset()
    self.vehicle = vehicle

    if self.vehicle and DoesEntityExist(self.vehicle) then
        SetEntityAsMissionEntity(self.vehicle, true, true)
        DeleteEntity(self.vehicle)
    end

    if self.routeBlip then
        self.routeBlip:remove()
    end

    if self.routePoints then
        self.routePoints:remove()
    end

    if self.routePedZone then
        self.routePedZone:remove()
    end

    if self.passenger and #self.passenger > 0 then
        for i=1, #self.passenger do
            local entity = self.passenger[i]
            pcall(DeleteEntity, entity)
        end
    end

    if self.pedEntities and #self.pedEntities > 0 then
        for i=1, #self.pedEntities do
            local entity = self.pedEntities[i]
            pcall(DeleteEntity, entity)
        end
    end

    infoUI.remove('busjob:mission')
end

return BUS