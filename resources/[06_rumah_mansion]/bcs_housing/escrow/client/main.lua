local homeType2 = nil

blipStatus = {
    sell = Config.Blips.house_sell.enable,
    owned = Config.Blips.owned_house.enable,
    admin_owned = Config.Blips.admin_owned_house.enable,
    agent = Config.Blips.agent.enable,
}

KeyPermissions = {
    "Storage",
    "CCTV",
    "Wardrobe",
    "Key",
    "Rename",
    "Garage",
    "Door 1",
    "Door 2",
    "Door 3",
    "Furnish",
    "Store Furniture",
    "Management",
}

local sEvent = "player:%s"

AddStateBagChangeHandler("CurrentHome", sEvent:format(cache.serverId), function(bagName, key, value)
    SendReactMessage("setHomeIdentifier", value and value.identifier or nil)
end)

RegisterNUICallback("initialize", function(data, cb)
    Config.UI.cataloguePreview = Config.Preview.Catalogue

    local uiLocales = {}
    for localeKey, translation in pairs(lib.getLocales()) do
        if string.find(localeKey, "ui") then
            local cleanKey = string.gsub(localeKey, "ui.", "")
            uiLocales[cleanKey] = translation
        end
    end

    cb({
        locale = uiLocales,
        config = Config.UI,
    })
end)

RegisterNUICallback("errorForm", function(message, cb)
    Notify(locale("housing"), message, "error", 3000)
    cb(1)
end)

RegisterNUICallback("GetShells", function(data, cb)
    local shellList = {}
    for shellName in pairs(Shells) do
        shellList[#shellList + 1] = shellName
    end
    cb(shellList)
end)

RegisterNUICallback("GetIPL", function(data, cb)
    local iplList = {}
    for i = 1, #CustomizeIPL do
        iplList[#iplList + 1] = CustomizeIPL[i].name
    end
    cb(iplList)
end)

RegisterNUICallback("GetMLOTeleport", function(data, cb)
    local mloList = {}
    for i = 1, #MLOTeleport do
        mloList[#mloList + 1] = MLOTeleport[i].name
    end
    cb(mloList)
end)

function CreateHome(data)
    if data then
        CreateData = data
    end
    lib.callback("Housing:server:CheckAllowed", false, function(isAllowed)
        if isAllowed then
            ToggleNuiFrame(true)
            Wait(100)
            SendReactMessage("setPage", "create")
        end
    end, "createhome")
end

exports("CreateHome", CreateHome)

RegisterCommand(commands.createhome.name, function()
    CreateHome()
end)

RegisterNUICallback("getStreetName", function(data, cb)
    local coords = GetEntityCoords(cache.ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local zoneName = GetNameOfZone(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local area = GetLabelText(zoneName)

    cb({
        street = street,
        area = area,
        id = math.random(100, 999),
    })
end)

RegisterNUICallback("createHome", function(data, cb)
    local name = data.name
    if name then
        ToggleNuiFrame(false)

        local homeData = {
            name = name,
            type = string.lower(data.type),
            payment = data.payment,
            price = tonumber(data.price),
            mortgage = data.mortgages,
            data = {
                interior = data.interior,
                downpayment = tonumber(data.downpayment),
                expiry = data.expiry,
            },
            configuration = {
                garage = data.configuration.garage,
                rename = data.configuration.rename,
                cctv = data.configuration.cctv,
                area = data.configuration.area,
                storage = data.configuration.storage,
                rentable = data.configuration.rentable,
                disableBuy = data.configuration.disableBuy,
                keys = data.configuration.keys,
                wardrobes = data.configuration.wardrobes,
                garages = data.configuration.garages,
                autoRemove = data.configuration.autoRemove,
                rentTimer = data.configuration.rentTimer,
                disableCatalogue = data.configuration.disableCatalogue,
            },
            storages = data.storages,
            wardrobes = data.wardrobes,
            permission = {
                sell = data.permission.sell,
                moveGarage = data.permission.moveGarage,
                transfer = data.permission.transfer,
                doorlock = data.permission.doorlock,
            },
            complex = data.complex,
        }

        if CreateData then
            for key, val in pairs(CreateData) do
                homeData[key] = val
            end
            CreateData = nil
        end

        if homeData.mortgage then
            for _, mortgage in pairs(homeData.mortgage) do
                mortgage.result = ((homeData.price - homeData.data.downpayment) * (mortgage.interest / 100) + 1.0) / mortgage.duration
            end
        end

        if homeData.configuration.garage then
            local garageCoords, garageInfo = GetVehiclePoint()
            if garageInfo then
                homeData.garages = {
                    {
                        coords = garageCoords,
                        name = garageInfo[1],
                        type = garageInfo[2],
                    },
                }
            end
        end

        Wait(1000)

        if homeData.type == "mlo" then
            homeData.entry = GetCoordsHeading(locale("entrance"))
            homeData.doors = CreateInitialDoors()
            PlaceStoragesWardrobes(homeData)
            Wait(1000)
            homeData.data = {
                downpayment = tonumber(data.downpayment),
                expiry = homeData.data.expiry,
            }
            TriggerEvent("Housing:client:CreateArea", homeData, data.createThumbnail)
        else
            if homeData.complex == "Flat" then
                local nearestFlat = GetNearestFlat()

                local function promptFlatData()
                    local entranceCoords = GetCoordsHeading(locale("entrance"))
                    return {
                        name = RequestKeyboardInput(locale("flat_name"), locale("flat_complex_name"), 16),
                        coords = entranceCoords,
                    }
                end

                if nearestFlat then
                    local alertChoice = lib.alertDialog({
                        header = locale("choose"),
                        content = locale("use_existing", Flats[nearestFlat].name),
                        cancel = true,
                        labels = {
                            cancel = locale("no"),
                            confirm = locale("yes"),
                        },
                    })
                    if alertChoice and alertChoice ~= "cancel" then
                        homeData.data.flat = {
                            name = Flats[nearestFlat].name,
                            coords = Flats[nearestFlat].entry,
                            identifier = nearestFlat,
                        }
                    else
                        homeData.data.flat = promptFlatData()
                    end
                else
                    homeData.data.flat = promptFlatData()
                end
            else
                if not homeData.entry then
                    homeData.entry = GetCoordsHeading("entrance")
                end
                if data.createThumbnail then
                    homeData.thumbnail = CreateThumbnail()
                end
                if homeData.complex == "Individual" then
                    if data.setArea then
                        homeData.area = CreatePoints(homeData.entry)
                    end
                end
            end
        end

        if homeData.type ~= "mlo" then
            if homeData.type == "shell" then
                TriggerEvent("Housing:client:CreateShell", homeData)
            elseif homeData.type == "ipl" then
                TriggerEvent("Housing:client:CreateIPL", homeData)
            else
                PlaceStoragesWardrobes(homeData)
                TriggerServerEvent("Housing:server:CreateHome", homeData)
            end
        end
    else
        Notify(locale("housing"), locale("error_create_home"), "error", 3000)
    end

    cb(1)
end)

RegisterNUICallback("buyHome", function(data, cb)
    ToggleNuiFrame(false)
    if Homes[data.identifier].properties.complex == "Apartment" then
        TriggerServerEvent("Housing:server:BuyApartment", data.identifier)
    else
        TriggerServerEvent("Housing:server:BuyHome", data.identifier)
    end
    cb(1)
end)

RegisterNUICallback("choosePlan", function(data, cb)
    ToggleNuiFrame(false)
    TriggerServerEvent("Housing:server:ChoosePlan", data.identifier, data.downpayment, data.plan)
    cb(1)
end)

RegisterNUICallback("boxClick", function(data, cb)
    Wait(200)
    if data.event then
        if data.server then
            TriggerServerEvent(data.event, UnpackParams(data.args))
        else
            TriggerEvent(data.event, UnpackParams(data.args))
        end
    end
    cb(1)
end)

RegisterNUICallback("notify", function(data, cb)
    Notify(locale("housing"), data.message, data.type, true)
    cb(1)
end)

local registerNUICallback2 = RegisterNUICallback
registerNUICallback2("getHouseMortgages", function(homeId, cb)
    local home = Homes[homeId]
    if home then
        cb({
            downpayment = home.properties.data.downpayment,
            mortgages = lib.callback.await("Housing:server:GetMortgages", false, homeId),
        })
    end
end)

local function getHomeOwnerName(homeId, aptId)
    local home = Homes[homeId]
    if not home then
        return locale("not_owned")
    end

    local owner = home.properties.owner
    local ownerName
    if owner then
        local name = lib.callback.await("Housing:server:GetOwnerName", false, owner) or ""
        ownerName = name .. " (" .. owner .. ")"
    else
        ownerName = locale("not_owned")
    end

    if home.properties.complex == "Apartment" and aptId then
        local aptOwner = lib.callback.await("Housing:server:GetApartmentOwner", false, homeId, aptId)
        if aptOwner then
            local aptOwnerName = lib.callback.await("Housing:server:GetOwnerName", false, aptOwner)
            ownerName = string.format("%s (%s)", aptOwnerName, aptOwner)
        end
    end

    return ownerName
end

RegisterNUICallback("getOwnerName", function(data, cb)
    local aptId = data.aptId and tonumber(data.aptId) or nil
    cb(getHomeOwnerName(data.homeId, aptId))
end)

RegisterNUICallback("getHouseData", function(data, cb)
    local home = Homes[data.homeId]
    if data.aptId == "undefined" then
        data.aptId = nil
    end

    if home then
        local aptId = data.aptId and tonumber(data.aptId) or nil
        local ownerName = getHomeOwnerName(data.homeId, aptId)
        local serverData = lib.callback.await("Housing:server:GetData", false, data.homeId, data.aptId)
        home:SetData(serverData, data.aptId)

        cb({
            name = home.properties.name,
            price = home.properties.price,
            type = home.properties.type,
            payment = home.properties.payment,
            complex = home.properties.complex,
            locked = home.properties.locked,
            configuration = home.configuration,
            permission = home.permission,
            lastPayment = lib.callback.await("Housing:server:CheckRent", false, data.homeId, data.aptId),
            owner = ownerName,
            expiry = home.properties.data.expiry,
            rent = lib.callback.await("Housing:server:GetRentData", false, data.homeId),
            thumbnail = home.thumbnail,
        })
    else
        cb(false)
    end
end)

RegisterNUICallback("getHomeManagerTabs", function(data, cb)
    local homeId = data.homeId
    local home = Homes[homeId]
    local tabs = {}

    if home then
        local playerIsAdmin = isAdmin()
        local canManageHome = false

        if not home:isTenant() then
            if home.properties.realestate and isAgent(home.properties.realestate, "configuration") then
                canManageHome = true
            elseif home.keys:HasKey(GetIdentifier(), "CCTV", data.aptId)
                or home.keys:HasKey(GetIdentifier(), "Rename", data.aptId)
                or playerIsAdmin
            then
                canManageHome = true
            end
        end

        if canManageHome then
            tabs[#tabs + 1] = locale("ui.home")
        end

        local canAccessStorage = false
        if home.properties.realestate and isAgent(home.properties.realestate, "configuration") then
            canAccessStorage = true
        elseif home:isKeyOwner("Storage") or playerIsAdmin or home:isTenant("storage") then
            canAccessStorage = true
        end

        if canAccessStorage then
            tabs[#tabs + 1] = locale("ui.storages")
        end

        if playerIsAdmin and IsResourceStarted("ox_inventory") then
            tabs[#tabs + 1] = locale("ui.storages_list")
        end

        local canAccessWardrobe = false
        if home.properties.realestate and isAgent(home.properties.realestate, "configuration") then
            canAccessWardrobe = true
        elseif home:isKeyOwner("Wardrobe") or playerIsAdmin or home:isTenant("wardrobe") then
            canAccessWardrobe = true
        end

        if canAccessWardrobe then
            tabs[#tabs + 1] = locale("ui.wardrobes")
        end

        if home:isOwned(data.aptId) then
            if home.keys:HasKey(GetIdentifier(), "Key", data.aptId) or playerIsAdmin then
                tabs[#tabs + 1] = locale("ui.keys")
            end
        end

        local canManageDoors = false
        if home.properties.realestate and isAgent(home.properties.realestate, "configuration") then
            canManageDoors = true
        elseif home.keys:HasKey(GetIdentifier(), "Management", data.aptId) or playerIsAdmin then
            canManageDoors = true
        end

        if canManageDoors then
            tabs[#tabs + 1] = locale("ui.doors")
        end

        if home.configuration.upgrades and home:isOwner(data.aptId) then
            tabs[#tabs + 1] = locale("ui.upgrades")
        end

        local canConfigure = false
        if home.properties.realestate and isAgent(home.properties.realestate, "configuration") then
            canConfigure = true
        end

        if canConfigure or playerIsAdmin then
            tabs[#tabs + 1] = locale("ui.configuration")
        end

        local mortgages = lib.callback.await("Housing:server:GetMortgages", false, homeId)
        if next(mortgages) then
            if playerIsAdmin or (home.properties.realestate and isAgent(home.properties.realestate, "configuration")) then
                tabs[#tabs + 1] = locale("ui.mortgage")
            end
        end

        if home.configuration.rentable and home:isOwner(data.aptId) then
            tabs[#tabs + 1] = locale("ui.rent")
        end

        if home.properties.complex ~= "Apartment" and home.configuration.garage then
            tabs[#tabs + 1] = locale("ui.garages")
        end

        local canAccessTeleports = false
        if home.properties.realestate and isAgent(home.properties.realestate, "teleports") then
            canAccessTeleports = true
        elseif playerIsAdmin then
            canAccessTeleports = true
        end

        if canAccessTeleports and home.properties.type ~= "mlo" then
            tabs[#tabs + 1] = locale("ui.teleports")
        end

        if home.configuration.bill and home:isOwner(data.aptId) then
            tabs[#tabs + 1] = locale("ui.bill")
        end

        cb(tabs)
    end
end)

RegisterNUICallback("getHomeConfiguration", function(homeId, cb)
    local home = Homes[homeId]
    if home then
        cb(home.configuration)
    else
        cb({})
    end
end)

RegisterNUICallback("getDefaultHomeConfiguration", function(data, cb)
    cb({
        garage = Config.configuration.Garage,
        cctv = Config.configuration.CCTV,
        rename = Config.configuration.Rename,
        wardrobes = Config.configuration.LimitWardrobes,
        keys = Config.configuration.LimitKeys,
        storage = Config.configuration.DefaultMaxStorage,
        garages = Config.configuration.DefaultMaxGarages,
        rentTimer = Config.configuration.RentTimer,
        autoRemove = Config.configuration.AutoRemove,
        bill = Config.configuration.Bill,
        disableCatalogue = Config.configuration.DisableCatalogue,
    })
end)

RegisterNUICallback("getDefaultHomePermission", function(data, cb)
    cb({
        doorlock = Config.configuration.DefaultOwnerPermission.doorlock,
        sell = Config.configuration.DefaultOwnerPermission.sell,
        moveGarage = Config.configuration.DefaultOwnerPermission.moveGarage,
        transfer = Config.configuration.DefaultOwnerPermission.transfer,
    })
end)

RegisterNUICallback("getHomeMortgages", function(homeId, cb)
    local home = Homes[homeId]
    local mortgages = lib.callback.await("Housing:server:GetMortgages", false, homeId)
    if home and mortgages then
        cb({
            mortgages = mortgages,
            downpayment = home.properties.data.downpayment,
        })
    end
end)

RegisterNUICallback("saveMortgages", function(data, cb)
    for _, mortgage in pairs(data.mortgages) do
        mortgage.result = ((data.price - data.downpayment) * (mortgage.interest / 100) + 1.0) / mortgage.duration
    end
    cb(lib.callback.await("Housing:server:SaveMortgages", false, data))
end)

RegisterNUICallback("saveHomeConfiguration", function(data, cb)
    if Homes[data.identifier] then
        TriggerServerEvent("Housing:server:SaveHomeConfiguration", data.identifier, data.configuration)
    end
    cb({})
end)

RegisterNUICallback("saveHomePermission", function(data, cb)
    local home = Homes[data.identifier]
    if home then
        home:UpdatePermission(data.permission)
    end
    cb({})
end)

RegisterNUICallback("saveEditHome", function(data, cb)
    local home = Homes[data.identifier]
    if home then
        cb(home:SaveEdit(data))
    else
        cb({})
    end
end)

RegisterNUICallback("editPlacement", function(homeId, cb)
    local home = Homes[homeId]
    if home then
        if not LocalPlayer.state.isInsideHome then
            ToggleNuiFrame(false)
            local entryCoords = home.properties.entry or home.properties.data.flat.coords
            local shellPlacement = PlaceShell(home.properties.data.interior, entryCoords, home.properties.data.placement)
            if shellPlacement then
                home:UpdateShell(shellPlacement)
            end
        end
    else
        Notify(locale("housing"), locale("action_cannot_inside"), "error", 3000)
    end
    cb({})
end)

RegisterNUICallback("editEntrance", function(homeId, cb)
    if Homes[homeId] then
        ToggleNuiFrame(false)
        HelpText(true, locale("prompt_title", "entrance"))
        local entranceCoords = nil
        repeat
            Wait(0)
            local hit, entityHit, hitCoords = lib.raycast.cam(17)
            DrawMarker(1, hitCoords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 0, 255, 150, 100, false, true, 2, false, false, false, false)
            DisableControlAction(0, 38, true)
            if IsDisabledControlJustReleased(0, 38) then
                local playerPed = PlayerPedId()
                entranceCoords = {
                    x = round(hitCoords.x, 2),
                    y = round(hitCoords.y, 2),
                    z = round(hitCoords.z, 2),
                    w = round(GetEntityHeading(playerPed), 2),
                }
                HelpText(false)
                break
            end
        until false
        TriggerServerEvent("Housing:server:UpdateEntrance", homeId, entranceCoords)
    end
    cb({})
end)

RegisterNUICallback("editThumbnail", function(homeId, cb)
    local home = Homes[homeId]
    cb(true)
    if home then
        ToggleNuiFrame(false)
        Wait(500)
        local input = lib.inputDialog(locale("housing"), {
            {
                type = "input",
                label = locale("thumbnail"),
                default = home.thumbnail,
                description = locale("thumbnail_help"),
            },
        })
        local thumbnail = nil
        if input and input[1] and input[1] ~= "" then
            thumbnail = input[1]
        end
        if not thumbnail then
            thumbnail = CreateThumbnail()
        end
        if thumbnail then
            TriggerServerEvent("Housing:server:UpdateThumbnail", homeId, thumbnail)
        end
    end
end)

RegisterNetEvent("Housing:client:UpdateThumbnail", function(homeId, thumbnail)
    local home = Homes[homeId]
    if home then
        home.thumbnail = thumbnail
    end
end)

RegisterNUICallback("getHomeKeys", function(data, cb)
    local home = Homes[data.id]
    if home then
        if data.aptId then
            local apartment = Apartments[data.id]
            local room = apartment and apartment:GetApartmentById(data.aptId)
            if room then
                cb(room.keys:GetKeyList())
            else
                cb({})
            end
        else
            cb(home.keys:GetKeyList())
        end
    else
        cb({})
    end
end)

RegisterNUICallback("addHomeKey", function(data, cb)
    for i = 1, #data.permission do
        data.permission[i] = data.permission[i] + 1
    end
    local success = AddKey(data.homeId, data.aptId, data.name, data.oldName, data.permission)
    if success then
        Notify(locale("housing"), locale("key_created_successfully", data.name), "success", 3000)
    else
        Notify(locale("housing"), locale("key_creation_error"), "error", 3000)
    end
    cb(success)
end)

RegisterNUICallback("deleteHomeKey", function(data, cb)
    local success = RemoveKey(data.homeId, data.aptId, data.key)
    if success then
        Notify(locale("housing"), locale("key_deleted_successfully", data.key), "success", 3000)
    else
        Notify(locale("housing"), locale("key_deletion_error"), "error", 3000)
    end
    cb(success)
end)

RegisterNUICallback("getNearbyPlayers", function(data, cb)
    local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 10.0)
    local playersList = {}
    if isAdmin() then
        playersList[1] = cache.serverId
    end
    for i = 1, #nearbyPlayers do
        playersList[#playersList + 1] = GetPlayerServerId(nearbyPlayers[i].id)
    end
    cb(playersList)
end)

RegisterNUICallback("giveHomeKeyHolder", function(data, cb)
    cb(exports[GetCurrentResourceName()]:AddKeyHolder(data.homeId, data.target, data.key, data.aptId))
end)

RegisterNUICallback("removeHomeKeyHolder", function(data, cb)
    cb(exports[GetCurrentResourceName()]:RemoveKeyHolder(data.homeId, data.identifier, data.aptId))
end)

RegisterNUICallback("getKeyPermissions", function(data, cb)
    cb(KeyPermissions)
end)

RegisterNUICallback("toggleLock", function(homeId, cb)
    local isLocked = lib.callback.await("Housing:server:ToggleLock", false, homeId, LocalPlayer.state.CurrentApartment)
    SendReactMessage("setHome", {
        identifier = homeId,
        status = isLocked,
    })
    cb(isLocked)
end)

RegisterNUICallback("setWaypoint", function(homeId, cb)
    local home = Homes[homeId]
    if home then
        local entryCoords = home:GetEntryCoords()
        SetNewWaypoint(entryCoords.x, entryCoords.y)
    end
    cb(1)
end)

RegisterNUICallback("doCommand", function(data, cb)
    ToggleNuiFrame(false)
    local commandParams = commands[data.key].params or {}
    if next(commandParams) then
        local dialogInputs = {}
        for i = 1, #commandParams do
            dialogInputs[#dialogInputs + 1] = {
                type = "input",
                label = commandParams[i].name,
                description = commandParams[i].help,
            }
        end
        local inputResult = lib.inputDialog(locale("housing"), dialogInputs)
        if inputResult then
            data.cmd = string.format("%s %s", data.cmd, table.concat(inputResult, " "))
        end
    end
    ExecuteCommand(data.cmd)
    cb(1)
end)

RegisterNUICallback("getCommands", function(data, cb)
    local commandList = {}
    local tab = data.tab
    for key, command in pairs(commands) do
        if tab == "realtor" then
            if command.perm == "Realtor" or command.perm == "Admin / Realtor" then
                command.key = key
                table.insert(commandList, command)
            end
        elseif tab == "public" then
            if command.perm == "Public" then
                command.key = key
                table.insert(commandList, command)
            end
        else
            command.key = key
            table.insert(commandList, command)
        end
    end
    cb(commandList)
end)

RegisterNUICallback("getJobs", function(data, cb)
    local jobList = {}
    for jobName in pairs(JobConfig.jobs) do
        table.insert(jobList, jobName)
    end
    cb(jobList)
end)

RegisterCommand("housing", function()
    ToggleNuiFrame(true)
    Wait(50)
    SendReactMessage("setPage", "housing")
    local animDict = "amb@world_human_tourist_map@male@base"
    local animName = "base"
    local tabletModel = "prop_cs_tablet"
    lib.requestAnimDict(animDict)
    pcall(lib.requestModel, tabletModel)
    local tabletObject = CreateObjectNoOffset(tabletModel, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(tabletModel)
    AttachEntityToEntity(tabletObject, cache.ped, GetPedBoneIndex(cache.ped, 28422),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    TaskPlayAnim(cache.ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    while IsNuiFocused() do
        Wait(100)
    end
    StopAnimTask(cache.ped, animDict, animName, 1.0)
    DeleteObject(tabletObject)
end)

RegisterNUICallback("renameHouse", function(data, cb)
    local home = Homes[data.identifier]
    if home then
        if home.configuration.rename then
            local success = lib.callback.await("Housing:server:RenameHouse", false, data.name, data.identifier)
            if success then
                Notify(locale("housing"), locale("successfully_renamed", data.name), "success", 3000)
            end
            cb(success)
        end
    else
        Notify(locale("housing"), locale("rename_not_allowed"), "error", 3000)
    end
end)

RegisterNetEvent("Housing:client:RenameHouse", function(identifier, name)
    if Homes[identifier] then
        Homes[identifier].properties.name = name
        RefreshHomeBlip(identifier)
    end
end)

RegisterNUICallback("transferHome", function(data, cb)
    if data.id and type(tonumber(data.id)) == "number" then
        local home = Homes[data.identifier]
        if home then
            local canTransfer = home:isOwner() or isAdmin() or isAgent(home.properties.realestate)
            if canTransfer then
                ToggleNuiFrame(false)
                local alert = lib.alertDialog({
                    header = locale("transfer_home"),
                    content = locale("transfer_home_desc"),
                    centered = true,
                    cancel = true
                })
                if alert ~= "confirm" then
                    cb(1)
                    return
                end
                TriggerServerEvent("Housing:server:TransferOwner", home.identifier, tonumber(data.id), data.aptId)
            end
        end
    else
        Notify(locale("housing"), locale("invalid_input"), "error", 3000)
    end
    cb(1)
end)

RegisterNUICallback("sellHome", function(data, cb)
    if not LocalPlayer.state.isInsideHome then
        ToggleNuiFrame(false)
        TriggerServerEvent("Housing:server:SellHome", data.id, data.aptId)
    else
        Notify(locale("housing"), locale("action_cannot_inside"), "error", 3000)
    end
    cb(1)
end)

RegisterNUICallback("deleteHome", function(data, cb)
    if not LocalPlayer.state.isInsideHome then
        TriggerServerEvent("Housing:server:DeleteHome", data)
        Wait(1000)
        if homeType2 == "adminhome" then
            OpenAdminHomes()
        elseif homeType2 == "realestate" then
            OpenCreatedRealestates()
        elseif homeType2 == "ownedhome" then
            OpenOwnedHomeManager()
        end
    else
        Notify(locale("housing"), locale("action_cannot_inside"), "error", 3000)
    end
    cb(1)
end)

RegisterNetEvent("Housing:client:SyncKeys", function(identifier, keyIndex, keyData, aptId)
    local home = Homes[identifier]
    if home then
        if aptId then
            local complex = Apartments[identifier]
            local apartment = complex and complex:GetApartmentById(aptId)
            if apartment and apartment.keys then
                apartment.keys[keyIndex] = keyData
                return
            end
        else
            home.keys[keyIndex] = keyData
        end
    end
end)

AddEventHandler("Housing:client:CreateMenu", function(menuData)
    if menuData.title and menuData.boxes then
        ToggleNuiFrame(true)
        local homeIdentifier = CurrentHome and CurrentHome.identifier or ""
        SendReactMessage("setHomeIdentifier", homeIdentifier)
        Wait(50)
        SendReactMessage("setPage", "selection")
        Wait(50)
        SendNUIMessage({
            action = "setSelection",
            data = menuData
        })
    end
end)

AddEventHandler("Housing:client:PayMortgage", function(identifier, aptId)
    local parsedAptId = tonumber(aptId)
    lib.callback("Housing:server:CheckMortgage", false, function(mortgageData)
        if mortgageData then
            ToggleNuiFrame(true)
            Wait(50)
            SendReactMessage("setPage", "mortgage")
            Wait(100)
            local plan = (function()
                local home = Homes[identifier]
                if home.properties.complex == "Apartment" then
                    if aptId then
                        local complex = Apartments[identifier]
                        if complex then
                            local apartment = complex:GetApartmentById(aptId)
                            return apartment and apartment.plan
                        end
                    end
                else
                    return home.properties and home.properties.plan
                end
            end)()
            if plan then
                SendNUIMessage({
                    action = "setMortgage",
                    data = {
                        plan = plan,
                        data = mortgageData,
                        identifier = identifier,
                        aptId = aptId
                    }
                })
            end
        else
            Notify(locale("housing"), locale("no_mortgage"), "error", 3000)
        end
    end, identifier, parsedAptId)
end)

AddEventHandler("Housing:client:BuyHome", function(identifier)
    ToggleNuiFrame(true)
    Wait(50)
    SendReactMessage("setPage", "buy")
    Wait(100)
    local home = Homes[identifier]
    lib.callback("Housing:server:GetMortgages", false, function(mortgages)
        local interior = ""
        if home.properties.type == "ipl" and home.properties.data.interior.name then
            interior = home.properties.data.interior.name
        elseif home.properties.data.interior then
            interior = home.properties.data.interior
        end

        SendNUIMessage({
            action = "setBuyHome",
            data = {
                mortgages = mortgages or {},
                interior = interior,
                name = home.properties.name,
                price = home.properties.price,
                payment = home.properties.payment,
                downpayment = home.properties.data.downpayment or 0,
                identifier = identifier,
                rentTimer = home.configuration.rentTimer or 0
            }
        })
    end, identifier)
end)

lib.callback.register("Housing:client:callback:EnterHome", function(identifier, isPreview, aptId)
    local home = Homes[identifier]
    if home then
        if home.properties.complex == "Apartment" and not aptId then
            local complex = Apartments[home.identifier]
            aptId = complex:GetOwnedApartmentId()
        end
        return home:EnterHome(isPreview, aptId)
    end
end)

RegisterNetEvent("Housing:client:EnterHome", function(identifier, isPreview, aptId, targetPed)
    local home = Homes[identifier]
    local allowed, reason = TriggerEventHooks("EnterHome", {
        identifier = identifier
    })
    if not allowed then
        if reason then
            Notify(locale("housing"), reason, "error", 3000)
        end
        return
    end
    if isPreview and not Config.Preview.Home then
        Notify(locale("housing"), locale("preview_not_allowed"), "error", 3000)
        return
    end
    if home then
        local entryCoords = home:GetEntryCoords()
        if home.properties.type == "mlo" then
            SetEntityCoords(cache.ped, entryCoords.x, entryCoords.y, entryCoords.z)
        else
            if home.properties.complex == "Apartment" and not aptId then
                local complex = Apartments[home.identifier]
                aptId = complex:GetOwnedApartmentId()
            end
            home:EnterHome(isPreview, aptId, targetPed)
        end
    end
end)

AddEventHandler("Housing:client:ExitHome", function(identifier, isTeleport)
    local home = Homes[identifier]
    local allowed, reason = TriggerEventHooks("ExitHome", {
        identifier = identifier
    })
    if not allowed then
        if reason then
            Notify(locale("housing"), reason, "error", 3000)
        end
        return
    end
    if home then
        home:ExitHome(isTeleport)
    end
end)

AddEventHandler("Housing:client:OpenHouseManager", OpenHouseManager)

RegisterNetEvent("Housing:client:SellHome", function(identifier)
    Wait(200)
    TriggerEvent("Housing:client:CreateMenu", {
        title = locale("confirmation_sell_home"),
        subtitle = locale("are_you_sure"),
        boxes = {
            {
                text = {
                    title = locale("yes")
                },
                icon = "check",
                event = "Housing:server:SellHome",
                server = true,
                args = {
                    identifier
                }
            },
            {
                text = {
                    title = locale("no")
                },
                icon = "x"
            }
        }
    })
end)

RegisterCommand(commands.deletehome.name, function(source, args)
    lib.callback("Housing:server:CheckAllowed", false, function(allowed)
        if allowed then
            DeleteHome(args[1])
        end
    end, "deletehome")
end)

RegisterCommand(commands.deleteapartment.name, function(source, args)
    lib.callback("Housing:server:CheckAllowed", false, function(allowed)
        if allowed then
            DeleteApartment(args[1], tonumber(args[2]))
        end
    end, "deletehome")
end)

RegisterCommand(commands.deleteflat.name, function(source, args)
    lib.callback("Housing:server:CheckAllowed", false, function(allowed)
        if allowed then
            DeleteFlat(table.concat(args, " "))
        end
    end, "deletehome")
end)

RegisterNUICallback("getRealestates", function(data, cb)
    local realestates = {}
    for jobName, jobData in pairs(JobConfig.jobs) do
        table.insert(realestates, {
            job = jobName,
            label = jobData.label
        })
    end
    cb(realestates)
end)

RegisterNUICallback("hideFrame", function(data, cb)
    homeType2 = nil
    cb({})
end)

RegisterNUICallback("backToList", function(data, cb)
    CachePage = data.page or 1
    if homeType2 == "adminhome" then
        OpenAdminHomes()
    elseif homeType2 == "realestate" then
        OpenCreatedRealestates()
    elseif homeType2 == "ownedhome" then
        OpenOwnedHomeManager()
    end
    cb({})
end)

RegisterNUICallback("getCreator", function(identifier, cb)
    local creatorName = locale("ui.home")
    local home = Homes[identifier]
    if identifier then
        if home and home.properties and home.properties.realestate and not home.properties.owner then
            local serverCreator = lib.callback.await("Housing:server:GetCreator", false, identifier)
            creatorName = serverCreator or creatorName
        end
    else
        local job = JobConfig.jobs[PlayerData.job.name]
        if job then
            creatorName = string.format("%s | %s", GetName(), PlayerData.job.label)
        elseif home and home.properties and home.properties.owner then
            if GetIdentifier() == home.properties.owner then
                creatorName = GetName() or locale("ui.home")
            else
                creatorName = locale("ui.home")
            end
        end
    end
    cb(creatorName)
end)

RegisterNUICallback("disableScroll", function(state, cb)
    DisableScroll = state
    cb(true)
end)

RegisterNUICallback("getUpgradeList", function(data, cb)
    cb(lib.callback.await("Housing:server:GetUpgradeList", false, data.homeId, data.aptId))
end)

RegisterNUICallback("upgradeHomeLimit", function(data, cb)
    local home = Homes[data.homeId]
    if home then
        ToggleNuiFrame(false)
        home.configuration = home.configuration or {}
        home.configuration[data.type] = data.value
        TriggerServerEvent("Housing:server:SaveHomeConfiguration", data.homeId, home.configuration, true, data.type)
    end
    cb(1)
end)

RegisterNUICallback("getHomes", function(data, cb)
    local page = data.page or 1
    local perPage = data.perPage or 4
    local filterComplex = data.filters.complex
    local filterStatus = data.filters.status
    local filterHomeType = data.filters.homeType
    local filterSearch = data.filters.search
    local filterOwner = data.filters.owner

    if HomeList then
        local homeList = HomeList
        local isAdminList = HomeListAdmin
        local filteredHomes = {}

        for i = #homeList, 1, -1 do
            local homeData = homeList[i]
            homeData.name = homeData.properties.name
            homeData.type = homeData.properties.type
            homeData.complex = homeData.properties.complex
            homeData.status = homeData.properties.locked or (homeData.properties.locked == 0)
            homeData.realestate = homeData.properties.realestate
            local homeObj = Homes[homeData.identifier]
            homeData.owner = homeObj and homeObj:GetOwner()
            homeData.price = homeData.properties.price or 0
            homeData.thumbnail = homeData.thumbnail

            if not homeData.thumbnail and (homeData.type == "shell" or homeData.type == "ipl") then
                local interiorName = homeData.properties.data.interior:gsub("%s", "")
                homeData.thumbnail = "images/interior/" .. interiorName .. ".png"
            end

            local isMatch = true
            if filterOwner and filterOwner ~= "all" and homeData.owner ~= filterOwner then
                isMatch = false
            end
            if filterComplex ~= "all" and homeData.complex ~= filterComplex then
                isMatch = false
            end
            if isMatch and filterStatus ~= "all" then
                if filterStatus == "owned" then
                    if not homeData.owner then
                        isMatch = false
                    end
                elseif filterStatus == "for_sale" then
                    if homeData.owner then
                        isMatch = false
                    end
                end
            end
            if isMatch and filterHomeType ~= "all" and homeData.type ~= filterHomeType then
                isMatch = false
            end
            if isMatch and filterSearch ~= "" then
                local searchLower = string.lower(filterSearch)
                local nameLower = string.lower(homeData.name or "")
                if not string.find(nameLower, searchLower, 1, true) then
                    isMatch = false
                end
                if not isMatch and homeData.owner then
                    local ownerLower = string.lower(homeData.owner or "")
                    if string.find(ownerLower, searchLower, 1, true) then
                        isMatch = true
                    end
                end
                if not isMatch and homeData.complex == "Apartment" then
                    local apartmentList = Apartments[homeData.identifier] and Apartments[homeData.identifier].apartments
                    if apartmentList then
                        for aptIndex = 1, #apartmentList do
                            local aptOwnerLower = string.lower(apartmentList[aptIndex].owner or "")
                            if string.find(aptOwnerLower, searchLower, 1, true) then
                                homeData.apartment = apartmentList[aptIndex].apartment
                                homeData.owner = apartmentList[aptIndex].owner
                                isMatch = true
                                break
                            end
                        end
                    end
                end
            end

            if isMatch then
                if not isAdminList and homeData.complex == "Apartment" then
                    local apartmentList = Apartments[homeData.identifier] and Apartments[homeData.identifier].apartments
                    if apartmentList then
                        for aptIndex = 1, #apartmentList do
                            local keys = apartmentList[aptIndex].keys
                            if keys and keys:HasKey(GetIdentifier()) then
                                homeData.apartment = apartmentList[aptIndex].apartment
                                homeData.owner = apartmentList[aptIndex].owner
                                break
                            end
                        end
                    end
                end

                if isAdminList then
                    if homeData.properties.complex == "Apartment" then
                        local apartmentList = Apartments[homeData.identifier] and Apartments[homeData.identifier].apartments
                        if apartmentList and type(apartmentList) == "table" and #apartmentList > 0 then
                            local baseClone = table.clone(homeData)
                            for aptIndex = 1, #apartmentList do
                                local aptClone = table.clone(baseClone)
                                aptClone.apartment = apartmentList[aptIndex].apartment
                                aptClone.owner = apartmentList[aptIndex].owner
                                table.insert(filteredHomes, aptClone)
                            end
                        else
                            table.insert(filteredHomes, homeData)
                        end
                    else
                        table.insert(filteredHomes, homeData)
                    end
                else
                    table.insert(filteredHomes, homeData)
                end
            end
        end

        local totalCount = #filteredHomes
        local totalPages = math.ceil(totalCount / perPage)
        local startIndex = ((page - 1) * perPage) + 1
        local endIndex = math.min((startIndex + perPage) - 1, totalCount)
        local pagedData = {}
        for i = startIndex, endIndex do
            if filteredHomes[i] then
                table.insert(pagedData, filteredHomes[i])
            end
        end

        cb({
            totalPages = totalPages,
            data = pagedData
        })
    else
        cb({
            totalPages = 0,
            data = {}
        })
    end
end)

local registerNUICallback = RegisterNUICallback
registerNUICallback("setCachePage", function(data, cb)
    CachePage = data.page
    cb({})
end)

local function openHomeList(homes, isAdminList)
    HomeList = homes
    HomeListAdmin = isAdminList
    ToggleNuiFrame(true)
    SendReactMessage("setPage", "home/manager/list")
    Wait(100)
    SendReactMessage("setCachePage", {
        page = CachePage or 1
    })
end

function OpenOwnedHomeManager(source, args)
    local identifier = GetIdentifier()
    homeType2 = "ownedhome"
    if CurrentHome and CurrentHome.identifier then
        local hasKey = CurrentHome.keys and CurrentHome.keys:HasKey(identifier, "Management", LocalPlayer.state.CurrentApartment)
        local isOwner = CurrentHome.properties.owner == identifier
        local isTenant = Homes[CurrentHome.identifier] and Homes[CurrentHome.identifier]:isTenant()

        if isOwner or hasKey or isTenant then
            SendReactMessage("setPage", string.format("home/%s/%s", CurrentHome.identifier, LocalPlayer.state.CurrentApartment))
            ToggleNuiFrame(true)
        else
            if args and args[1] == "rented" then
                openHomeList(exports[GetCurrentResourceName()]:GetOwnedRentedHomes())
            else
                openHomeList(exports[GetCurrentResourceName()]:GetOwnedHomeKeys())
            end
        end
    else
        if args and args[1] == "rented" then
            openHomeList(exports[GetCurrentResourceName()]:GetOwnedRentedHomes())
        else
            openHomeList(exports[GetCurrentResourceName()]:GetOwnedHomeKeys())
        end
    end

    if CachePage then
        Wait(100)
        SendReactMessage("setCachePage", {
            page = CachePage or 1
        })
    end
end

RegisterNetEvent("Housing:client:ManageOwnedHomes", OpenOwnedHomeManager)

function OpenCreatedRealestates()
    if PlayerData.job and JobConfig.jobs[PlayerData.job.name] then
        homeType2 = "realestate"
        openHomeList(exports[GetCurrentResourceName()]:GetRealestateHomes(PlayerData.job.name))
    else
        Notify(locale("housing"), locale("not_allowed"), "error", 3000)
    end
end

RegisterNetEvent("Housing:client:RealEstateHomes", OpenCreatedRealestates)

function OpenAdminHomes(source, args)
    if isAdmin() then
        homeType2 = "adminhome"
        if args and args[1] then
            local nearestHome = GetNearestHome(nil, 100.0)
            if nearestHome then
                SendReactMessage("setPage", string.format("home/%s/%s", nearestHome.identifier, LocalPlayer.state.CurrentApartment))
                ToggleNuiFrame(true)
            else
                Notify(locale("housing"), locale("no_home_nearby"), "error", 3000)
            end
        else
            openHomeList(exports[GetCurrentResourceName()]:GetHomes(), true)
        end
        SendReactMessage("setPlayer", {
            identifier = GetIdentifier(),
            role = "admin"
        })
    else
        Notify(locale("housing"), locale("not_allowed"), "error", 3000)
    end
end

function ToggleBlip(blipType)
    if blipStatus[blipType] ~= nil then
        if blipStatus[blipType] then
            for identifier in pairs(Homes) do
                deleteBlip(identifier .. "_" .. blipType)
            end
            for _, flatData in pairs(Flats) do
                for _, room in pairs(flatData.rooms) do
                    deleteBlip(room.properties.data.flat.identifier .. "_" .. blipType)
                end
            end
            blipStatus[blipType] = false
        else
            blipStatus[blipType] = true
            for identifier in pairs(Homes) do
                RefreshHomeBlip(identifier, isAdmin())
            end
            RefreshFlatBlip()
        end
    end
end

RegisterCommand(commands.managehomes.name, OpenOwnedHomeManager)
RegisterCommand(commands.realestatehomes.name, OpenCreatedRealestates)
RegisterCommand(commands.adminhomes.name, OpenAdminHomes)
RegisterCommand(commands.houseblip.name, function(source, args)
    ToggleBlip(args[1])
end)

RegisterNUICallback("teleportToStorage", function(data, cb)
    cb(true)

    if not CurrentHome or not next(CurrentHome) then
        Notify(locale("housing"), locale("not_inside_home"), "error", 3000)
        return
    end

    local home = Homes[data.homeId]
    if home then
        local storageCoords = nil

        if data.aptId then
            local apartmentList = Apartments[data.homeId]
            local apartment = apartmentList and apartmentList:GetApartmentById(data.aptId)
            if apartment and apartment.storages then
                for _, storage in pairs(apartment.storages) do
                    if storage.id == data.storageId then
                        storageCoords = storage.coords
                        break
                    end
                end
            end
        elseif home.properties.storages then
            for _, storage in pairs(home.properties.storages) do
                if storage.id == data.storageId then
                    storageCoords = storage.coords
                    break
                end
            end
        end

        if storageCoords then
            ToggleNuiFrame(false)

            if home.properties.type == "shell" then
                local placement = home.properties.data.placement
                local targetCoords = vector3(storageCoords.x + placement.x, storageCoords.y + placement.y, storageCoords.z + placement.z + 1.0)
                SetEntityCoords(cache.ped, targetCoords)
            end
        end
    end
end)