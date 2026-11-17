local QBCore = exports['qb-core']:GetCoreObject()
local Config = localmodule 'config.shared'

local currentVehicle = nil
local currentAssembly = nil
local completedParts = {}
local vehicleInteracts = {}
local activeAssemblies = {}
local testDriveActive = false
local originalCoords = nil
local testDriveVehicle = nil

local cachedHasJob = false
local cachedCanSPK = false

local function RefreshJobCache()
    local job = QBCore.Functions.GetPlayerData().job
    if not job then
        cachedHasJob = false
        cachedCanSPK = false
        return
    end
    local match = job.name == Config.RequiredJob.name
    cachedHasJob = match and job.grade.level >= Config.RequiredJob.assemblyGrade
    cachedCanSPK = match and job.grade.level >= Config.RequiredJob.spkGrade
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function() RefreshJobCache() end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() RefreshJobCache() end)
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then RefreshJobCache() end
end)

local function WaitForNetEntity(netId, timeout)
    local elapsed = 0
    while not NetworkDoesEntityExistWithNetworkId(netId) and elapsed < timeout do
        Wait(500)
        elapsed = elapsed + 500
    end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return nil end

    local entity = NetworkGetEntityFromNetworkId(netId)
    elapsed = 0
    while not DoesEntityExist(entity) and elapsed < 10000 do
        Wait(500)
        elapsed = elapsed + 500
        entity = NetworkGetEntityFromNetworkId(netId)
    end
    return DoesEntityExist(entity) and entity or nil
end

local function GetVehiclePartPosition(vehicle, partName)
    if not DoesEntityExist(vehicle) then return nil end

    local offset = Config.PartOffsets[partName]
    if not offset then return nil end

    local pos = GetEntityCoords(vehicle)
    local heading = math.rad(GetEntityHeading(vehicle))
    local cosH, sinH = math.cos(heading), math.sin(heading)

    return vector3(
        pos.x + offset.x * cosH - offset.y * sinH,
        pos.y + offset.x * sinH + offset.y * cosH,
        pos.z + offset.z
    )
end

local function ClearInteracts(filter)
    for key, id in pairs(vehicleInteracts) do
        if id and (not filter or key:find(filter)) then
            exports.rhd_interact:removeCoords(id)
            vehicleInteracts[key] = nil
        end
    end
end

local function ApplyGhostProps(vehicle)
    SetEntityAlpha(vehicle, Config.GhostVehicle.alpha, false)
    FreezeEntityPosition(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleUndriveable(vehicle, true)

    if Config.GhostVehicle.missionEntity then
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleHasBeenOwnedByPlayer(vehicle, false)
    end

    if Config.GhostVehicle.preventDamage then
        SetEntityCanBeDamaged(vehicle, false)
        SetVehicleCanBeVisiblyDamaged(vehicle, false)
        SetVehicleCanBreak(vehicle, false)
    end
end

local function CheckAssemblyCompletion()
    if not currentAssembly then return end

    local total, done = 0, 0
    for partName in pairs(currentAssembly.data.materials) do
        total = total + 1
        if completedParts[partName] then done = done + 1 end
    end

    if done >= total then
        ClearInteracts()
        TriggerTokenEvent('vehicle_assembly:completeAssembly', currentAssembly.vehicleNetId)
        currentVehicle = nil
        currentAssembly = nil
        completedParts = {}
    end
end

local function StartPartAssembly(partName)
    if not currentAssembly then return end

    local vehicleNetId = currentAssembly.vehicleNetId
    local success = lib.callback.await('vehicle_assembly:startPartAssembly', false, vehicleNetId, partName)

    if not success then
        lib.notify({ title = 'Error', description = 'Material tidak mencukupi atau part tidak valid!', type = 'error' })
        return
    end

    local ped = PlayerPedId()
    RequestAnimDict('mini@repair')
    while not HasAnimDictLoaded('mini@repair') do Wait(100) end
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 1, 0, false, false, false)

    if lib.progressBar({
        duration = Config.AssemblySystem.progressDuration,
        label = 'Merakit ' .. string.upper(partName:gsub('_', ' ')),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        completedParts[partName] = true
        ClearPedTasks(ped)
        TriggerTokenEvent('vehicle_assembly:finishPart', vehicleNetId, partName)
        lib.notify({ title = 'Berhasil', description = 'Bagian ' .. string.upper(partName:gsub('_', ' ')) .. ' berhasil dirakit!', type = 'success' })
        CheckAssemblyCompletion()
    else
        ClearPedTasks(ped)
        TriggerTokenEvent('vehicle_assembly:cancelPart', vehicleNetId)
    end
end

local function ShowPartMaterials(partName, materials)
    local options = {}
    local hasAll = true

    for _, mat in ipairs(materials) do
        local has = exports.ox_inventory:Search('count', mat.item) >= mat.count
        if not has then hasAll = false end
        options[#options + 1] = {
            title = mat.item .. ' (' .. mat.count .. 'x)',
            description = has and '✅ Tersedia' or '❌ Tidak tersedia',
            icon = has and 'check' or 'times',
            disabled = true,
        }
    end

    if hasAll then
        options[#options + 1] = {
            title = 'Mulai Inspeksi',
            description = 'Mulai proses perakitan bagian ini',
            icon = 'play',
            onSelect = function()
                ClearPedTasks(PlayerPedId())
                StartPartAssembly(partName)
            end,
        }
    end

    lib.registerContext({
        id = 'part_materials_' .. partName,
        title = 'Material: ' .. string.upper(partName:gsub('_', ' ')),
        menu = 'assembly_menu',
        onExit = function() ClearPedTasks(PlayerPedId()) end,
        options = options,
    })
    lib.showContext('part_materials_' .. partName)
end

local function SetupVehicleInteractions()
    if not currentAssembly or not DoesEntityExist(currentVehicle) then return end

    vehicleInteracts = {}
    for partName, partMaterials in pairs(currentAssembly.data.materials) do
        local pos = GetVehiclePartPosition(currentVehicle, partName)
        if pos then
            vehicleInteracts[partName] = exports.rhd_interact:addCoords({
                coords = pos,
                options = {
                    {
                        label = 'Rakit ' .. string.upper(partName:gsub('_', ' ')),
                        icon = 'wrench',
                        distance = 2.0,
                        onSelect = function()
                            TaskStartScenarioInPlace(PlayerPedId(), Config.AssemblySystem.animationScenario, 0, true)
                            ShowPartMaterials(partName, partMaterials)
                        end,
                        canInteract = function(_, distance)
                            return not completedParts[partName] and currentAssembly ~= nil and cachedHasJob
                        end,
                    }
                }
            })
        end
    end
end

local function CancelAssembly()
    local alert = lib.alertDialog({
        header = 'Konfirmasi Pembatalan',
        content = 'Apakah Anda yakin ingin membatalkan perakitan? Material yang sudah digunakan akan dikembalikan.',
        centered = true,
        cancel = true,
    })
    if alert ~= 'confirm' then return end

    local netId = currentAssembly.vehicleNetId
    ClearInteracts()
    TriggerTokenEvent('vehicle_assembly:cancelAssembly', netId)
    currentVehicle = nil
    currentAssembly = nil
    completedParts = {}
end

function OpenAssemblyMenu()
    local options = {}

    if currentAssembly then
        options[#options + 1] = {
            title = 'BATALKAN PERAKITAN',
            description = 'Batalkan perakitan ' .. currentAssembly.data.name .. ' yang sedang berlangsung',
            icon = 'times',
            onSelect = CancelAssembly,
        }
        options[#options + 1] = { title = '', disabled = true }
    end

    for category, vehicles in pairs(Config.VehicleList) do
        for _, vehicle in ipairs(vehicles) do
            options[#options + 1] = {
                title = vehicle.name,
                description = 'Kategori: ' .. string.upper(category),
                icon = 'car',
                disabled = currentAssembly ~= nil,
                onSelect = function()
                    if currentAssembly then
                        lib.notify({ title = 'Error', description = 'Anda masih memiliki kendaraan yang sedang dirakit!', type = 'error' })
                        return
                    end
                    OpenVehicleDetailMenu(vehicle, category)
                end,
            }
        end
    end

    lib.registerContext({ id = 'assembly_menu', title = 'Pabrik Kendaraan', options = options })
    lib.showContext('assembly_menu')
end

function OpenVehicleDetailMenu(vehicleData, category)
    local totalMats = {}
    for _, materials in pairs(vehicleData.materials) do
        for _, mat in ipairs(materials) do
            totalMats[mat.item] = (totalMats[mat.item] or 0) + mat.count
        end
    end

    local options = {
        { title = 'INFORMASI KENDARAAN', disabled = true },
        { title = 'Nama: ' .. vehicleData.name, disabled = true },
        { title = 'Model: ' .. vehicleData.model, disabled = true },
        { title = 'Kategori: ' .. string.upper(category), disabled = true },
        { title = '', disabled = true },
        { title = 'TOTAL MATERIAL DIBUTUHKAN', disabled = true },
    }

    for item, count in pairs(totalMats) do
        options[#options + 1] = {
            title = item:sub(1, 1):upper() .. item:sub(2) .. ': ' .. count .. 'x',
            disabled = true,
        }
    end

    options[#options + 1] = { title = '', disabled = true }
    options[#options + 1] = {
        title = 'MULAI PERAKITAN',
        description = 'Mulai proses perakitan kendaraan',
        icon = 'play',
        onSelect = function()
            TriggerTokenEvent('vehicle_assembly:requestSpawn', vehicleData.model)
        end,
    }
    options[#options + 1] = {
        title = 'KEMBALI',
        icon = 'arrow-left',
        onSelect = OpenAssemblyMenu,
    }

    lib.registerContext({ id = 'vehicle_detail_menu', title = vehicleData.name .. ' - Detail', options = options })
    lib.showContext('vehicle_detail_menu')
end

CreateThread(function()
    exports.ox_target:addBoxZone({
        coords = Config.AssemblyLocation,
        name = 'vehicle_assembly',
        size = vector3(2, 2, 2),
        rotation = 0,
        debug = false,
        options = {{
            name = 'open_assembly_menu',
            event = 'vehicle_assembly:openMenu',
            icon = 'fas fa-car',
            label = 'Pabrik Kendaraan',
            canInteract = function() return cachedHasJob end,
        }},
    })
end)

RegisterNetEvent('vehicle_assembly:openMenu', function()
    local hasJob = lib.callback.await('vehicle_assembly:checkJob', false, 'assembly')
    if not hasJob then
        lib.notify({ title = 'Akses Ditolak', description = 'Anda tidak memiliki akses!', type = 'error' })
        return
    end
    OpenAssemblyMenu()
end)

RegisterNetEvent('vehicle_assembly:spawnResponse', function(success, spawnLocation, vehicleData, category, vehicleNetId)
    if not success then
        lib.notify({ title = 'Error', description = 'Tidak ada tempat kosong!', type = 'error' })
        return
    end

    currentAssembly = {
        vehicleNetId = vehicleNetId,
        data = vehicleData,
        category = category,
        location = spawnLocation,
        owner = GetPlayerServerId(PlayerId()),
    }
    completedParts = {}

    CreateThread(function()
        local vehicle = WaitForNetEntity(vehicleNetId, 15000)
        if vehicle then
            currentVehicle = vehicle
            Wait(2000)
            SetupVehicleInteractions()
        else
            lib.notify({ title = 'Error', description = 'Kendaraan gagal di-network!', type = 'error' })
        end
    end)
end)

RegisterNetEvent('vehicle_assembly:applyGhostProperties', function(vehicleNetId)
    CreateThread(function()
        local vehicle = WaitForNetEntity(vehicleNetId, 15000)
        if not vehicle then return end

        Wait(1000)
        ApplyGhostProps(vehicle)
        Wait(500)
        ApplyGhostProps(vehicle)

        if Config.GhostVehicle.showBlip then
            local blip = AddBlipForEntity(vehicle)
            SetBlipSprite(blip, 326)
            SetBlipColour(blip, 5)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('Kendaraan Sedang Dirakit')
            EndTextCommandSetBlipName(blip)

            activeAssemblies[vehicleNetId] = activeAssemblies[vehicleNetId] or {}
            activeAssemblies[vehicleNetId].blip = blip
        end
    end)
end)

RegisterNetEvent('vehicle_assembly:updatePartStatus', function(vehicleNetId, partName, completed)
    if currentAssembly and currentAssembly.vehicleNetId == vehicleNetId then
        completedParts[partName] = completed
    end
end)

RegisterNetEvent('vehicle_assembly:cleanupGhostVehicle', function(vehicleNetId)
    if activeAssemblies[vehicleNetId] and activeAssemblies[vehicleNetId].blip then
        RemoveBlip(activeAssemblies[vehicleNetId].blip)
    end

    ClearInteracts('_' .. tostring(vehicleNetId))
    activeAssemblies[vehicleNetId] = nil

    if currentAssembly and currentAssembly.vehicleNetId == vehicleNetId then
        currentVehicle = nil
        currentAssembly = nil
        completedParts = {}
        ClearInteracts()
    end
end)

RegisterNetEvent('vehicle_assembly:assemblyCompleted', function(vehicleNetId, vehicleName)
    activeAssemblies[vehicleNetId] = nil

    if currentAssembly and currentAssembly.vehicleNetId == vehicleNetId then
        currentVehicle = nil
        currentAssembly = nil
        completedParts = {}
        ClearInteracts()
    end

    lib.notify({ title = 'Pabrik Kendaraan', description = vehicleName .. ' telah selesai dirakit!', type = 'success' })
end)

RegisterNetEvent('vehicle_assembly:openSPKMenu', function(spkData, itemSlot, uniqueId)
    local canSPK = lib.callback.await('vehicle_assembly:checkJob', false, 'spk')
    if not canSPK then
        lib.notify({ title = 'Akses Ditolak', description = 'Anda tidak memiliki akses untuk menggunakan SPK!', type = 'error' })
        return
    end

    lib.registerContext({
        id = 'spk_menu',
        title = 'SPK Kendaraan',
        options = {
            {
                title = 'Data Kendaraan',
                description = 'Lihat informasi kendaraan',
                icon = 'info-circle',
                onSelect = function()
                    lib.registerContext({
                        id = 'vehicle_data',
                        title = 'Data Kendaraan',
                        menu = 'spk_menu',
                        options = {
                            { title = 'ID Kendaraan: ' .. spkData.vehicleId, disabled = true },
                            { title = 'Nama Pembuat: ' .. spkData.creatorName, disabled = true },
                            { title = 'Citizen ID: ' .. spkData.creatorCid, disabled = true },
                            { title = 'Tanggal Dibuat: ' .. spkData.createdDate, disabled = true },
                            { title = 'Model: ' .. spkData.vehicleName, disabled = true },
                        },
                    })
                    lib.showContext('vehicle_data')
                end,
            },
            {
                title = 'Transfer Kendaraan',
                description = 'Transfer kendaraan ke player lain',
                icon = 'exchange-alt',
                onSelect = function()
                    TaskStartScenarioInPlace(PlayerPedId(), Config.AssemblySystem.animationScenario, 0, true)
                    local input = lib.inputDialog('Transfer Kendaraan', {
                        { type = 'number', label = 'Player ID', description = 'Masukkan ID player tujuan', required = true, min = 1 },
                    })
                    ClearPedTasks(PlayerPedId())
                    if not input then return end

                    local targetId = tonumber(input[1])
                    local alert = lib.alertDialog({
                        header = 'Konfirmasi Transfer',
                        content = 'Transfer ' .. spkData.vehicleName .. ' ke Player ID: ' .. targetId .. '?',
                        centered = true,
                        cancel = true,
                    })
                    if alert == 'confirm' then
                        TriggerTokenEvent('vehicle_assembly:transferVehicle', targetId, uniqueId)
                    end
                end,
            },
        },
    })
    lib.showContext('spk_menu')
end)

local function EndTestDrive()
    if not testDriveActive then return end
    testDriveActive = false
    lib.hideTextUI()

    DoScreenFadeOut(500)
    Wait(500)

    ---@cast testDriveVehicle number

    if DoesEntityExist(testDriveVehicle) then
        DeleteVehicle(testDriveVehicle)
        testDriveVehicle = nil
    end

    ---@cast originalCoords vector3
    SetEntityCoords(PlayerPedId(), originalCoords.x, originalCoords.y, originalCoords.z)
    originalCoords = nil
    TriggerTokenEvent('vehicle_assembly:endTestDrive')

    Wait(500)
    DoScreenFadeIn(500)
    lib.notify({ title = 'Test Drive', description = 'Terima kasih telah test drive!', type = 'success' })
end

local function StartTestDrive(vehicleData)
    if testDriveActive then return end
    testDriveActive = true

    if not lib.callback.await('vehicle_assembly:startTestDrive', false) then
        testDriveActive = false
        lib.notify({ title = 'Test Drive', description = 'Test drive tidak tersedia', type = 'error' })
        return
    end

    local ped = PlayerPedId()
    originalCoords = GetEntityCoords(ped)

    lib.notify({ title = 'Test Drive', description = 'Mempersiapkan kendaraan ' .. vehicleData.name .. '...', type = 'inform' })
    DoScreenFadeOut(500)
    Wait(500)

    local td = Config.TestDrive.coords
    SetEntityCoords(ped, td.x, td.y, td.z)
    SetEntityHeading(ped, td.w)
    Wait(500)

    local hash = GetHashKey(vehicleData.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(100) end

    testDriveVehicle = CreateVehicle(hash, td.x, td.y, td.z, td.w, true, false)
    local prefix = Config.TestDrive.platePrefix or 'TEST'
    local randomNum = math.random(1000, 9999)
    local testPlate = (prefix .. randomNum):sub(1, 8)
    SetVehicleNumberPlateText(testDriveVehicle, testPlate)

    SetPedIntoVehicle(ped, testDriveVehicle, -1)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', testPlate)
    SetVehicleEngineOn(testDriveVehicle, true, true, false)
    SetVehicleFuelLevel(testDriveVehicle, 100.0)
    SetModelAsNoLongerNeeded(hash)

    DoScreenFadeIn(500)
    lib.notify({ title = 'Test Drive', description = 'Test drive dimulai! Tekan [E] untuk mengakhiri', type = 'success' })

    local timeLeft = Config.TestDrive.duration
    local lastTick = GetGameTimer()

    CreateThread(function()
        while timeLeft > 0 and testDriveActive do
            lib.showTextUI('Waktu tersisa: ' .. timeLeft .. ' detik | Tekan [E] untuk selesai', {
                position = 'top-center',
                icon = 'clock',
            })

            if IsControlJustPressed(0, 38) then
                EndTestDrive()
                return
            end

            if GetGameTimer() - lastTick >= 1000 then
                timeLeft = timeLeft - 1
                lastTick = GetGameTimer()
            end

            Wait(0)
        end

        if testDriveActive then EndTestDrive() end
    end)
end


CreateThread(function()
    local model = Config.TestDrive.npcModel
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(500) end

    local coords = Config.TestDrive.npcCoords
    local npc = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    TaskStartScenarioInPlace(npc, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    exports.ox_target:addLocalEntity(npc, {{
        name = 'test_drive_npc',
        icon = 'fas fa-car',
        label = 'Test Drive Kendaraan',
        onSelect = function()
            if testDriveActive then
                lib.notify({ title = 'Test Drive', description = 'Anda sedang test drive!', type = 'error' })
                return
            end

            local options = {}
            for category, vehicles in pairs(Config.VehicleList) do
                options[#options + 1] = { title = '━━━ ' .. string.upper(category) .. ' ━━━', disabled = true }
                for _, vehicle in ipairs(vehicles) do
                    options[#options + 1] = {
                        title = vehicle.name,
                        description = 'Model: ' .. vehicle.model,
                        icon = 'car',
                        onSelect = function() StartTestDrive(vehicle) end,
                    }
                end
            end

            lib.registerContext({ id = 'test_drive_menu', title = 'Test Drive Kendaraan', options = options })
            lib.showContext('test_drive_menu')
        end,
        canInteract = function() return not testDriveActive end,
    }})
end)


AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    ClearInteracts()
    exports.ox_target:removeZone('vehicle_assembly')

    if currentAssembly then
        TriggerTokenEvent('vehicle_assembly:playerDisconnected', currentAssembly.vehicleNetId)
    end

    if testDriveActive then
        lib.hideTextUI()
        if DoesEntityExist(testDriveVehicle) then DeleteVehicle(testDriveVehicle) end
        if originalCoords then
            SetEntityCoords(PlayerPedId(), originalCoords.x, originalCoords.y, originalCoords.z)
        end
    end
end)