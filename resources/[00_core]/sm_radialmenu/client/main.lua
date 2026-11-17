QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

-- Functions

local function convert(tbl)
    if tbl.items then
        local items = {}
        for _, v in pairs(tbl.items) do
            items[#items + 1] = convert(v)
        end
        lib.registerRadial({
            id = tbl.id .. '_menu',
            items = items
        })
        return { id = tbl.id, label = tbl.title or tbl.label, icon = tbl.icon, menu = tbl.id .. '_menu' }
    end
    local action
    if tbl.event then
        if tbl.type == 'client' then
            action = function() TriggerEvent(tbl.event, tbl.arg or nil) end
        elseif tbl.type == 'server' then
            action = function() TriggerServerEvent(tbl.event, tbl.arg or nil) end
        elseif tbl.type == 'command' then
            action = function() ExecuteCommand(tbl.event) end
        end
    elseif tbl.action then
        action = function() tbl.action(tbl.arg) end
    elseif tbl.command then
        action = function() ExecuteCommand(tbl.command .. " " .. tbl.arg) end
    end
    local onSelect = tbl.onSelect or function()
        if action then action() end
    end
    return { id = tbl.id, label = tbl.title or tbl.label, icon = tbl.icon, onSelect = onSelect, keepOpen = not tbl
    .shouldClose or false }
end

local function SetupVehicleMenu(vehicle)
    lib.removeRadialItem('vehicle-menu')
    lib.removeRadialItem('vehicle-flip')
    lib.removeRadialItem('give-keys')

    if cache.vehicle then
        lib.addRadialItem({
            id = 'vehicle-menu',
            label = 'Vehicle Menu',
            icon = 'gauge',
            onSelect = function()
                ExecuteCommand('vehmenu')
                lib.hideRadial()
            end,
        })
    end

    if not IsPedInAnyVehicle(PlayerPedId(), false) and vehicle ~= 0 then
        lib.addRadialItem({
            id = 'vehicle-flip',
            label = Lang:t("options.flip"),
            icon = 'car-burst',
            onSelect = function()
                TriggerEvent('radialmenu:flipveh')
                lib.hideRadial()
            end,
        })
    end

    lib.addRadialItem({
        id = 'give-keys',
        label = 'Give Keys',
        icon = 'key',
        onSelect = function()
            ExecuteCommand('givekeys')
            lib.hideRadial()
        end,
    })
end

local function IsDead()
    return PlayerData.metadata.inlaststand or PlayerData.metadata.isdead
end

---@param vehicle number|false
local function SetDriftItem(vehicle)
    if not vehicle then
        lib.removeRadialItem('driftmode')
        return
    end
    lib.addRadialItem({
        id = 'driftmode',
        label = 'Toggle Drift Mode',
        icon = 'car',
        onSelect = function()
            if cache.vehicle then exports.sm_resource:toggleDrift(cache.vehicle) end
        end,
    })
end

lib.onCache('vehicle', SetDriftItem)

RegisterNetEvent('qb-radialmenu:client:onRadialmenuOpen', function(data)
    if IsDead() then return end

    local vehicle, dist = QBCore.Functions.GetClosestVehicle()
    if vehicle and dist < 3.0 then
        SetupVehicleMenu(vehicle)
    else
        lib.removeRadialItem('vehicle-menu')
        lib.removeRadialItem('vehicle-flip')
        lib.removeRadialItem('give-keys')
    end
end)

-- MAIN FUNCTION: Setup semua radial menu dengan prioritas job interactions di depan
local function SetupRadialMenu()
    lib.clearRadialItems()
    
    -- 1. JOB INTERACTIONS PERTAMA (posisi paling depan)
    if PlayerData.job and PlayerData.job.onduty and Config.JobInteractions[PlayerData.job.name] then
        lib.addRadialItem(convert({
            id = 'jobinteractions',
            label = Lang:t("general.job_radial"),
            icon = 'briefcase',
            items = Config.JobInteractions[PlayerData.job.name]
        }))
    end
    
    -- 2. GANG INTERACTIONS KEDUA
    if PlayerData.gang and Config.GangInteractions[PlayerData.gang.name] and next(Config.GangInteractions[PlayerData.gang.name]) then
        lib.addRadialItem(convert({
            id = 'ganginteractions',
            label = Lang:t("general.gang_radial"),
            icon = 'skull-crossbones',
            items = Config.GangInteractions[PlayerData.gang.name]
        }))
    end
    
    -- 3. MENU ITEMS REGULER TERAKHIR
    for _, v in pairs(Config.MenuItems) do
        lib.addRadialItem(convert(v))
    end

    SetDriftItem(cache.vehicle)
end

local function IsPolice()
    return PlayerData.job.type == "leo" and PlayerData.job.onduty
end

local function IsEMS()
    return PlayerData.job.type == "medic" and PlayerData.job.onduty
end

-- Events
RegisterNetEvent('radialmenu:client:deadradial', function(isDead)
    if isDead then
        local ispolice, isems = IsPolice(), IsEMS()
        if not ispolice or isems then return lib.disableRadial(true) end
        lib.clearRadialItems()
        lib.addRadialItem({
            id = 'emergencybutton2',
            label = Lang:t("options.emergency_button"),
            icon = 'circle-exclamation',
            onSelect = function()
                if ispolice then
                    exports['ps-dispatch']:OfficerDown()
                elseif isems then
                    exports['ps-dispatch']:EmsDown()
                end
                lib.hideRadial()
            end
        })
    else
        lib.clearRadialItems()
        SetupRadialMenu()
        lib.disableRadial(false)
    end
end)

RegisterNetEvent('radialmenu:client:ChangeSeat', function(id, label)
    local Veh = cache.vehicle
    local IsSeatFree = IsVehicleSeatFree(Veh, id - 2)
    local speed = GetEntitySpeed(Veh)

    if not IsSeatFree then
        return QBCore.Functions.Notify(Lang:t("error.seat_occupied"), 'error')
    end

    local kmh = speed * 3.6

    if kmh > 100.0 then
        return QBCore.Functions.Notify(Lang:t("error.vehicle_driving_fast"), 'error')
    end

    SetPedIntoVehicle(cache.ped, Veh, id - 2)
    QBCore.Functions.Notify(Lang:t("info.switched_seats", { seat = label }))
end)

RegisterNetEvent('qb-radialmenu:trunk:client:Door', function(plate, door, open)
    local veh = cache.vehicle
    if not veh then return end

    local pl = QBCore.Functions.GetPlate(veh)
    if pl ~= plate then return end

    if open then
        SetVehicleDoorOpen(veh, door, false, false)
    else
        SetVehicleDoorShut(veh, door, false)
    end
end)

RegisterNetEvent('qb-radialmenu:client:openDoor', function(id)
    local door = id
    local closestVehicle = cache.vehicle or QBCore.Functions.GetClosestVehicle(GetEntityCoords(cache.ped))
    if closestVehicle ~= 0 then
        if closestVehicle ~= cache.vehicle then
            local plate = QBCore.Functions.GetPlate(closestVehicle)
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', false, plate, door)
                else
                    SetVehicleDoorShut(closestVehicle, door, false)
                end
            else
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', true, plate, door)
                else
                    SetVehicleDoorOpen(closestVehicle, door, false, false)
                end
            end
        else
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                SetVehicleDoorShut(closestVehicle, door, false)
            else
                SetVehicleDoorOpen(closestVehicle, door, false, false)
            end
        end
    else
        QBCore.Functions.Notify(Lang:t("error.no_vehicle_found"), 'error', 2500)
    end
end)

RegisterNetEvent('radialmenu:client:setExtra', function(id)
    local extra = id
    local veh = cache.vehicle
    if veh ~= nil then
        if cache.seat == -1 then
            SetVehicleAutoRepairDisabled(veh, true) -- Forces Auto Repair off when Toggling Extra [GTA 5 Niche Issue]
            if DoesExtraExist(veh, extra) then
                if IsVehicleExtraTurnedOn(veh, extra) then
                    SetVehicleExtra(veh, extra, true)
                    QBCore.Functions.Notify(Lang:t("error.extra_deactivated", { extra = extra }), 'error', 2500)
                else
                    SetVehicleExtra(veh, extra, false)
                    QBCore.Functions.Notify(Lang:t("success.extra_activated", { extra = extra }), 'success', 2500)
                end
            else
                QBCore.Functions.Notify(Lang:t("error.extra_not_present", { extra = extra }), 'error', 2500)
            end
        else
            QBCore.Functions.Notify(Lang:t("error.not_driver"), 'error', 2500)
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        SetupRadialMenu()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        lib.clearRadialItems()
    end
end)

-- Sets the metadata when the player spawns
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    SetupRadialMenu()
end)

-- Sets the playerdata to an empty table when the player has quit or did /logout
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

-- This will update all the PlayerData that doesn't get updated with a specific event other than this like the metadata
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- FIXED EVENT HANDLERS: Cuma panggil SetupRadialMenu() aja, jangan tambah manual lagi
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
    SetupRadialMenu() -- Ini udah handle semua, termasuk job interactions di posisi depan
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(onduty)
    PlayerData.job.onduty = onduty
    SetupRadialMenu() -- Ini udah handle semua, termasuk job interactions di posisi depan
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerData.gang = gang
    SetupRadialMenu() -- Ini udah handle semua, termasuk gang interactions di posisi depan
end)

exports('AddOption', function(data, id)
    data.id = data.id or id and id
    lib.addRadialItem(convert(data))
    return data.id
end)

exports('RemoveOption', function(id)
    lib.removeRadialItem(id)
end)

-- Backwards Compatibility --
function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_qb-radialmenu_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
    AddEventHandler(('__cfx_export_qbx_radialmenu_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

exportHandler('AddOption', function(data, id)
    data.id = data.id or id and id
    lib.addRadialItem(convert(data))
    return data.id
end)

exportHandler('RemoveOption', function(id)
    lib.removeRadialItem(id)
end)

RegisterNetEvent('qb-radialmenu:OfficerInDistress', function()
    exports['ps-dispatch']:OfficerInDistress()
end)

RegisterNetEvent('qb-radialmenu:OfficerBackup', function()
    exports['ps-dispatch']:OfficerBackup()
end)

--emotemenumoods

AddEventHandler("expressions:angry", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_angry_1", 0)
end)
AddEventHandler("expressions:drunk", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_drunk_1", 0)
end)
AddEventHandler("expressions:dumb", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "pose_injured_1", 0)
end)
AddEventHandler("expressions:grumpy", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_drivefast_1", 0)
end)
AddEventHandler("expressions:electrocuted", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "electrocuted_1", 0)
end)

AddEventHandler("expressions:happy", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_happy_1", 0)
end)
AddEventHandler("expressions:injured", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_injured_1", 0)
end)
AddEventHandler("expressions:joyful", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_dancing_low_1", 0)
end)
AddEventHandler("expressions:mouthbreather", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "smoking_hold_1", 0)
end)

AddEventHandler("expressions:oneeye", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "pose_aiming_1", 0)
end)

AddEventHandler("expressions:shocked", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "shocked_1", 0)
end)
AddEventHandler("expressions:sleeping", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "dead_1", 0)
end)
AddEventHandler("expressions:smug", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_smug_1", 0)
end)
AddEventHandler("expressions:speculative", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_aiming_1", 0)
end)

AddEventHandler("expressions:stressed", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_stressed_1", 0)
end)
AddEventHandler("expressions:sulking", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "mood_sulk_1", 0)
end)
AddEventHandler("expressions:weird", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "effort_2", 0)
end)
AddEventHandler("expressions:weird2", function()
    SetFacialIdleAnimOverride(PlayerPedId(), "effort_3", 0)
end)

AddEventHandler("expressions:clear",function() 
    ClearFacialIdleAnimOverride(PlayerPedId()) 
end)

RegisterNetEvent('axon:openPhone')
AddEventHandler('axon:openPhone', function()
    SetTimeout(200, function()
        -- Panggil export TogglePhone pada ox_inventory jika tersedia
        if exports['ox_inventory'] and exports['ox_inventory'].TogglePhone then
            local ok = exports['ox_inventory']:TogglePhone(nil, nil)
            if not ok then
                -- optional feedback: already handled by inventory but you can add something
                -- lib.notify({ title = 'PHONE', description = 'Cannot open phone.', type = 'error' })
            end
            return
        end

        -- Jika export tidak tersedia, coba useItem/useSlot. Tapi HENTIKAN jika mereka tidak menemukan slot
        local slotId
        local ok, res = pcall(function()
            if exports['ox_inventory'] and exports['ox_inventory'].GetSlotIdWithItem then
                return exports['ox_inventory']:GetSlotIdWithItem('phone', nil, false)
            end
            return nil
        end)
        if ok and res then slotId = res end

        if slotId then
            if exports['ox_inventory'] and exports['ox_inventory'].useSlot then
                local success = exports['ox_inventory']:useSlot(slotId)
                -- useSlot sendiri harus menolak bila durability 0
                return
            end
        else
            -- Jika tidak ada slot, jangan panggil TriggerEvent fallback yang membuka phone tanpa slot
            -- Sebagai gantinya beri notifikasi
            lib.notify({ title = 'PHONE', description = 'No phone found in inventory.', type = 'error' })
            return
        end
    end)
end)

RegisterNetEvent("radialmenu:flipveh", function()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = nil
    
    -- Check if player is in vehicle or get closest vehicle
    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    else
        vehicle = lib.getClosestVehicle(coords, 6.0, false)
    end
    
    -- Check if vehicle exists
    if not vehicle or not DoesEntityExist(vehicle) then
        return QBCore.Functions.Notify("Tidak ada kendaraan terdekat", 'error')
    end
    
    -- Check distance
    local vehicleCoords = GetEntityCoords(vehicle)
    if #(coords - vehicleCoords) > 6.0 then
        return QBCore.Functions.Notify("Tidak ada kendaraan terdekat", 'error')
    end
    
    -- Check if vehicle is actually flipped (not on all wheels)
    if IsVehicleOnAllWheels(vehicle) then
        return QBCore.Functions.Notify("Kendaraan sudah dalam posisi normal", 'error')
    end
    
    -- Load animation
    local animDict = 'random@mugging4'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    -- Play animation
    TaskPlayAnim(ped, animDict, 'struggle_loop_b_thief', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
    
    -- Progress bar
    if lib.progressBar({
        label = "Membalikkan kendaraan",
        duration = 10000,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        },
    }) then
        -- Success - flip the vehicle
        local carRotation = GetEntityRotation(vehicle, 2)
        SetEntityRotation(vehicle, carRotation[1], 0, carRotation[3], 2, true)
        SetVehicleOnGroundProperly(vehicle)
        
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Berhasil membalikkan kendaraan", 'success')
    else
        -- Cancelled
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Dibatalkan", 'error')
    end
end)

RegisterNetEvent('radialmenu:client:forceUnlockVehicle', function()
    local ped = PlayerPedId()
    local vehicle = nil
    
    -- Cek apakah player di dalam kendaraan
    if IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
    else
        -- Cek kendaraan terdekat
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
    end
    
    -- Validasi vehicle
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify("Tidak ada kendaraan di sekitar!", "error", 3000)
        return
    end
    
    -- Cek jarak (untuk safety)
    local playerCoords = GetEntityCoords(ped)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)
    
    if distance > 3.0 then
        QBCore.Functions.Notify("Kamu terlalu jauh dari kendaraan!", "error", 3000)
        return
    end
    
    -- Cek apakah kendaraan terkunci
    if GetVehicleDoorLockStatus(vehicle) == 1 then
        QBCore.Functions.Notify("Kendaraan sudah tidak terkunci!", "error", 3000)
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_WELDING", 0, true)
    
    QBCore.Functions.Progressbar("unlocking_vehicle", "Membobol Kendaraan...", 8000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        -- Success
        ClearPedTasks(ped)
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        -- TriggerServerEvent('sm_vehiclekeys:server:AcquireVehicleKeys', plate)
        QBCore.Functions.Notify("Kendaraan berhasil dibobol", "success", 3000)
    end, function()
        -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Pembobolan dibatalkan!", "error", 3000)
    end)
end)

RegisterNetEvent('radialmenu:client:JoinRadio', function(data)
    local channel = type(data) == "table" and data.arg or data
    
    if not channel then
        QBCore.Functions.Notify("Channel radio tidak valid!", "error")
        return
    end
    
    local hasRadio = false
    
    if exports.ox_inventory then
        local items = exports.ox_inventory:Search('count', 'radio')
        if items and items > 0 then
            hasRadio = true
        end
    end
    
    if not hasRadio then
        QBCore.Functions.Notify("Kamu tidak memiliki radio!", "error")
        return
    end
    
    exports["mm_radio"]:JoinRadio(channel)
    QBCore.Functions.Notify("Bergabung ke radio channel " .. channel, "success")
end)

RegisterNetEvent('radialmenu:client:openmdt', function(data)
    local count = exports.ox_inventory:Search('count', 'pol_mdt')

    if not count or count < 1 then
        QBCore.Functions.Notify("Kamu tidak memiliki MDT Police!", "error")
        return
    end

    TriggerServerEvent('sm_nui_browser:openMdt', 'pol_mdt')
end)