local isPlacing = false
local isMenuOpen = false
local skipDelete = false

lastSelected = {}
loadingFurnitures = true
FurnitureList = {}
FurnitureModelList = {}
FullList = {}
FurnitureCategories = {}

local function getFurnitureByKey(key, list)
    for i = 1, #list do
        if list[i].key == key then
            return list[i], i
        end
    end
end

local function getFurnitureFromEntity(entity)
    local home = Homes[CurrentHome.identifier]
    debugPrint("[SearchFurniture] CurrentHome:", CurrentHome.identifier)
    local entityCoords = GetEntityCoords(entity)
    local entityModel = GetEntityModel(entity)
    local furnitures = home:GetFurnitures()

    for i = 1, #furnitures do
        local furniture = furnitures[i]
        local targetCoords

        if home.properties.type == "mlo" or (LocalPlayer.state.isInsideArea and furniture.area) then
            targetCoords = ToVector3(home.properties.entry) + ToVector3(furniture.coords)
        elseif home.properties.type == "ipl" then
            targetCoords = ToVector3(CurrentHome.entryInside) + ToVector3(furniture.coords)
        else
            targetCoords = GetOffsetFromEntityInWorldCoords(CurrentHome.object, furniture.coords.x, furniture.coords.y, furniture.coords.z)
        end

        local distance = #(entityCoords - targetCoords)
        debugPrint("[SearchFurniture]", entityCoords, targetCoords, distance)

        if distance < 1.0 then
            local matchedKey
            local objects = LocalPlayer.state.isInsideHome and home.spawnedObjects or home.areaObjects

            for j = 1, #objects do
                local objData = objects[j]
                debugPrint("[SearchFurniture]", entity, objData.object, objData.key, j)
                if objData.object == entity then
                    matchedKey = objData.key
                    break
                end
            end

            debugPrint("[SearchFurniture] Found furniture:", matchedKey, furniture.key, entityModel, GetHashKey(furniture.model))
            if matchedKey and furniture.key == matchedKey and entityModel == GetHashKey(furniture.model) then
                return matchedKey, furniture
            end
        end
    end

    return false, {}
end

local function getSpawnedObjectByKey(key, home)
    local objects = LocalPlayer.state.isInsideHome and home.spawnedObjects or home.areaObjects
    for i = 1, #objects do
        if objects[i].key == key then
            return objects[i].object, i
        end
    end
end

local function resetPlacement()
    if lastSelected.entity and IsAnEntity(lastSelected.entity) then
        SetEntityDrawOutline(lastSelected.entity, false)
        ResetEntityAlpha(lastSelected.entity)
        if lastSelected.key then
            SetEntityCoordsNoOffset(lastSelected.entity, lastSelected.initPos)
            SetEntityRotation(lastSelected.entity, lastSelected.initRotation)
            SetEntityCollision(lastSelected.entity, true)
        elseif not skipDelete then
            DeleteEntity(lastSelected.entity)
        end
    end

    isPlacing = false
    CurrentMode = nil
    StopGizmo()

    if not skipDelete then
        lastSelected = {}
    end
end

if Config.EnableFurnish then
    RegisterCommand(commands.furnish.name, function()
        local identifier = CurrentHome and CurrentHome.identifier
        if not identifier and LocalPlayer.state.designInterior then
            TriggerEvent("Housing:client:Furnish")
            return
        end

        if CurrentHome and CurrentHome.identifier then
            local playerIdentifier = GetIdentifier()
            local hasKey = CurrentHome.keys:HasKey(playerIdentifier, "Furnish", LocalPlayer.state.CurrentApartment)
            local home = Homes[CurrentHome.identifier]
            local isOwner = home:isOwner()

            if not isOwner then
                local jobConfig = JobConfig.jobs[PlayerData.job.name]
                local hasJobPerm = jobConfig and jobConfig.permission.furnish and isAgent(CurrentHome.properties.realestate)

                if not hasJobPerm and not hasKey then
                    if not isAdmin("furnish") and not home:isTenant("furnish") then
                        Notify(locale("housing"), locale("not_allowed"), "error", 2500)
                        return
                    end
                end
            end

            TriggerEvent("Housing:client:Furnish")
        else
            Notify(locale("housing"), locale("not_inside_home"), "error", 2500)
        end
    end)

    RegisterCommand(commands.editfurniture.name, function()
        local identifier = CurrentHome and CurrentHome.identifier
        if not identifier and LocalPlayer.state.designInterior then
            TriggerEvent("Housing:client:EditFurniture")
            return
        end

        if CurrentHome and CurrentHome.identifier then
            local playerIdentifier = GetIdentifier()
            local hasKey = CurrentHome.keys:HasKey(playerIdentifier, "Furnish", LocalPlayer.state.CurrentApartment)
            local home = Homes[CurrentHome.identifier]
            local isOwner = home:isOwner()

            if not isOwner then
                local jobConfig = JobConfig.jobs[PlayerData.job.name]
                local hasJobPerm = jobConfig and jobConfig.permission.furnish and isAgent(CurrentHome.properties.realestate)

                if not hasJobPerm and not hasKey then
                    if not isAdmin("furnish") and not home:isTenant("furnish") then
                        Notify(locale("housing"), locale("not_allowed"), "error", 2500)
                        return
                    end
                end
            end

            TriggerEvent("Housing:client:EditFurniture")
        else
            Notify(locale("housing"), locale("not_inside_home"), "error", 2500)
        end
    end)
end

AddEventHandler("Housing:client:Furnish", function()
    isMenuOpen = true
    OpenFurnitureMenu(Config.EnableFurnitureShop and "furnish" or "furniture_shop")
end)

RegisterNUICallback("hideFrame", function(data, cb)
    isMenuOpen = false
    resetPlacement()
    SetNuiFocusKeepInput(false)
    cb({})
end)

AddEventHandler("Housing:client:ResetFurniturePlacement", function()
    isMenuOpen = false
    resetPlacement()
end)

RegisterNetEvent("Housing:client:PlaceFurnitureFailed", function(key)
    local home = CurrentHome and CurrentHome.identifier and Homes[CurrentHome.identifier]
    if not home or not key then
        return
    end

    local furnitures = home:GetFurnitures()
    local _, index = getFurnitureByKey(key, furnitures)
    if index then
        table.remove(furnitures, index)
    end

    local lists = { home.spawnedObjects, home.areaObjects }
    for i = 1, #lists do
        local list = lists[i]
        if list then
            for j = #list, 1, -1 do
                if list[j].key == key then
                    DeleteEntity(list[j].object)
                    table.remove(list, j)
                end
            end
        end
    end
end)

RegisterNUICallback("selectScreenFurniture", function(data, cb)
    cb({})
    if not (CurrentHome and CurrentHome.identifier) then
        if LocalPlayer.state.designInterior then
            return TriggerEvent("Housing:client:SelectScreenFurniture", data, function(furnitureData, key)
                PlaceFurniture(furnitureData, furnitureData.object, key)
            end)
        end
    end

    local home = Homes[CurrentHome.identifier]
    if home and isMenuOpen then
        if not home.keys:HasKey(GetIdentifier(), "Store Furniture", LocalPlayer.state.CurrentApartment) then
            if not isAgent(home.properties.realestate) and not isAdmin("furnish") then
                return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
            end
        end

        local worldCoord, normal = GetWorldCoordFromScreenCoord(data.x, data.y)
        local hit, entity = lib.raycast.fromCoords(worldCoord + normal, worldCoord + normal * 40, 17)

        if hit and entity and GetEntityType(entity) == 3 then
            local key, furniture = getFurnitureFromEntity(entity)
            if key then
                SendReactMessage("setSelectedFurniture", key)
                Wait(100)
                if isInFurnitureShop() then
                    PlaceFurniture(FindFurniture(furniture.label), entity, key, false)
                    return
                end
                if lastSelected.entity == entity then
                    return
                end
                PlaceFurniture(furniture, entity, key)
            end
        end
    end
end)

RegisterNUICallback("submitPosition", function(data, cb)
    if CurrentMode == "precise" then
        local homeCoords = (CurrentHome.properties.type == "mlo" and Homes[CurrentHome.identifier]:GetEntityCoords()) or CurrentHome.entryInside
        local rot = ToVector3(data.rotation)
        local coords = ToVector3(data.coords)

        if #(homeCoords - coords) <= Config.MaxDistance.Furniture then
            SetEntityRotation(currentEntity, rot)
            SetEntityCoords(currentEntity, coords)
        else
            Notify(locale("housing"), locale("going_too_far"), "error", 3000)
        end
    end
end)

RegisterNUICallback("selectFurniture", function(key, cb)
    cb({})
    if not (CurrentHome and CurrentHome.identifier) then
        if LocalPlayer.state.designInterior then
            return TriggerEvent("Housing:client:SelectFurniture", key, function(furnitureData)
                PlaceFurniture(furnitureData, furnitureData.object, key)
            end)
        end
    end

    local home = Homes[CurrentHome.identifier]
    if home then
        if not home.keys:HasKey(GetIdentifier(), "Store Furniture", LocalPlayer.state.CurrentApartment) then
            if not isAgent(home.properties.realestate) then
                return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
            end
        end

        local furniture = getFurnitureByKey(key, home:GetFurnitures())
        local entity = getSpawnedObjectByKey(key, home)
        if lastSelected.entity == entity then
            return
        end
        PlaceFurniture(furniture, entity, furniture.key)
    end
end)

RegisterNUICallback("savePlacement", function(data, cb)
    SetEntityCollision(lastSelected.entity, true)
    SetEntityDrawOutline(lastSelected.entity, false)
    ResetEntityAlpha(lastSelected.entity)

    if not (CurrentHome and CurrentHome.identifier) then
        if LocalPlayer.state.designInterior then
            TriggerEvent("Housing:client:SavePlacement", lastSelected.key)
            lastSelected = {}
            cb(true)
            return
        end
    end

    if not skipDelete then
        if not ConfirmPlacement(lastSelected.entity, lastSelected.data, lastSelected.key) then
            if lastSelected.key then
                SetEntityCoordsNoOffset(lastSelected.entity, lastSelected.initPos)
                SetEntityCollision(lastSelected.entity, true)
                SetEntityDrawOutline(lastSelected.entity, false)
                SetEntityRotation(lastSelected.entity, lastSelected.initRotation)
                ResetEntityAlpha(lastSelected.entity)
            else
                DeleteEntity(lastSelected.entity)
            end

            if not Config.EnableFurnitureShop and not lastSelected.key then
                OpenFurnitureMenu("furnish")
            end
            cb(false)
        else
            DeleteEntity(lastSelected.entity)
            SendReactMessage("setSelectedFurniture", false)
            if lastSelected.key then
                EditFurniture()
            else
                OpenFurnitureMenu("furnish")
            end
            cb(true)
        end
    end

    if not skipDelete then
        lastSelected = {}
    end
    closeHelp()
    resetPlacement()
end)

RegisterNUICallback("storeFurniture", function(key, cb)
    cb({})
    if not (CurrentHome and CurrentHome.identifier) then
        if LocalPlayer.state.designInterior then
            return TriggerEvent("Housing:client:StoreFurniture", key)
        end
    end

    local home = Homes[CurrentHome.identifier]
    if home then
        local furnitures = home:GetFurnitures()
        local furniture, furnIndex = getFurnitureByKey(key, furnitures)
        local entity, objIndex = getSpawnedObjectByKey(key, home)

        if furnIndex and entity then
            debugPrint("[editFurniture]", "Furniture Index: " .. furnIndex)
            if furniture.identifier and not lib.callback.await("Housing:server:CanStoreFurniture", false, {
                    homeId = home.identifier,
                    aptId = LocalPlayer.state.CurrentApartment,
                }, furniture.identifier) then
                return
            end
            if Config.EnableFurnitureShop then
                Notify(locale("housing"), locale("furniture_stored"), "error", 3000)
            end

            if LocalPlayer.state.isInsideHome then
                table.remove(home.spawnedObjects, objIndex)
            else
                table.remove(home.areaObjects, objIndex)
            end

            if furniture.identifier then
                lib.callback.await("Housing:server:DeleteStorage", false, home.identifier, furniture.identifier)
            end

            table.remove(furnitures, furnIndex)
            DeleteEntity(entity)
            DeleteEntity(lastSelected.entity)

            SendReactMessage("setFurnitures", LabelizeFurnitures(furnitures, home))
            resetPlacement()
            TriggerServerEvent("Housing:server:StoreFurniture", {
                homeId = home.identifier,
                aptId = LocalPlayer.state.CurrentApartment,
            }, furniture, furnitures)
            closeHelp()
        end
    end
end)

RegisterNUICallback("teleportToMe", function(data, cb)
    if lastSelected.entity then
        SetEntityCoordsNoOffset(lastSelected.entity, GetEntityCoords(cache.ped))
        if CurrentMode == "gizmo" or isInFurnitureShop() then
            UpdateGizmoEntity(lastSelected.entity)
        end
    end
    cb({})
end)

RegisterNUICallback("snapToGround", function(data, cb)
    if lastSelected.entity then
        PlaceObjectOnGroundProperly(lastSelected.entity)
        if CurrentMode == "gizmo" or isInFurnitureShop() then
            UpdateGizmoEntity(lastSelected.entity)
        end
    end
    cb({})
end)

RegisterNUICallback("setEditorMode", function(mode, cb)
    SendReactMessage("setEditorMode", mode)
    cb({})
end)

RegisterNUICallback("changeMode", function(mode, cb)
    cb(mode)
    CurrentMode = mode
    if not lastSelected.entity then
        return
    end

    Wait(500)
    if mode ~= "gizmo" then
        StopGizmo()
    end

    if mode == "gizmo" then
        StartEntityGizmo(lastSelected.entity, "furnish")
    elseif mode == "raycast" then
        SetNuiFocusKeepInput(true)
        SetEntityCollision(lastSelected.entity, false)

        repeat
            local hit, _, coords = lib.raycast.cam()
            if hit then
                SetEntityCoordsNoOffset(lastSelected.entity, coords)
            end
            DrawLine(GetEntityCoords(cache.ped), coords, 255, 0, 0, 255)
            Wait(0)
            if not isInFurnitureShop() then
                break
            end
        until CurrentMode ~= "raycast"

        SetNuiFocusKeepInput(false)
    elseif mode == "precise" then
        local speed = 0.01
        displayHelp(locale("prompt_furnish_precise",
            Config.keybinds.furnish.LeftRight.help,
            Config.keybinds.furnish.ForwardBackward.help,
            Config.keybinds.furnish.PitchYawRoll.help,
            Config.keybinds.furnish.ChangeHeight.help,
            Config.keybinds.furnish.Rotate.help,
            Config.keybinds.furnish.ChangeSpeed.help
        ), "center-right")
        SetNuiFocusKeepInput(true)

        repeat
            DisableControlAction(0, Config.keybinds.furnish.ChangeHeight.key[1], true)
            DisableControlAction(0, Config.keybinds.furnish.ChangeHeight.key[2], true)
            DisableControlAction(0, Config.keybinds.furnish.PitchYawRoll.hold, true)
            DisableControlAction(0, Config.keybinds.furnish.ChangeSpeed.key[2], true)
            DisableControlAction(0, Config.keybinds.furnish.Rotate.key[2], true)
            DisableControlAction(0, Config.keybinds.furnish.Rotate.key[1], true)
            DisableControlAction(0, Config.keybinds.furnish.ChangeSpeed.key[1], true)
            DisableControlAction(0, Config.keybinds.furnish.PitchYawRoll.key[3], true)
            DisableControlAction(0, Config.keybinds.furnish.PitchYawRoll.key[4], true)
            DisableControlAction(0, Config.keybinds.furnish.PitchYawRoll.key[1], true)
            DisableControlAction(0, Config.keybinds.furnish.PitchYawRoll.key[2], true)

            if IsDisabledControlPressed(0, Config.keybinds.furnish.ChangeHeight.key[1]) then
                SetEntityCoordsNoOffset(lastSelected.entity, GetOffsetFromEntityInWorldCoords(lastSelected.entity, 0.0, 0.0, speed))
            end
            if IsDisabledControlPressed(0, Config.keybinds.furnish.ChangeHeight.key[2]) then
                SetEntityCoordsNoOffset(lastSelected.entity, GetOffsetFromEntityInWorldCoords(lastSelected.entity, 0.0, 0.0, -speed))
            end

            if IsDisabledControlPressed(0, Config.keybinds.furnish.ChangeSpeed.key[1]) and speed < 1.0 then
                speed = speed + 0.005
            end
            if IsDisabledControlPressed(0, Config.keybinds.furnish.ChangeSpeed.key[2]) and speed > 0.01 then
                speed = speed - 0.005
            end

            if IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.hold) then
                if IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.key[1]) then
                    local rot = GetEntityRotation(lastSelected.entity)
                    SetEntityRotation(lastSelected.entity, rot.x - 1.0, rot.y, rot.z)
                elseif IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.key[2]) then
                    local rot = GetEntityRotation(lastSelected.entity)
                    SetEntityRotation(lastSelected.entity, rot.x + 1.0, rot.y, rot.z)
                elseif IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.key[3]) then
                    local rot = GetEntityRotation(lastSelected.entity)
                    SetEntityRotation(lastSelected.entity, rot.x, rot.y - 1.0, rot.z)
                elseif IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.key[4]) then
                    local rot = GetEntityRotation(lastSelected.entity)
                    SetEntityRotation(lastSelected.entity, rot.x, rot.y + 1.0, rot.z)
                end
            else
                if IsDisabledControlPressed(0, Config.keybinds.furnish.Rotate.key[1]) then
                    local rot = GetEntityRotation(lastSelected.entity)
                    SetEntityRotation(lastSelected.entity, rot.x, rot.y, rot.z - 1.0)
                elseif IsDisabledControlPressed(0, Config.keybinds.furnish.Rotate.key[2]) then
                    local rot = GetEntityRotation(lastSelected.entity)
                    SetEntityRotation(lastSelected.entity, rot.x, rot.y, rot.z + 1.0)
                end
            end

            if IsDisabledControlPressed(0, Config.keybinds.furnish.ForwardBackward.key[2]) then
                if not IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.hold) then
                    SetEntityCoordsNoOffset(lastSelected.entity, GetOffsetFromEntityInWorldCoords(lastSelected.entity, 0.0, speed, 0.0))
                end
            elseif IsDisabledControlPressed(0, Config.keybinds.furnish.ForwardBackward.key[1]) then
                if not IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.hold) then
                    SetEntityCoordsNoOffset(lastSelected.entity, GetOffsetFromEntityInWorldCoords(lastSelected.entity, 0.0, -speed, 0.0))
                end
            elseif IsDisabledControlPressed(0, Config.keybinds.furnish.LeftRight.key[1]) then
                if not IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.hold) then
                    SetEntityCoordsNoOffset(lastSelected.entity, GetOffsetFromEntityInWorldCoords(lastSelected.entity, speed, 0.0, 0.0))
                end
            elseif IsDisabledControlPressed(0, Config.keybinds.furnish.LeftRight.key[2]) then
                if not IsDisabledControlPressed(0, Config.keybinds.furnish.PitchYawRoll.hold) then
                    SetEntityCoordsNoOffset(lastSelected.entity, GetOffsetFromEntityInWorldCoords(lastSelected.entity, -speed, 0.0, 0.0))
                end
            end

            Wait(0)
            if not isInFurnitureShop() then
                break
            end
        until CurrentMode ~= "precise"

        SetNuiFocusKeepInput(false)
        closeHelp()
    end
end)

function PlaceFurniture(data, entity, key, skipDeleteParam)
    if not data then
        return
    end

    skipDelete = skipDeleteParam
    if isPlacing then
        resetPlacement()
        Wait(100)
    end

    SendReactMessage("resetControlMode")
    debugPrint("[PlaceFurniture]", "Furniture model: " .. data.model)

    if not key and not entity then
        pcall(lib.requestModel, data.model)
        entity = CreateObjectNoOffset(data.model, GetEntityCoords(cache.ped), false, false, false)
        SetModelAsNoLongerNeeded(data.model)
    end

    SetEntityCollision(entity, false)
    SetEntityAlpha(entity, Config.FurnitureAlpha)
    SetEntityDrawOutline(entity, true)
    FreezeEntityPosition(entity, true)
    debugPrint("[PlaceFurniture]", "Furniture spawned: " .. entity)

    lastSelected = {
        entity = entity,
        data = data,
        key = key,
        initPos = GetEntityCoords(entity),
        initRotation = GetEntityRotation(entity),
    }

    ToggleNuiFrame(true)
    isPlacing = true
    CurrentMode = "gizmo"
    StartEntityGizmo(entity, "furnish")

    CreateThread(function()
        local controls = { 1, 2, 30, 31, 22, 23 }
        while isPlacing do
            DisableAllControlActions(0)
            CamGizmoControl()
            if IsDisabledControlPressed(0, 25) and CurrentMode ~= "gizmo" then
                for i = 1, #controls do
                    EnableControlAction(0, controls[i], true)
                end
            end
            Wait(0)
        end
    end)
end

function EditFurniture()
    local identifier = CurrentHome and CurrentHome.identifier
    if not identifier then
        if LocalPlayer.state.designInterior then
            isMenuOpen = true
            ToggleNuiFrame(true)
            SendReactMessage("setPage", "editfurniture/edit")
            Wait(50)
            TriggerEvent("Housing:client:GetEditFurniture", function(furnitures)
                SendReactMessage("setFurnitures", furnitures)
            end)
            return
        end
    end

    local home = Homes[CurrentHome.identifier]
    isMenuOpen = true
    ToggleNuiFrame(true)
    SendReactMessage("setPage", "editfurniture/edit")
    Wait(50)
    SendReactMessage("setFurnitures", LabelizeFurnitures(home:GetFurnitures(), home))
end

AddEventHandler("Housing:client:EditFurniture", EditFurniture)

function ConfirmPlacement(entity, data, key)
    if not LocalPlayer.state.isInsideHome and not LocalPlayer.state.isInsideArea then
        TriggerEvent("Housing:notify", locale("housing"), locale("not_inside_home"), "error", 3000)
        return false
    end

    local home = Homes[CurrentHome.identifier]
    if not key and not Config.EnableFurnitureShop then
        local modelData = FurnitureModelList[data.model]
        if modelData and modelData.slots then
            data.identifier = math.random(100, 999)
        end
    end

    if data.identifier then
        if home.configuration.storage < (#home:GetStorages()) + 1 then
            Notify(locale("housing"), locale("storage_max_exceeded"), "error", 3000)
            return false
        end
    end

    local entityCoords = GetEntityCoords(entity)
    local centerPoint = GetCenterPoint(home)
    local entityRotation = GetEntityRotation(entity)

    if #(entityCoords - centerPoint) > Config.MaxDistance.Furniture then
        Notify(locale("housing"), locale("going_too_far"), "error", 3000)
        return false
    end

    if not Config.EnableFurnitureShop and not key then
        local bought = lib.callback.await("Housing:server:BuyFurniture", false, data)
        if not bought then
            return false
        end
    end

    local relativeCoords
    if CurrentHome.object then
        relativeCoords = GetOffsetFromEntityGivenWorldCoords(CurrentHome.object, entityCoords.x, entityCoords.y, entityCoords.z)
    end

    if not relativeCoords then
        relativeCoords = {
            x = round(entityCoords.x - centerPoint.x, 4),
            y = round(entityCoords.y - centerPoint.y, 4),
            z = round(entityCoords.z - centerPoint.z, 4),
        }
    end

    local furnitureData = {
        coords = relativeCoords,
        heading = round(GetEntityHeading(entity) - GetEntityHeading(CurrentHome.object), 4),
        rotation = {
            x = round(entityRotation.x, 2),
            y = round(entityRotation.y, 2),
            z = round(entityRotation.z, 2),
        },
        model = data.model,
        area = LocalPlayer.state.isInsideArea and not LocalPlayer.state.isInsideHome,
        key = key,
        label = data.label,
    }

    local furnitureType = FurnitureModelList[furnitureData.model].type
    local limit = Config.LimitFurniture[furnitureType]
    if limit and limit < (#home:GetFurnituresByType(furnitureType)) + 1 then
        Notify(locale("housing"), locale("furniture_type_max_exceeded"), "error", 3000)
        return false
    end

    local furnitures = home:GetFurnitures()
    if furnitureType == "cctv" then
        if LocalPlayer.state.isInsideHome then
            Notify(locale("housing"), locale("temporarily_unavailable"), "error", 3000)
            return false
        end
        ToggleNuiFrame(false)
        SendReactMessage("resetControlMode")
        CurrentMode = "gizmo"
        furnitureData.cam = PreviewCCTV(entityCoords, entityRotation)
        OpenFurnitureMenu(Config.EnableFurnitureShop and "furnish" or "furniture_shop")
    elseif furnitureType == "light_switch" then
        local entitySetData = FindEntitySetData(home:GetEntryCoords())
        if entitySetData and next(entitySetData) then
            local input = lib.inputDialog(locale("for_which_light"), {
                {
                    label = locale("lights"),
                    type = "select",
                    options = entitySetData.lights,
                    required = true,
                },
            }, {
                allowCancel = false,
            })
            if input then
                furnitureData.light = input[1]
            end
        end
    end

    if data.identifier then
        furnitureData.identifier = data.identifier
    else
        local customFunc = Config.FurnitureFunctions[furnitureType]
        if customFunc then
            customFunc(entity, home.identifier, furnitureData.area, furnitureData)
        end
    end

    if not key then
        local newKey = #furnitures + 1
        furnitureData.key = newKey
        if LocalPlayer.state.isInsideHome then
            home.spawnedObjects[#home.spawnedObjects + 1] = {
                object = entity,
                key = newKey,
            }
        else
            home.areaObjects[#home.areaObjects + 1] = {
                object = entity,
                key = newKey,
            }
        end
        furnitures[newKey] = furnitureData
    else
        local _, index = getFurnitureByKey(key, furnitures)
        furnitures[index] = furnitureData
    end

    TriggerServerEvent("Housing:server:PlaceFurniture", {
        homeId = home.identifier,
        aptId = LocalPlayer.state.CurrentApartment,
    }, furnitureData, furnitures, key and true or false)

    if Config.EnableFurnitureShop then
        Wait(500)
    end

    RemoveOwnedFurniture(furnitureData)
    return true
end

RegisterCommand(commands.givefurniture.name, function(source, args)
    if not isAdmin() then
        return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
    end

    local targetId = tonumber(args[1])
    local furnitureName = args[2]
    if targetId and furnitureName then
        TriggerServerEvent("Housing:server:GiveFurniture", furnitureName, targetId)
    end
end, false)

RegisterNetEvent("Housing:client:UpdateFurniture", function(homeId, furnitures, apartmentId)
    local home = Homes[homeId]
    if home then
        home:UpdateFurniture(apartmentId, furnitures)
        if CurrentHome and CurrentHome.identifier == homeId then
            if home.spawnedObjects then
                for i = 1, #home.spawnedObjects do
                    DeleteEntity(home.spawnedObjects[i].object)
                end
            end
            if home.areaObjects then
                for i = 1, #home.areaObjects do
                    DeleteEntity(home.areaObjects[i].object)
                end
            end
        end

        home.spawnedObjects = {}
        home.areaObjects = {}

        if CurrentHome and CurrentHome.identifier == homeId then
            home:SpawnFurnitures()
        end
    end
end)

RegisterNetEvent("bcs_housing:client:SaveThumbnail", function(data)
    FurnitureImages[tostring(GetHashKey(data.model))] = data.img
end)