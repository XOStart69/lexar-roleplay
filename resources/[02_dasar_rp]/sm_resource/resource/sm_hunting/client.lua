local isworking = false

local config = localmodule 'config.shared'
local blipModule = require 'modules.blipHandle.client'

local zone = config.zone
local processing = config.processing
local animals = config.animals

local State = {
    hasHuntingRifle = false,
    blockShotActive = false,
    huntingZoneBlip = nil,
    playerInZone = false,
    animals = {},
    animalCooldown = {}
}

local AllowedWeapons = {
    [GetHashKey("WEAPON_SNIPERRIFLE")] = true
}

local function LoadModel(model)
    if type(model) == 'string' then model = GetHashKey(model) end
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasModelLoaded(model)
end

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(5)
    end
    return HasAnimDictLoaded(dict)
end

local function LoadParticle(pack)
    if HasNamedPtfxAssetLoaded(pack) then
        SetPtfxAssetNextCall(pack)
        return true
    end
    RequestNamedPtfxAsset(pack)
    local timeout = GetGameTimer() + 5000
    while not HasNamedPtfxAssetLoaded(pack) and GetGameTimer() < timeout do
        Wait(1)
    end
    if HasNamedPtfxAssetLoaded(pack) then
        SetPtfxAssetNextCall(pack)
        return true
    end
    return false
end

local function IsAggressiveAnimal(model)
    for _, animal in pairs(animals) do
        if animal.model == model and animal.aggressive then
            return true
        end
    end
    return false
end

local function GetRandomAnimalModel()
    local available = {}
    for _, animal in pairs(animals) do
        table.insert(available, animal.model)
    end
    return available[math.random(#available)]
end

if config.blockShootingPlayers then
    local function BlockShooting()
        if State.blockShotActive then return end
        State.blockShotActive = true
        CreateThread(function()
            while State.hasHuntingRifle do
                local _, entity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
                local freeAiming = IsPlayerFreeAiming(cache.playerId)
                local shouldBlock = false

                if not freeAiming then
                    shouldBlock = true
                elseif entity and DoesEntityExist(entity) then
                    local entityType = GetEntityType(entity)
                    if IsPedAPlayer(entity) then
                        shouldBlock = true
                    elseif entityType == 2 then
                        shouldBlock = true
                    elseif entityType == 1 and IsPedInAnyVehicle(entity, false) then
                        shouldBlock = true
                    elseif entityType == 1 then
                        local model = GetEntityModel(entity)
                        local isValid = false
                        for _, animal in pairs(animals) do
                            if GetHashKey(animal.model) == model then
                                isValid = true
                                break
                            end
                        end
                        if not isValid then shouldBlock = true end
                    end
                else
                    shouldBlock = true
                end

                if shouldBlock then
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 257, true)
                    DisablePlayerFiring(cache.ped, true)
                end
                Wait(1)
            end
            State.blockShotActive = false
        end)
    end

    CreateThread(function()
        while true do
            local currentWeapon = GetSelectedPedWeapon(cache.ped)
            local huntingRifleHash = GetHashKey(config.huntingRifle)
            if currentWeapon == huntingRifleHash then
                if not State.hasHuntingRifle then
                    State.hasHuntingRifle = true
                    BlockShooting()
                end
            else
                State.hasHuntingRifle = false
            end
            Wait(100)
        end
    end)
end

local function CarryAnimal(entity, animalIndex)
    if isworking then return end
    if not DoesEntityExist(entity) or not IsEntityDead(entity) then return end

    if config.killerNeededToSkin and GetPedSourceOfDeath(entity) ~= cache.ped then
        lib.notify({ title = "Hunting", description = "Anda harus membunuh hewan ini sendiri!", type = "error" })
        return
    end

    if not LoadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") then return end

    isworking = true
    TaskPlayAnim(cache.ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, 8.0, -1, 1, 0, false, false, false)

    local success = lib.progressCircle({
        duration = 5000,
        position = "bottom",
        label = "Mengangkat hewan...",
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
    })

    ClearPedTasks(cache.ped)

    if not success then
        isworking = false
        lib.notify({ title = "Hunting", description = "Dibatalkan!", type = "error" })
        return
    end

    if DoesEntityExist(entity) then
        if not NetworkHasControlOfEntity(entity) then
            NetworkRequestControlOfEntity(entity)
            local timeout = GetGameTimer() + 3000
            while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
                Wait(10)
            end
        end
        if NetworkHasControlOfEntity(entity) then
            DeleteEntity(entity)
        end
    end

    TriggerTokenEvent('sm_hunting:carryAnimal', animalIndex)
    isworking = false
end

local function ProcessAnimal()
    if isworking then return end

    if config.requireWeapon then
        local playerWeapon = GetSelectedPedWeapon(cache.ped)
        local neededWeaponHash = GetHashKey(config.processingWeapon)
        if playerWeapon ~= neededWeaponHash then
            lib.notify({ title = "Hunting", description = "Anda harus memegang kapak untuk memotong!", type = "error" })
            return
        end
    end

    isworking = true
    TriggerTokenEvent('sm_hunting:processAnimal')
end

RegisterNetEvent('sm_hunting:client:processResult', function(success, message, animalModel)
    if not success then
        isworking = false
        if message then
            lib.notify({ title = "Hunting", description = message, type = "error" })
        end
        return
    end

    local coords = processing.coords
    if not LoadModel(animalModel) then
        isworking = false
        return
    end

    local animalEntity = CreatePed(1, GetHashKey(animalModel), coords.x, coords.y, coords.z, processing.heading + 90, false, false)
    SetEntityInvincible(animalEntity, true)
    SetEntityHealth(animalEntity, 0)
    FreezeEntityPosition(animalEntity, true)

    local animalCoords = GetEntityCoords(animalEntity)
    local isAnimating = true

    CreateThread(function()
        TaskTurnPedToFaceEntity(cache.ped, animalEntity, -1)
        if not LoadAnimDict("melee@hatchet@streamed_core") then
            isAnimating = false
            return
        end
        while isAnimating do
            TaskPlayAnim(cache.ped, "melee@hatchet@streamed_core", "plyr_front_takedown_b", -3.0, 3.0, -1, 49, 0, 0, 0, 0)
            Wait(700)
            if LoadParticle("core") then
                StartParticleFxLoopedAtCoord("blood_stab", animalCoords.x, animalCoords.y, animalCoords.z - 0.25, 0.0, 0.0, 0.0, 2.5, false, false, false, false)
            end
            Wait(1000)
        end
    end)

    lib.progressCircle({
        duration = config.processingTime,
        useWhileDead = false,
        canCancel = false,
        disable = { move = true }
    })

    isAnimating = false
    StopAnimTask(cache.ped, "melee@hatchet@streamed_core", "plyr_front_takedown_b", 1.5)
    if DoesEntityExist(animalEntity) then DeleteEntity(animalEntity) end

    TriggerTokenEvent('sm_hunting:completeProcessing')
    isworking = false
end)

lib.onCache('weapon', function(weapon)
    if State.playerInZone and weapon and not AllowedWeapons[weapon] then
        SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
        RemoveWeaponFromPed(PlayerPedId(), weapon)
        lib.notify({ title = 'Hunting Zone', description = 'Anda hanya boleh menggunakan Sniper Rifle!', type = 'error' })
    end
end)

local function SpawnAnimal()
    if #State.animals >= zone.maxAnimals then return end

    local randomAnimal = GetRandomAnimalModel()
    if State.animalCooldown[randomAnimal] and GetGameTimer() < State.animalCooldown[randomAnimal] then
        return
    end

    local spawnOffset = vec3(
        math.random(-zone.radius, zone.radius),
        math.random(-zone.radius, zone.radius),
        0.0
    )
    local spawnPos = zone.center + spawnOffset
    local _, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 100.0, true)

    if not LoadModel(randomAnimal) then return end

    local animal = CreatePed(28, GetHashKey(randomAnimal), spawnPos.x, spawnPos.y, groundZ, math.random(0, 360), false, true)
    if not DoesEntityExist(animal) then return end

    SetEntityAsMissionEntity(animal, true, true)
    SetPedRelationshipGroupHash(animal, `HUNTER_ANIMAL`)
    SetEntityHealth(animal, 500)
    TaskWanderStandard(animal, 10.0, 10)
    SetEntityOnlyDamagedByPlayer(animal, true)
    SetEntityProofs(animal, false, true, false, false, false, false, false, false)

    if IsAggressiveAnimal(randomAnimal) then
        SetPedCombatAttributes(animal, 5, true)
        SetPedCombatAbility(animal, 2)
        SetPedCombatMovement(animal, 2)
        SetPedCombatRange(animal, 2)
        CreateThread(function()
            Wait(1000)
            if DoesEntityExist(animal) then
                TaskCombatPed(animal, PlayerPedId(), 0, 16)
            end
        end)
    end

    local blip = AddBlipForEntity(animal)
    SetBlipSprite(blip, 141)
    SetBlipColour(blip, IsAggressiveAnimal(randomAnimal) and 1 or 2)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(IsAggressiveAnimal(randomAnimal) and "Dangerous Animal" or "Hunting Animal")
    EndTextCommandSetBlipName(blip)

    table.insert(State.animals, { entity = animal, blip = blip, model = randomAnimal })
    State.animalCooldown[randomAnimal] = GetGameTimer() + 30000
end

local function CleanupAnimals()
    for i = #State.animals, 1, -1 do
        local data = State.animals[i]
        if DoesEntityExist(data.entity) then
            RemoveBlip(data.blip)
            if NetworkHasControlOfEntity(data.entity) then
                DeleteEntity(data.entity)
            else
                NetworkRequestControlOfEntity(data.entity)
                CreateThread(function()
                    local timeout = GetGameTimer() + 5000
                    while not NetworkHasControlOfEntity(data.entity) and GetGameTimer() < timeout do
                        Wait(10)
                    end
                    if NetworkHasControlOfEntity(data.entity) then
                        DeleteEntity(data.entity)
                    end
                end)
            end
        end
        table.remove(State.animals, i)
    end
    State.animalCooldown = {}
end

local function KeepAnimalsInZone()
    CreateThread(function()
        while State.playerInZone do
            Wait(5000)
            for i = #State.animals, 1, -1 do
                local data = State.animals[i]
                if DoesEntityExist(data.entity) then
                    local animalPos = GetEntityCoords(data.entity)
                    if #(animalPos - zone.center) > zone.radius then
                        local newX = zone.center.x + math.random(-zone.radius / 2, zone.radius / 2)
                        local newY = zone.center.y + math.random(-zone.radius / 2, zone.radius / 2)
                        local _, groundZ = GetGroundZFor_3dCoord(newX, newY, zone.center.z + 100.0, true)
                        SetEntityCoords(data.entity, newX, newY, groundZ, false, false, false, true)
                        TaskWanderStandard(data.entity, 10.0, 10)
                    end
                else
                    RemoveBlip(data.blip)
                    table.remove(State.animals, i)
                end
            end
        end
    end)
end

local function StartAnimalSpawning()
    CreateThread(function()
        while State.playerInZone do
            if #State.animals < zone.maxAnimals then
                SpawnAnimal()
            end
            Wait(10000)
        end
    end)
end

CreateThread(function()
    Wait(1500)

    exports.ox_target:addBoxZone({
        coords = processing.coords,
        size = vec3(2.0, 2.0, 1.0),
        rotation = processing.heading,
        options = {
            {
                label = "Potong Hewan",
                icon = 'fas fa-cut',
                distance = 2.0,
                onSelect = ProcessAnimal,
                canInteract = function()
                    return not isworking
                end
            }
        }
    })

    State.huntingZoneBlip = AddBlipForRadius(zone.center.x, zone.center.y, zone.center.z, zone.radius)
    SetBlipHighDetail(State.huntingZoneBlip, true)
    SetBlipColour(State.huntingZoneBlip, 1)
    SetBlipAlpha(State.huntingZoneBlip, 80)

    for i, animal in pairs(animals) do
        exports.ox_target:addModel(animal.model, {
            {
                label = "Angkat Hewan",
                icon = 'fas fa-people-carry',
                distance = 2.5,
                onSelect = function(data)
                    CarryAnimal(data.entity, i)
                end,
                canInteract = function(entity)
                    return IsEntityDead(entity) and not isworking
                end
            }
        })
    end

    lib.zones.sphere({
        coords = zone.center,
        radius = zone.radius,
        onEnter = function()
            State.playerInZone = true
            lib.notify({ title = 'Hunting Zone', description = 'Selamat datang di Area Berburu!', type = 'success' })
            for _ = 1, zone.maxAnimals do
                SpawnAnimal()
            end
            KeepAnimalsInZone()
            StartAnimalSpawning()
        end,
        onExit = function()
            State.playerInZone = false
            lib.notify({ title = 'Zone Exit', description = 'Anda telah keluar dari Zona Perburuan.', type = 'error' })
            CleanupAnimals()
        end
    })

    if not config.blip then return end
    AddTextEntry("BLIP_CAT_" .. 31, "Hunting")
    for _, blipdata in pairs(config.blip) do
        blipModule:new(blipdata)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if State.huntingZoneBlip then RemoveBlip(State.huntingZoneBlip) end
    CleanupAnimals()
end)