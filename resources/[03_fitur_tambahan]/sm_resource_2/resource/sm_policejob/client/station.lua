local config = localmodule 'config'
local interact = exports.rhd_interact

local VEHICLES = config.vehicles
local GARAGES = config.garages
local GARAGE_PED = config.garagePed
local EVIDENCE = config.evidence

local STATE_LABELS = { [0] = 'Tersedia', [2] = 'Impound' }

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'error' })
end

---@return boolean
local function isLeo()
    local job = QBPlayerData.job
    return job ~= nil and job.type == 'leo'
end

---@param spot { x: number, y: number, z: number, w: number }
---@param plate string
---@param vehicle table
local function spawnVehicle(spot, plate, vehicle)
    local hash = joaat(vehicle.model)
    if not lib.requestModel(hash, 10000) then return notify('Model kendaraan gagal dimuat.') end

    local veh = CreateVehicle(hash, spot.x, spot.y, spot.z, spot.w, true, false)
    SetModelAsNoLongerNeeded(hash)
    if veh == 0 then return notify('Gagal memunculkan kendaraan.') end

    SetVehicleNumberPlateText(veh, plate)
    SetVehicleOnGroundProperly(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleModKit(veh, 0)
    local livery = vehicle.livery
    if livery and livery >= 0 then
        SetVehicleLivery(veh, livery)
        if GetNumVehicleMods(veh, 48) > 0 then
            SetVehicleMod(veh, 48, livery, false)
        end
    end
    pcall(function() exports.LegacyFuel:SetFuel(veh, 100.0) end)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)

    local networked = pcall(lib.waitFor, function()
        if NetworkGetEntityIsNetworked(veh) then return true end
    end, 'kendaraan tidak tersinkron', 5000)

    local registered, reason = false, nil
    if networked then
        registered, reason = lib.callback.await('police:server:RegisterVehicle', false, VehToNet(veh))
    end
    if not registered then
        if DoesEntityExist(veh) then DeleteEntity(veh) end
        notify(reason or 'Gagal mendaftarkan kendaraan.')
    end
end

---@param kind string
---@param index number
---@param vehicle table
local function takeOut(kind, index, vehicle)
    local spawn = GARAGES[kind][index].spawn
    if IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, 2.0) then
        return notify('Lokasi spawn terblokir, bersihkan spawn point!')
    end

    local ok, spot, plate = lib.callback.await('police:server:TakeOutVehicle', false, kind, index, vehicle.model)
    if not ok then return notify(spot or 'Kendaraan tidak tersedia.') end

    lib.hideContext()
    spawnVehicle(spot, plate, vehicle)
end

---@param kind string
---@param index number
local function openGarage(kind, index)
    local job = QBPlayerData.job
    local grade = job and job.grade.level or 0
    local list = VEHICLES[kind]
    local icon = kind == 'heli' and 'helicopter' or 'car'
    local options = {}

    for i = 1, #list do
        local vehicle = list[i]
        if grade >= vehicle.minGrade then
            options[#options + 1] = {
                title = vehicle.label,
                description = vehicle.price > 0 and ('Harga : $%d'):format(vehicle.price) or 'Harga : Gratis',
                icon = icon,
                onSelect = function() takeOut(kind, index, vehicle) end,
            }
        end
    end

    if #options == 0 then
        options[1] = { title = 'Tidak ada kendaraan untuk pangkatmu', icon = 'ban', disabled = true }
    end

    lib.registerContext({ id = 'police_garage_menu', title = 'Kendaraan Polisi', options = options })
    lib.showContext('police_garage_menu')
end

local function openDrawer()
    local input = lib.inputDialog('Laci Barang Bukti', {
        { type = 'number', label = 'Nomor Laci', description = 'Masukkan nomor barang bukti', required = true, min = 1, max = 999999 },
    })
    local slot = input and tonumber(input[1])
    if not slot then return end

    local id = lib.callback.await('police:server:openDrawer', false, slot)
    if id then
        ox_inventory:openInventory('stash', id)
    end
end

---@param index number
local function openEvidenceMenu(index)
    lib.registerContext({
        id = 'police_evidence_menu',
        title = 'Barang Bukti',
        options = {
            { title = 'Laci Barang Bukti', description = 'Akses laci dengan memasukkan nomor barang bukti', icon = 'list-ol', onSelect = openDrawer },
            {
                title = 'Penyimpanan Barang Bukti Umum',
                description = 'Penyimpanan barang bukti yang dapat digunakan secara umum',
                icon = 'folder-closed',
                onSelect = function() ox_inventory:openInventory('stash', 'generalevidence_' .. index) end,
            },
        },
    })
    lib.showContext('police_evidence_menu')
end

local function openPlateTracker()
    local input = lib.inputDialog('Pelacakan Plat Kendaraan', {
        { type = 'input', label = 'Nomor Plat', placeholder = 'Masukkan nomor plat...', required = true, min = 1, max = 10 },
    })
    local plate = input and input[1]
    if not plate then return end

    local ok, info = lib.callback.await('police:server:checkPlate', false, plate)
    if not ok then return notify(info or 'Gagal memeriksa plat') end
    if not info then return notify('Kendaraan dengan plat tersebut tidak ditemukan!') end

    lib.registerContext({
        id = 'vehicle_plate_info',
        title = 'Informasi Kendaraan',
        options = {
            { title = 'Detail Pemilik', description = ('Citizen ID: %s\nNama: %s'):format(info.citizenid or 'N/A', info.owner or 'Tidak ditemukan'), icon = 'user' },
            { title = 'Detail Kendaraan', description = ('Model: %s\nPlat: %s'):format(info.vehicle or 'N/A', info.plate), icon = 'car' },
            { title = 'Status & Lokasi', description = ('Status: %s\nGarage: %s'):format(STATE_LABELS[info.state] or 'Impound Publik', info.garage or 'N/A'), icon = 'map-marker-alt' },
        },
    })
    lib.showContext('vehicle_plate_info')
end

CreateThread(function()
    local blip = config.stationBlip
    AddTextEntry('BLIP_CAT_36', 'Police')
    for i = 1, #config.stations do
        local station = config.stations[i]
        local handle = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(handle, blip.sprite)
        SetBlipScale(handle, blip.scale)
        SetBlipColour(handle, blip.colour)
        SetBlipAsShortRange(handle, true)
        SetBlipCategory(handle, 36)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(station.label)
        EndTextCommandSetBlipName(handle)
    end

    local addPed = exports[cache.resource]
    for kind, list in pairs(GARAGES) do
        local label = kind == 'heli' and 'Spawn Helikopter' or 'Garasi Polisi'
        local icon = kind == 'heli' and 'helicopter' or 'car'
        for i = 1, #list do
            addPed:addPed({
                model = GARAGE_PED,
                coords = { list[i].ped },
                renderDistance = 30.0,
                scenario = 'WORLD_HUMAN_CLIPBOARD',
                interactOptions = {
                    {
                        label = label,
                        icon = icon,
                        distance = 2.5,
                        canInteract = isLeo,
                        onSelect = function() openGarage(kind, i) end,
                    },
                },
            })
        end
    end

    for i = 1, #EVIDENCE do
        interact:addCoords({
            id = 'police_evidence_' .. i,
            coords = EVIDENCE[i],
            options = {
                {
                    label = 'Buka Barang Bukti',
                    icon = 'folder-open',
                    distance = 2.0,
                    canInteract = isLeo,
                    onSelect = function() openEvidenceMenu(i) end,
                },
            },
        })
    end

    interact:addCoords({
        id = 'police_plate_tracker',
        coords = config.plateTracker,
        options = {
            {
                label = 'Buka Plate Tracker',
                icon = 'car',
                distance = 2.0,
                canInteract = isLeo,
                onSelect = openPlateTracker,
            },
        },
    })

    ox_target:addModel(config.licenseVehicleModels, {
        {
            name = 'sm_open_license_menu',
            label = 'SIM Keliling',
            icon = 'fa-solid fa-id-card',
            distance = 2.5,
            groups = 'police',
            onSelect = function()
                TriggerEvent('sm_ktp:client:openLicenseMainMenu')
            end,
        },
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for i = 1, #EVIDENCE do
        interact:removeCoords('police_evidence_' .. i)
    end
    interact:removeCoords('police_plate_tracker')
end)
