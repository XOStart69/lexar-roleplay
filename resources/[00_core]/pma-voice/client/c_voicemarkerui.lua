local voiceModes = {}
local proximityRangeTimeout = 0
local proximityRangeMarkerReachTimeOut = false

-- Fungsi menggambar marker dengan animasi dan warna biru
local function DrawMarkerForProximityRange(proximityRange)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- Adjust Z position based on whether player is in vehicle
    local zOffset = -1.0
    if vehicle ~= 0 then
        -- Player is in vehicle - raise marker higher
        local vehicleModel = GetEntityModel(vehicle)
        local minDim, maxDim = GetModelDimensions(vehicleModel)
        zOffset = minDim.z + 0.5 -- Use vehicle's bottom dimension minus small offset
    end
    
    DrawMarker(
        1, -- Marker Type: Cylinder
        coords.x, coords.y, coords.z + zOffset,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        proximityRange * 2.0, proximityRange * 2.0, 0.5,
        0, 191, 255, 150, -- Deep Sky Blue
        true, -- bobUpAndDown
        true, -- faceCamera
        2, -- p19
        false, -- rotate
        nil, nil, false
    )
end

local function CreateProximityRangeTimeout()
    proximityRangeTimeout = 2
    Citizen.CreateThread(function()
        repeat
            Wait(1000)
            proximityRangeTimeout -= 1
        until (proximityRangeTimeout <= 0)
        proximityRangeMarkerReachTimeOut = true
        Wait(1)
        proximityRangeMarkerReachTimeOut = false
    end)
end

local function CreateProximityRange(proximityRange)
    proximityRangeMarkerReachTimeOut = true
    Wait(1)
    proximityRangeMarkerReachTimeOut = false

    if proximityRangeTimeout <= 0 then
        CreateProximityRangeTimeout()
    end
    proximityRangeTimeout = 2

    Citizen.CreateThread(function()
        while not proximityRangeMarkerReachTimeOut do
            Wait(0)
            DrawMarkerForProximityRange(proximityRange)
        end
    end)
end

-- Inisialisasi voiceModes dengan retry
Citizen.CreateThread(function()
    local attempts = 0
    while #voiceModes == 0 and attempts < 10 do
        TriggerEvent("pma-voice:settingsCallback", function(voiceSettings)
            voiceModes = voiceSettings.voiceModes or {}
        end)
        attempts += 1
        Wait(500)
    end

    if #voiceModes == 0 then
        print("[voicemarker] Gagal mengambil voiceModes dari pma-voice.")
    else
        print(string.format("[voicemarker] voiceModes berhasil diambil. Total: %d mode.", #voiceModes))
    end
end)

-- Event listener dari pma-voice
AddEventHandler('pma-voice:setTalkingMode', function(mode)
    if voiceModes and voiceModes[mode] and voiceModes[mode][1] then
        CreateProximityRange(voiceModes[mode][1])
    else
        print(string.format("[voicemarker] Invalid voice mode: %s", tostring(mode)))
    end
end)