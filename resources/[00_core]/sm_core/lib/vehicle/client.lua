local functions = {}

---@deprecated use qbx.spawnVehicle from modules/lib.lua
---@param model string|number
---@param cb? fun(vehicle: number)
---@param coords? vector4 player position if not specified
---@param isnetworked? boolean defaults to true
---@param teleportInto boolean teleport player to driver seat if true
function functions.SpawnVehicle(model, cb, coords, isnetworked, teleportInto)
    local playerCoords = GetEntityCoords(cache.ped)
    local combinedCoords = vec4(playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(cache.ped))
    coords = type(coords) == 'table' and vec4(coords.x, coords.y, coords.z, coords.w or combinedCoords.w) or coords or combinedCoords
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end

    isnetworked = isnetworked == nil or isnetworked
    lib.requestModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    local netid = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(netid, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(model)
    if teleportInto then TaskWarpPedIntoVehicle(cache.ped, veh, -1) end
    if cb then cb(veh) return end

    return veh, netid
end

function functions.GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end
    
    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    if GetIsVehiclePrimaryColourCustom(vehicle) then
        colorPrimary = {GetVehicleCustomPrimaryColour(vehicle)}
    end

    if GetIsVehicleSecondaryColourCustom(vehicle) then
        colorSecondary = {GetVehicleCustomSecondaryColour(vehicle)}
    end
    
    local hasCustomXenonColor, customXenonColorR, customXenonColorG, customXenonColorB = GetVehicleXenonLightsCustomColor(vehicle)
    local customXenonColor = nil
    if hasCustomXenonColor then
        customXenonColor = {customXenonColorR, customXenonColorG, customXenonColorB}
    end

    local paintTypePrimary, _, _ = GetVehicleModColor_1(vehicle)
    local paintTypeSecondary, _ = GetVehicleModColor_2(vehicle)

    local extras = {}
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId)
        end
    end

    local tireHealth = {}
    for i = 0, 3 do
        tireHealth[tostring(i)] = GetVehicleWheelHealth(vehicle, i)
    end

    local tireBurstState = {}
    for i = 0, 5 do
       tireBurstState[tostring(i)] = IsVehicleTyreBurst(vehicle, i, false)
    end

    local tireBurstCompletely = {}
    for i = 0, 5 do
        tireBurstCompletely[tostring(i)] = IsVehicleTyreBurst(vehicle, i, true)
    end

    local windowStatus = {}
    for i = 0, 7 do
        windowStatus[tostring(i)] = IsVehicleWindowIntact(vehicle, i) == 1
    end

    local doorStatus = {}
    for i = 0, 5 do
        doorStatus[tostring(i)] = IsVehicleDoorDamaged(vehicle, i) == 1
    end
    
    local deformation = nil
    if GetResourceState('VehicleDeformation') == 'started' then
        deformation = exports['VehicleDeformation']:GetVehicleDeformation(vehicle)
    end

    return {
        model = GetEntityModel(vehicle),
        doorStatus = doorStatus,
        windowStatus = windowStatus,
        tireHealth = tireHealth,
        tireBurstState = tireBurstState,
        tireBurstCompletely = tireBurstCompletely,
        plate = QBCore.Functions.GetPlate(vehicle),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        
        suspensionHeight = GetVehicleSuspensionHeight(vehicle),
        wheelSize = GetVehicleWheelSize(vehicle),
        wheelWidth = GetVehicleWheelWidth(vehicle),
        driftTyres = GetDriftTyresEnabled(vehicle),

        bodyHealth = math.floor(GetVehicleBodyHealth(vehicle)),
        engineHealth = math.floor(GetVehicleEngineHealth(vehicle)),
        tankHealth = math.floor(GetVehiclePetrolTankHealth(vehicle)),
        fuelLevel = math.floor(GetVehicleFuelLevel(vehicle)),
        dirtLevel = math.floor(GetVehicleDirtLevel(vehicle)),
        oilLevel = math.floor(GetVehicleOilLevel(vehicle)),

        deformation = deformation,
        
        color1 = colorPrimary,
        color2 = colorSecondary,

        paintTypePrimary = paintTypePrimary,
        paintTypeSecondary = paintTypeSecondary,

        dashboardColor = GetVehicleDashboardColour(vehicle),
        interiorColor = GetVehicleInteriorColour(vehicle),
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,

        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),

        xenonColor = GetVehicleXenonLightsColour(vehicle),
        customXenonColor = customXenonColor,

        neonEnabled = {IsVehicleNeonLightEnabled(vehicle, 0), IsVehicleNeonLightEnabled(vehicle, 1), IsVehicleNeonLightEnabled(vehicle, 2), IsVehicleNeonLightEnabled(vehicle, 3)},
        neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),

        extras = extras,
        tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),

        modSpoilers = GetVehicleMod(vehicle, 0),
        modFrontBumper = GetVehicleMod(vehicle, 1),
        modRearBumper = GetVehicleMod(vehicle, 2),
        modSideSkirt = GetVehicleMod(vehicle, 3),
        modExhaust = GetVehicleMod(vehicle, 4),
        modFrame = GetVehicleMod(vehicle, 5),
        modGrille = GetVehicleMod(vehicle, 6),
        modHood = GetVehicleMod(vehicle, 7),
        modFender = GetVehicleMod(vehicle, 8),
        modRightFender = GetVehicleMod(vehicle, 9),
        modRoof = GetVehicleMod(vehicle, 10),
        
        modEngine = GetVehicleMod(vehicle, 11),
        modBrakes = GetVehicleMod(vehicle, 12),
        modTransmission = GetVehicleMod(vehicle, 13),
        modHorns = GetVehicleMod(vehicle, 14),
        modSuspension = GetVehicleMod(vehicle, 15),
        modArmor = GetVehicleMod(vehicle, 16),

        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),

        modFrontWheels = GetVehicleMod(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),

        modPlateHolder = GetVehicleMod(vehicle, 25),
        modVanityPlate = GetVehicleMod(vehicle, 26),
        modTrimA = GetVehicleMod(vehicle, 27),
        modOrnaments = GetVehicleMod(vehicle, 28),
        modDashboard = GetVehicleMod(vehicle, 29),
        modDial = GetVehicleMod(vehicle, 30),
        modDoorSpeaker = GetVehicleMod(vehicle, 31),
        modSeats = GetVehicleMod(vehicle, 32),
        modSteeringWheel = GetVehicleMod(vehicle, 33),
        modShifterLeavers = GetVehicleMod(vehicle, 34),
        modAPlate = GetVehicleMod(vehicle, 35),
        modSpeakers = GetVehicleMod(vehicle, 36),
        modTrunk = GetVehicleMod(vehicle, 37),
        modHydrolic = GetVehicleMod(vehicle, 38),
        modEngineBlock = GetVehicleMod(vehicle, 39),
        modAirFilter = GetVehicleMod(vehicle, 40),
        modStruts = GetVehicleMod(vehicle, 41),
        modArchCover = GetVehicleMod(vehicle, 42),
        modAerials = GetVehicleMod(vehicle, 43),
        modTrimB = GetVehicleMod(vehicle, 44),
        modTank = GetVehicleMod(vehicle, 45),
        modLivery = GetVehicleLiveryCount(vehicle) > 0 and GetVehicleLivery(vehicle) or GetVehicleMod(vehicle, 48),
        liveryRoof = GetVehicleRoofLivery(vehicle),
        modKit49 = GetVehicleMod(vehicle, 49)
    }
end

function functions.SetVehicleProperties(vehicle, props)
    if DoesEntityExist(vehicle) then
        if props.extras then
            for id, enabled in pairs(props.extras) do
                if enabled then
                    SetVehicleExtra(vehicle, tonumber(id), 0)
                else
                    SetVehicleExtra(vehicle, tonumber(id), 1)
                end
            end
        end

        local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
        local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
        SetVehicleModKit(vehicle, 0)
        if props.plate ~= nil then
            SetVehicleNumberPlateText(vehicle, props.plate)
        end
        if props.plateIndex ~= nil then
            SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
        end
        if props.bodyHealth ~= nil then
            SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
        end
        if props.engineHealth ~= nil then
            SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
        end
        if props.tankHealth ~= nil then
            SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
        end
        if props.fuelLevel ~= nil then
            SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
        end
        if props.dirtLevel ~= nil then
            SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
        end
        if props.oilLevel ~= nil then
            SetVehicleOilLevel(vehicle, props.oilLevel + 0.0)
        end
        if props.color1 ~= nil then
            if type(props.color1) == "number" then
                SetVehicleColours(vehicle, props.color1, type(props.color2) == "number" and props.color2 or colorSecondary)
            else
                SetVehicleCustomPrimaryColour(vehicle, props.color1[1], props.color1[2], props.color1[3])
                if props.paintTypePrimary then
                    SetVehicleModColor_1(vehicle, props.paintTypePrimary, 0, props.pearlescentColor or pearlescentColor)
                end
            end
        end
        if props.color2 ~= nil then
            if type(props.color2) == "number" then
                SetVehicleColours(vehicle, type(props.color1) == "number" and props.color1 or colorPrimary, props.color2)
                if props.paintTypePrimary and type(props.color1) ~= "number" then
                    SetVehicleModColor_1(vehicle, props.paintTypePrimary, 0, props.pearlescentColor or pearlescentColor)
                end
            else
                SetVehicleCustomSecondaryColour(vehicle, props.color2[1], props.color2[2], props.color2[3])
                if props.paintTypeSecondary then
                    SetVehicleModColor_2(vehicle, props.paintTypeSecondary, 0)
                end
            end
        end
        if props.pearlescentColor ~= nil then
            SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
        end
        if props.interiorColor ~= nil then
            SetVehicleInteriorColor(vehicle, props.interiorColor)
        end
        if props.dashboardColor ~= nil then
            SetVehicleDashboardColour(vehicle, props.dashboardColor)
        end
        if props.wheelColor ~= nil then
            SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
        end
        if props.wheels ~= nil then
            SetVehicleWheelType(vehicle, props.wheels)
        end
        if props.tireHealth ~= nil then
            for wheelIndex, health in pairs(props.tireHealth) do
                SetVehicleWheelHealth(vehicle, wheelIndex, health)
            end
        end
        if props.tireBurstState ~= nil then
            for wheelIndex, burstState in pairs(props.tireBurstState) do
                if burstState then
                    SetVehicleTyreBurst(vehicle, tonumber(wheelIndex), false, 1000.0)
                end
            end
        end
        if props.tireBurstCompletely ~= nil then
            for wheelIndex, burstState in pairs(props.tireBurstCompletely) do
                if burstState then
                    SetVehicleTyreBurst(vehicle, tonumber(wheelIndex), true, 1000.0)
                end
            end
        end
        if props.windowTint ~= nil then
            SetVehicleWindowTint(vehicle, props.windowTint)
        end
        if props.windowStatus ~= nil then
            for windowIndex, smashWindow in pairs(props.windowStatus) do
                if not smashWindow then SmashVehicleWindow(vehicle, windowIndex) end
            end
        end
        if props.doorStatus ~= nil then
            for doorIndex, breakDoor in pairs(props.doorStatus) do
                if breakDoor then
                    SetVehicleDoorBroken(vehicle, tonumber(doorIndex), true)
                end
            end
        end
        if props.neonEnabled ~= nil then
            SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
            SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
            SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
            SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
        end
        if props.neonColor ~= nil then
            SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
        end
        if props.headlightColor ~= nil then
            SetVehicleHeadlightsColour(vehicle, props.headlightColor)
        end
        if props.interiorColor ~= nil then
            SetVehicleInteriorColour(vehicle, props.interiorColor)
        end
        if props.tyreSmokeColor ~= nil then
            SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
        end
        if props.modSpoilers ~= nil then
            SetVehicleMod(vehicle, 0, props.modSpoilers, false)
        end
        if props.modFrontBumper ~= nil then
            SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
        end
        if props.modRearBumper ~= nil then
            SetVehicleMod(vehicle, 2, props.modRearBumper, false)
        end
        if props.modSideSkirt ~= nil then
            SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
        end
        if props.modExhaust ~= nil then
            SetVehicleMod(vehicle, 4, props.modExhaust, false)
        end
        if props.modFrame ~= nil then
            SetVehicleMod(vehicle, 5, props.modFrame, false)
        end
        if props.modGrille ~= nil then
            SetVehicleMod(vehicle, 6, props.modGrille, false)
        end
        if props.modHood ~= nil then
            SetVehicleMod(vehicle, 7, props.modHood, false)
        end
        if props.modFender ~= nil then
            SetVehicleMod(vehicle, 8, props.modFender, false)
        end
        if props.modRightFender ~= nil then
            SetVehicleMod(vehicle, 9, props.modRightFender, false)
        end
        if props.modRoof ~= nil then
            SetVehicleMod(vehicle, 10, props.modRoof, false)
        end
        if props.modEngine ~= nil then
            SetVehicleMod(vehicle, 11, props.modEngine, false)
        end
        if props.modBrakes ~= nil then
            SetVehicleMod(vehicle, 12, props.modBrakes, false)
        end
        if props.modTransmission ~= nil then
            SetVehicleMod(vehicle, 13, props.modTransmission, false)
        end
        if props.modHorns ~= nil then
            SetVehicleMod(vehicle, 14, props.modHorns, false)
        end
        local classAllowed = GetVehicleClass(vehicle) ~= 14 and
                             GetVehicleClass(vehicle) ~= 15 and
                             GetVehicleClass(vehicle) ~= 16 and
                             GetVehicleClass(vehicle) ~= 21 and
                             GetVehicleClass(vehicle) ~= 22
        if classAllowed and (props.suspensionHeight ~= nil and props.suspensionHeight ~= 0.00) then -- from version 2.0.6
            SetVehicleSuspensionHeight(vehicle, props.suspensionHeight)
        elseif props.modSuspension ~= nil then
            SetVehicleMod(vehicle, 15, props.modSuspension, false)
        end
        if props.modArmor ~= nil then
            SetVehicleMod(vehicle, 16, props.modArmor, false)
        end
        if props.modKit17 ~= nil then
            SetVehicleMod(vehicle, 17, props.modKit17, false)
        end
        if props.modTurbo ~= nil then
            ToggleVehicleMod(vehicle, 18, props.modTurbo)
        end
        if props.modKit19 ~= nil then
            SetVehicleMod(vehicle, 19, props.modKit19, false)
        end
        if props.modSmokeEnabled ~= nil then
            ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
        end
        if props.modKit21 ~= nil then
            SetVehicleMod(vehicle, 21, props.modKit21, false)
        end
        if props.modXenon ~= nil then
            ToggleVehicleMod(vehicle, 22, props.modXenon)
        end
        if props.xenonColor ~= nil then
            SetVehicleXenonLightsColor(vehicle, props.xenonColor)
        end
        if props.customXenonColor ~= nil then
            SetVehicleXenonLightsCustomColor(vehicle, props.customXenonColor[1], props.customXenonColor[2], props.customXenonColor[3])
        end
        if props.modFrontWheels ~= nil then
            SetVehicleMod(vehicle, 23, props.modFrontWheels, false)
        end
        if props.modBackWheels ~= nil then
            SetVehicleMod(vehicle, 24, props.modBackWheels, false)
        end
        if props.modCustomTiresF ~= nil then
            SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTiresF)
        end
        if props.modCustomTiresR ~= nil then
            SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTiresR)
        end
        if props.modPlateHolder ~= nil then
            SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
        end
        if props.modVanityPlate ~= nil then
            SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
        end
        if props.modTrimA ~= nil then
            SetVehicleMod(vehicle, 27, props.modTrimA, false)
        end
        if props.modOrnaments ~= nil then
            SetVehicleMod(vehicle, 28, props.modOrnaments, false)
        end
        if props.modDashboard ~= nil then
            SetVehicleMod(vehicle, 29, props.modDashboard, false)
        end
        if props.modDial ~= nil then
            SetVehicleMod(vehicle, 30, props.modDial, false)
        end
        if props.modDoorSpeaker ~= nil then
            SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
        end
        if props.modSeats ~= nil then
            SetVehicleMod(vehicle, 32, props.modSeats, false)
        end
        if props.modSteeringWheel ~= nil then
            SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
        end
        if props.modShifterLeavers ~= nil then
            SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
        end
        if props.modAPlate ~= nil then
            SetVehicleMod(vehicle, 35, props.modAPlate, false)
        end
        if props.modSpeakers ~= nil then
            SetVehicleMod(vehicle, 36, props.modSpeakers, false)
        end
        if props.modTrunk ~= nil then
            SetVehicleMod(vehicle, 37, props.modTrunk, false)
        end
        if props.modHydrolic ~= nil then
            SetVehicleMod(vehicle, 38, props.modHydrolic, false)
        end
        if props.modEngineBlock ~= nil then
            SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
        end
        if props.modAirFilter ~= nil then
            SetVehicleMod(vehicle, 40, props.modAirFilter, false)
        end
        if props.modStruts ~= nil then
            SetVehicleMod(vehicle, 41, props.modStruts, false)
        end
        if props.modArchCover ~= nil then
            SetVehicleMod(vehicle, 42, props.modArchCover, false)
        end
        if props.modAerials ~= nil then
            SetVehicleMod(vehicle, 43, props.modAerials, false)
        end
        if props.modTrimB ~= nil then
            SetVehicleMod(vehicle, 44, props.modTrimB, false)
        end
        if props.modTank ~= nil then
            SetVehicleMod(vehicle, 45, props.modTank, false)
        end
        if props.modWindows ~= nil then
            SetVehicleMod(vehicle, 46, props.modWindows, false)
        end
        if props.modKit47 ~= nil then
            SetVehicleMod(vehicle, 47, props.modKit47, false)
        end
        if props.modLivery ~= nil then
            if GetNumVehicleMods(vehicle, 48) > 0 then
                SetVehicleMod(vehicle, 48, props.modLivery, false)
                SetVehicleLivery(vehicle, 0)
            end
            if GetVehicleLiveryCount(vehicle) > 0 then
                SetVehicleMod(vehicle, 48, -1, false)
                SetVehicleLivery(vehicle, props.modLivery)
            end
        end
        if props.modKit49 ~= nil then
            SetVehicleMod(vehicle, 49, props.modKit49, false)
        end
        if props.liveryRoof ~= nil then
            SetVehicleRoofLivery(vehicle, props.liveryRoof)
        end
        
        if props.modFrontWheels ~= nil and props.modFrontWheels ~= -1 then
            if props.wheelSize ~= nil then
                Citizen.CreateThread(function()
                    Citizen.Wait(30)
                    SetVehicleWheelSize(vehicle, props.wheelSize)
                end)
            end
        
            if props.wheelWidth ~= nil then
                Citizen.CreateThread(function()
                    Citizen.Wait(30)
                    SetVehicleWheelWidth(vehicle, props.wheelWidth)
                end)
            end
        end

        if props.driftTyres ~= nil then -- from version 2.0.6
            SetDriftTyresEnabled(vehicle, tonumber(props.driftTyres))
        end
    end
end

return functions