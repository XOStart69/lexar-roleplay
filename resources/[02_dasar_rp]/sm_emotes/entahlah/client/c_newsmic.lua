-- ============================================
-- NEWS MICROPHONE SYSTEM
-- ============================================

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables untuk tracking state
local newsmic_net
local newsbmic_net

-- Models dan animasi - News Microphone
local newsmicModel = "p_ing_microphonel_01"
local newsmicanimDict = "anim@heists@humane_labs@finale@keycards"
local newsmicanimName = "ped_a_enter_loop"

-- Models dan animasi - Boom Microphone
local newsbmicModel = "prop_v_bmike_01"
local newsbmicanimDict = "missfra1"
local newsbmicanimName = "mcs2_crew_idle_m_boom"

-- ============================================
-- FUNCTIONS
-- ============================================

-- Toggle News Microphone
local function ToggleNewsmic()
    local holdingNewsmic = PState.isUsingNewsmic or false
    local holdingNewsbmic = PState.isUsingNewsbmic or false

    if not holdingNewsmic then
        if holdingNewsbmic then
            QBCore.Functions.Notify("You are already holding boom microphone!", "error")
            return
        end

        -- Load model
        RequestModel(GetHashKey(newsmicModel))
        while not HasModelLoaded(GetHashKey(newsmicModel)) do
            Wait(100)
        end

        -- Load animation
        RequestAnimDict(newsmicanimDict)
        while not HasAnimDictLoaded(newsmicanimDict) do
            Wait(100)
        end

        -- Create and setup object
        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local newsmicspawned = CreateObject(GetHashKey(newsmicModel), plyCoords.x, plyCoords.y, plyCoords.z, true, true, false)
        Wait(1000)

        local netid = ObjToNet(newsmicspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)

        -- Attach to hand
        AttachEntityToEntity(
            newsmicspawned,
            GetPlayerPed(PlayerId()),
            GetPedBoneIndex(GetPlayerPed(PlayerId()), 4154),
            -0.00, -0.0200, 0.1100,
            0.00, 0.0, 60.0,
            true, true, false, true, 0, true
        )

        -- Play animation
        TaskPlayAnim(GetPlayerPed(PlayerId()), newsmicanimDict, newsmicanimName, 1.0, -1, -1, 50, 0, false, false, false)

        newsmic_net = netid
        PState:set('isUsingNewsmic', true, true)

        lib.showTextUI('News Microphone | Cancel [X]', {
            position = "top-center",
            icon = 'microphone',
        })

        QBCore.Functions.Notify("You are now using news microphone", "success")
    else
        -- Cleanup
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(newsmic_net), true, true)
        DeleteEntity(NetToObj(newsmic_net))
        newsmic_net = nil
        PState:set('isUsingNewsmic', false, true)
        lib.hideTextUI()
        QBCore.Functions.Notify("News microphone cancelled", "error")
    end
end

-- Toggle Boom Microphone
local function ToggleNewsbmic()
    local holdingNewsmic = PState.isUsingNewsmic or false
    local holdingNewsbmic = PState.isUsingNewsbmic or false

    if not holdingNewsbmic then
        if holdingNewsmic then
            QBCore.Functions.Notify("You are already holding news microphone!", "error")
            return
        end

        -- Load model
        RequestModel(GetHashKey(newsbmicModel))
        while not HasModelLoaded(GetHashKey(newsbmicModel)) do
            Wait(100)
        end

        -- Load animation
        RequestAnimDict(newsbmicanimDict)
        while not HasAnimDictLoaded(newsbmicanimDict) do
            Wait(100)
        end

        -- Create and setup object
        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local newsbmicspawned = CreateObject(GetHashKey(newsbmicModel), plyCoords.x, plyCoords.y, plyCoords.z, true, true, false)
        Wait(1000)

        local netid = ObjToNet(newsbmicspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)

        -- Attach to hand
        AttachEntityToEntity(
            newsbmicspawned,
            GetPlayerPed(PlayerId()),
            GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422),
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            true, true, false, true, 0, true
        )

        -- Play animation
        TaskPlayAnim(GetPlayerPed(PlayerId()), newsbmicanimDict, newsbmicanimName, 1.0, -1, -1, 50, 0, false, false, false)

        newsbmic_net = netid
        PState:set('isUsingNewsbmic', true, true)

        lib.showTextUI('Boom Microphone | Cancel [X]', {
            position = "top-center",
            icon = 'microphone',
        })

        QBCore.Functions.Notify("You are now using boom microphone", "success")
    else
        -- Cleanup
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(newsbmic_net), true, true)
        DeleteEntity(NetToObj(newsbmic_net))
        newsbmic_net = nil
        PState:set('isUsingNewsbmic', false, true)
        lib.hideTextUI()
        QBCore.Functions.Notify("Boom microphone cancelled", "error")
    end
end

-- ============================================
-- EVENTS
-- ============================================

RegisterNetEvent("newsmic:client:use", function()
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    ToggleNewsmic()
end)

RegisterNetEvent("newsbmic:client:use", function()
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    ToggleNewsbmic()
end)

-- ============================================
-- THREADS
-- ============================================

-- News Microphone Animation & Controls
CreateThread(function()
    while true do
        local holdingNewsmic = PState.isUsingNewsmic or false
        if holdingNewsmic then
            if not IsEntityPlayingAnim(PlayerPedId(), newsmicanimDict, newsmicanimName, 3) then
                TaskPlayAnim(PlayerPedId(), newsmicanimDict, newsmicanimName, 1.0, -1, -1, 50, 0, false, false, false)
            end

            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 37, true) -- Select weapon
            SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)

            if IsControlJustPressed(0, 73) then
                ToggleNewsmic()
            end

            if IsPedInAnyVehicle(PlayerPedId(), false) or QBCore.Functions.GetPlayerData().metadata["ishandcuffed"] then
                ToggleNewsmic()
            end

            Wait(7)
        else
            Wait(100)
        end
    end
end)

-- Boom Microphone Animation & Controls
CreateThread(function()
    while true do
        local holdingNewsbmic = PState.isUsingNewsbmic or false
        if holdingNewsbmic then
            if not IsEntityPlayingAnim(PlayerPedId(), newsbmicanimDict, newsbmicanimName, 3) then
                TaskPlayAnim(PlayerPedId(), newsbmicanimDict, newsbmicanimName, 1.0, -1, -1, 50, 0, false, false, false)
            end

            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 44, true) -- Cover
            DisableControlAction(0, 37, true) -- Select weapon
            SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)

            if IsControlJustPressed(0, 73) then
                ToggleNewsbmic()
            end

            if IsPedInAnyVehicle(PlayerPedId(), false) or QBCore.Functions.GetPlayerData().metadata["ishandcuffed"] then
                ToggleNewsbmic()
            end

            Wait(7)
        else
            Wait(100)
        end
    end
end)

-- ============================================
-- CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local holdingNewsmic = PState.isUsingNewsmic or false
        local holdingNewsbmic = PState.isUsingNewsbmic or false

        if holdingNewsmic then
            ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
            DetachEntity(NetToObj(newsmic_net), true, true)
            DeleteEntity(NetToObj(newsmic_net))
            lib.hideTextUI()
        end
        if holdingNewsbmic then
            ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
            DetachEntity(NetToObj(newsbmic_net), true, true)
            DeleteEntity(NetToObj(newsbmic_net))
            lib.hideTextUI()
        end
    end
end)