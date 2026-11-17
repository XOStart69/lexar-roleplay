if not interface.init(false) then
    return
end

local targetveh
local impoundIndex
local frameToken = 0
local frameShown = false

local function openFrame()
    frameToken += 1
    frameShown = true
    interface.show()
end

local function closeFrame()
    frameToken += 1
    local token = frameToken

    SetTimeout(450, function()
        if token == frameToken then
            frameShown = false
            interface.hide()
        end
    end)
end

local cfg = localmodule 'config.client'
local impoundJobs = localmodule('config.shared').jobs
local takePhoto = localmodule 'utils.camera'

local pedModule = require 'modules.pedHandle.client'
local blipModule = require 'modules.blipHandle.client'

---@param vehicleModel integer | string
---@param coords table | vector3
---@param heading number
---@return number? vehicle
local function spawnCar(vehicleModel, coords, heading, cb, networked)
    local model = type(vehicleModel) == "number" and vehicleModel or joaat(vehicleModel)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    local isNetworked = networked == nil or networked

    local playerCoords = GetEntityCoords(cache.ped)
    if not vector or not playerCoords then
        return
    end

    local dist = #(playerCoords - vector)

    if dist > 424 then -- Onesync infinity Range (https://docs.fivem.net/docs/scripting-reference/onesync/)
        return
    end

    local promise = not cb and promise.new()

    local function results(res)
        if promise then
            promise:resolve(res)
        elseif cb then
            cb(res)
        end
    end

    CreateThread(function()
        if not pcall(lib.requestModel, model, 15000) then
            return results(nil)
        end
        
        local vehicle = CreateVehicle(model, vector.x, vector.y, vector.z, heading, isNetworked, true)

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
        return Citizen.Await(promise)
    end
end

local function vehexist()
    if not (targetveh and DoesEntityExist(targetveh)) then
        return lib.notify({ description = 'Tidak ada kendaraan', type = 'error', duration = 8000 })
    end
    return true
end

local function impoundVehicle(impdata)
    if not vehexist() then return end

    local success = lib.progressBar({
        duration = 2500,
        label = 'Menginput data...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base'
        },
        prop = {
            {
                model = 'prop_notepad_01',
                bone = 18905,
                pos = vec(0.099999999999994, 0.020000000000004, 0.049999999999998),
                rot = vec(10.0, 0.0, 0.0)
            },
            {
                model = 'prop_pencil_01',
                bone = 58866,
                pos = vec(0.11000000000002,
                    -0.020000000000004,
                    0.00099999999999988),
                rot = vec(-120.0,
                    0.0,
                    0.0)
            }
        }
    })

    if success then
        local netId = NetworkGetNetworkIdFromEntity(targetveh)
        TriggerServerEvent('pimpound:impound', netId, impdata)
    end
end

local function release(idx, data)
    local model = safecall.fun(function ()
        return lib.requestModel(data.model, 1500)
    end)

    if not model then
        return lib.notify({
            description = 'Model kendaraan tidak valid.',
            type = 'error'
        })
    end

    local coords = cfg.location[idx]?.parkout

    if not coords then
        return lib.notify({
            description = 'Gagal mendapatkan lokasi parkir untuk mengeluarkan kendaraan',
            type = 'error'
        })
    end
    
    local vehicle = spawnCar(model, coords.xyz, coords.w, nil, true)
    
    if not vehicle then
        return lib.notify({
            description = 'Terjadi kesalahan saat mengeluarkan kendaraan',
            type = 'error'
        })
    end

    lib.setVehicleProperties(vehicle, data)

    CreateThread(function ()
        Wait(500)
        SetVehicleBodyHealth(vehicle --[[@as integer]], data.bodyHealth or 1000.0)
        SetVehicleEngineHealth(vehicle --[[@as integer]], data.engineHealth or 1000.0)
        exports.LegacyFuel:SetFuel(vehicle, data.fuelLevel or 100)

        if data.doors then
            for i = 1, #data.doors do
                SetVehicleDoorBroken(vehicle, data.doors[i], true)
            end
        end

        if data.windows then
            for i = 1, #data.windows do
                RemoveVehicleWindow(vehicle, data.windows[i])
            end
        end

        if data.tyres then
            for tyre, state in pairs(data.tyres) do
                SetVehicleTyreBurst(vehicle, tonumber(tyre) --[[@as number]], state == 2, 1000.0)
            end
        end
    end)

    local plate = data.plate and data.plate:trim() or GetVehicleNumberPlateText(vehicle --[[@as integer]]):trim()
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', plate)
end

local function openImpoundForm()
    if not vehexist() then return end

    local model = GetEntityModel(targetveh)
    local vehdata = qb_vehicles.hash(model)

    if not vehdata then
        return lib.notify({
            description = 'Kendaraan ini belum didaftarkan kedalam server, silahkan hubungi developer untuk memperbaiki ini.',
            type = 'error',
            duration = 12000
        })
    end

    local vehplate = GetVehicleNumberPlateText(targetveh):trim()

    local charinfo = QBPlayerData.charinfo
    local officer = charinfo.firstname .. ' ' .. charinfo.lastname

    openFrame()
    interface.send({
        action = 'openImpoundForm',
        data = {
            officer = officer,
            name = vehdata.name,
            plate = vehplate
        }
    })

    interface.focus(true, true)
end

local function openImpoundMenu()
    local ispolice = jobhandler.check(impoundJobs)
    local citizenid = QBPlayerData.citizenid

    openFrame()
    interface.send({
        action = 'openImpoundMenu',
        data = {
            citizenid = citizenid,
            ispolice = ispolice,
        }
    })

    interface.focus(true, true)
end

interface.callback('disableFocus', function (data, cb)
    cb({ success = true })
    interface.focus(false, false)
    closeFrame()
end)

interface.callback('getvehicle', function (data, cb)
    local vehiclelist = lib.cblt.await('pimpound:getlist', 1500)

    cb({ vehicles = vehiclelist })
end)

interface.callback('unlockVehicle', function (data, cb)
    cb({success = lib.callback.await('pimpound:unlock', 1500, data)})
end)

interface.callback('payFine', function (data, cb)
    cb({success = lib.callback.await('pimpound:payFine', 1500, data)})
end)

interface.callback('releaseVehicle', function (data, cb)
    local sdata = lib.callback.await('pimpound:release', 1500, data)

    if sdata then
        release(sdata.index, sdata.mods)
    end

    cb({success = sdata and true})
end)

interface.callback('submitForm', function (data, cb)
    cb({ success = true })
    impoundVehicle(data)
end)

interface.callback('getVehicleImage', function (data, cb)
    interface.focus(false, false)

    local url = takePhoto() or false
    interface.focus(true, true)

    cb({ url = url })
end)

lib.callback.register('pimpound:getprops', function (netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then return end

    local props = lib.getVehicleProperties(vehicle)
    props.bodyHealth = GetVehicleBodyHealth(vehicle)
    props.engineHealth = GetVehicleEngineHealth(vehicle)
    props.fuelLevel = exports.LegacyFuel:GetFuel(vehicle)

    return props
end)

lib.callback.register('pimpound:getindex', function ()
    local idx = impoundIndex impoundIndex = nil
    return idx
end)

local function setupPed(pdata)
    local coords = pdata.coords
    local ped_config = pdata.ped_config

    local points = lib.points.new(coords.xyz, 10, {
        entity = nil
    })
    
    function points:onEnter()
        if self.entity then
            pcall(function (...)
                self.entity:remove()
            end)
        end

        ped_config.target = {
            {
                label = 'Akses impound',
                icon = 'fas fa-warehouse',
                distance = 2.5,
                onSelect = function ()
                    impoundIndex = pdata.location
                    openImpoundMenu()
                end
            }
        }

        self.entity = pedModule:new(ped_config)
    end
    
    function points:onExit()
        if self.entity then
            pcall(function (...)
                self.entity:remove()
            end)
        end
        self.entity = nil
    end
end

RegisterNetEvent('pimpound:updateVehicle', function (plate, data)
    if source == '' or not frameShown then return end

    interface.send({
        action = 'updateVehicleData',
        data = {
            plate = plate,
            value = data
        }
    })
end)

CreateThread(function ()
    ox_target:addGlobalVehicle({
        {
            name = 'pimpound:impoundForm',
            label = 'Impound Vehicle',
            icon = 'fas fa-car',
            distance = 1.5,
            groups = impoundJobs,
            onSelect = function (data)
                targetveh = data.entity

                lib.registerContext({
                    id = 'pimpound:context',
                    title = 'Impound Kendaraan',
                    options = {
                        {
                            title = 'Impound kendaraan polisi',
                            description = 'Impound kendaraan polisi yang nantinya diambil di Kantor Polisi.',
                            onSelect = function(args)
                                openImpoundForm()
                            end,
                        },
                        {
                            title = 'Impound publik',
                            description = 'Impound kendaraan polisi yang nantinya diambil di Asuransi umum.',
                            onSelect = function(args)
                                impoundVehicle()
                            end,
                        },
                    },
                })

                lib.showContext('pimpound:context')
            end
        }
    })

    for i=1, #cfg.location do
        local data = cfg.location[i]
        local coords = data.coords
        local ped = data.ped
        local blip = data.blip

        if coords then
            if type(coords) == "table" and table.type(coords) == 'array' then
                array.forEach(coords, function (val)
                    setupPed({
                        coords = val,
                        ped_config = {
                            model = ped,
                            coords = coords
                        },
                        location = i,
                    })

                    if blip then
                        AddTextEntry("BLIP_CAT_" .. 36, "Police")
                        blipModule:new({
                            label = blip.label,
                            coords = val.xyz,
                            sprite = blip.sprite,
                            color = blip.color,
                            category = 36,
                        })
                    end
                end)
            else
                setupPed({
                    coords = coords,
                    ped_config = {
                        model = ped,
                        coords = coords
                    },
                    location = i,
                })

                if blip then
                    AddTextEntry("BLIP_CAT_" .. 36, "Police")
                    blipModule:new({
                        label = blip.label,
                        coords = coords.xyz,
                        sprite = blip.sprite,
                        color = blip.color,
                        category = 36,
                    })
                end
            end
        end
    end
end)