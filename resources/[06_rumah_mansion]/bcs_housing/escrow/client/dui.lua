local signboardPoints = {}
local spawnedSigns = {}
local signSlots = { false, false, false, false, false }

local function EditSignboard(signId, text, homeId)
    if PlayerData and PlayerData.job and PlayerData.job.name ~= Homes[homeId].properties.realestate and not isAdmin() then
        return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
    end

    local inputDialog = lib.inputDialog(locale("signboard"), {
        { type = "input", label = locale("title"), required = true, default = text[1] },
        { type = "input", label = locale("logo_url") },
        { type = "input", label = locale("subtitle"), required = true, default = text[3] },
        { type = "input", label = locale("description"), required = true, default = text[4] },
        { type = "input", label = locale("footer"), description = locale("footer_signboard"), required = true, default = text[5] }
    })

    if not inputDialog then
        return
    end

    lib.callback("Housing:server:EditSignboard", false, function(success)
        if success then
            local payload = json.encode({
                action = "setSignText",
                data = {
                    title = inputDialog[1],
                    url = inputDialog[2],
                    subtitle = inputDialog[3],
                    text = inputDialog[4],
                    footer = inputDialog[5]
                }
            })
            SendDuiMessage(spawnedSigns[signId].duiObj, payload)
            Notify(locale("housing"), locale("edit_sign_successful"), "success", 3000)
        else
            Notify(locale("housing"), locale("an_error_has_occured"), "error", 3000)
        end
    end, inputDialog, homeId)
end

function DeleteSpawnedSign(homeId)
    for signId, signData in pairs(spawnedSigns) do
        if signData.homeId == homeId then
            if signId and spawnedSigns[signId] and spawnedSigns[signId].duiObj then
                DestroyDui(spawnedSigns[signId].duiObj)
                RemoveTargetEntity(spawnedSigns[signId].object, {
                    locale("edit_sign"),
                    locale("delete_sign")
                })
                DeleteObject(spawnedSigns[signId].object)
                signSlots[signId] = false
                spawnedSigns[signId] = nil

                for i = 1, #signboardPoints do
                    if signboardPoints[i].homeId == homeId then
                        signboardPoints[i].point:remove()
                    end
                end
            end
            break
        end
    end
end

function DeleteSign(signId, homeId)
    if PlayerData and PlayerData.job and PlayerData.job.name ~= Homes[homeId].properties.realestate and not isAdmin() then
        return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
    end

    lib.callback("Housing:server:DeleteSignboard", false, function(success)
        if success then
            if signId and spawnedSigns[signId] and spawnedSigns[signId].duiObj then
                DestroyDui(spawnedSigns[signId].duiObj)
                RemoveTargetEntity(spawnedSigns[signId].object, {
                    locale("edit_sign"),
                    locale("delete_sign")
                })
                DeleteObject(spawnedSigns[signId].object)
                signSlots[signId] = false
                spawnedSigns[signId] = nil

                for i = 1, #signboardPoints do
                    if signboardPoints[i].homeId == homeId then
                        signboardPoints[i].point:remove()
                    end
                end
                Notify(locale("housing"), locale("delete_sign_successful"), "error", 3000)
            end
        else
            Notify(locale("housing"), locale("an_error_has_occured"), "error", 3000)
        end
    end, homeId)
end

function LoadSignboard(data, realestateJob)
    local isPromptActive = false
    data.coords = ToVector3(data.coords)

    for i = 1, #signboardPoints do
        if signboardPoints[i].homeId == data.homeId then
            return
        end
    end

    local pointData = {
        coords = data.coords,
        homeId = data.homeId
    }

    pointData.point = lib.points.new({
        coords = data.coords,
        distance = 25,
        onEnter = function(point)
            signReady = false
            local availableSlot = nil

            for i = 1, #signSlots do
                if not signSlots[i] then
                    availableSlot = i
                end
            end

            if not availableSlot then
                return
            end

            point.signId = availableSlot
            spawnedSigns[availableSlot] = {
                homeId = data.homeId,
                object = CreateObject(GetHashKey("signboard_potato_" .. availableSlot), data.coords)
            }
            SetEntityHeading(spawnedSigns[availableSlot].object, data.heading)

            AddTargetEntity("signboard_" .. availableSlot, spawnedSigns[availableSlot].object, {
                distance = 3.5,
                options = {
                    {
                        icon = "fas fa-pen-to-square",
                        label = locale("edit_sign"),
                        action = function()
                            EditSignboard(availableSlot, data.text, data.homeId)
                        end,
                        canInteract = function()
                            return isAdmin() or isAgent(Homes[data.homeId].properties.realestate)
                        end
                    },
                    {
                        icon = "fas fa-trash",
                        label = locale("delete_sign"),
                        action = function()
                            DeleteSign(availableSlot, data.homeId)
                        end,
                        canInteract = function()
                            return isAdmin() or isAgent(Homes[data.homeId].properties.realestate)
                        end
                    }
                }
            })

            spawnedSigns[availableSlot].duiObj = CreateDui("https://cfx-nui-" .. GetCurrentResourceName() .. "/html/index.html", 960, 540)
            CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd("theboard_" .. availableSlot .. "_d"), "theboard_" .. availableSlot, GetDuiHandle(spawnedSigns[availableSlot].duiObj))
            RemoveReplaceTexture("signboard_potato", "signboard_" .. availableSlot)
            Wait(500)
            AddReplaceTexture("signboard_potato", "signboard_" .. availableSlot, "theboard_" .. availableSlot .. "_d", "theboard_" .. availableSlot)
            Wait(500)
            SendDuiMessage(spawnedSigns[availableSlot].duiObj, json.encode({
                action = "setVisible",
                data = true
            }))
            Wait(500)
            SendDuiMessage(spawnedSigns[availableSlot].duiObj, json.encode({
                action = "setPage",
                data = "realestate"
            }))
            SendDuiMessage(spawnedSigns[availableSlot].duiObj, json.encode({
                action = "setSignText",
                data = {
                    title = data.text[1],
                    url = data.text[2],
                    subtitle = data.text[3],
                    text = data.text[4],
                    footer = data.text[5]
                }
            }))
            signSlots[availableSlot] = true
        end,
        onExit = function(point)
            if point.signId and spawnedSigns[point.signId] and spawnedSigns[point.signId].duiObj then
                DestroyDui(spawnedSigns[point.signId].duiObj)
                RemoveTargetEntity(spawnedSigns[point.signId].object, {
                    locale("edit_sign"),
                    locale("delete_sign")
                })
                DeleteObject(spawnedSigns[point.signId].object)
                signSlots[point.signId] = false
                spawnedSigns[point.signId] = nil
            end
        end,
        nearby = function(point)
            if not Config.target then
                if point.currentDistance < 2.5 then
                    if not isPromptActive then
                        if isAdmin() or isAgent(realestateJob) then
                            HelpText(true, locale("prompt_manage_sign"))
                        end
                        isPromptActive = true
                    end
                    if IsControlJustReleased(0, 38) then
                        if isAdmin() or isAgent(realestateJob) then
                            EditSignboard(point.signId, data.text, data.homeId)
                            HelpText(false)
                            isPromptActive = false
                        end
                    elseif IsControlJustReleased(0, 58) then
                        if isAdmin() or isAgent(realestateJob) then
                            DeleteSign(point.signId, data.homeId)
                            HelpText(false)
                            isPromptActive = false
                        end
                    end
                else
                    if isPromptActive then
                        HelpText(false)
                        isPromptActive = false
                    end
                end
            end
        end
    })

    signboardPoints[#signboardPoints + 1] = pointData
end

function AddSignBoard(coords, heading, homeId)
    local inputDialog = lib.inputDialog(locale("signboard"), {
        { type = "input", label = locale("title"), required = true },
        { type = "input", label = locale("logo_url") },
        { type = "input", label = locale("subtitle"), required = true },
        { type = "input", label = locale("description"), required = true },
        { type = "input", label = locale("footer"), description = locale("footer_signboard"), required = true }
    })

    if not inputDialog then
        return
    end

    signboard = {
        coords = ToVector3(coords),
        heading = heading,
        text = inputDialog,
        homeId = homeId
    }

    lib.callback("Housing:server:AddSignboard", false, function(result)
        if result then
            LoadSignboard(result)
            Notify(locale("housing"), locale("create_sign_successful"), "success", 3000)
        end
    end, signboard)
end

RegisterCommand(commands.createsign.name, function()
    local nearestHome = GetNearestHome()
    if not nearestHome then
        return Notify(locale("housing"), locale("not_near_any_home"), "error", 3000)
    end

    local isAllowed = false
    if PlayerData and PlayerData.job and JobConfig.jobs[PlayerData.job.name] then
        isAllowed = PlayerData.job.name == nearestHome.properties.realestate
    end

    if not isAllowed and not isAdmin() then
        return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
    end

    HelpText(true, locale("prompt_sign_placement"))
    pcall(lib.requestModel, -1865284458)
    local previewObject = CreateObject(-1865284458, GetEntityCoords(cache.ped))
    SetModelAsNoLongerNeeded(-1865284458)

    local heading = 0.0
    SetEntityAlpha(previewObject, Config.FurnitureAlpha)
    SetEntityCollision(previewObject, false)
    FreezeEntityPosition(previewObject, true)

    while true do
        Wait(0)
        local hit, _, endCoords = lib.raycast.cam(nil, nil, 50)
        if hit then
            SetEntityCoords(previewObject, endCoords)
        end

        DisableControlAction(0, 175)
        DisableControlAction(0, 174)
        DisableControlAction(0, 38)
        DisableControlAction(0, 73)

        if IsDisabledControlJustPressed(0, 38) then
            Notify(locale("realestate"), locale("spawn_point_added"))
            HelpText(false)
            AddSignBoard(endCoords, heading, nearestHome.identifier)
            DeleteEntity(previewObject)
            break
        elseif IsDisabledControlJustPressed(0, 73) then
            Notify(locale("realestate"), locale("garage_canceled"))
            HelpText(false)
            DeleteEntity(previewObject)
            break
        end

        if IsDisabledControlPressed(0, 175) then
            if heading <= 355 then
                heading = heading + 1.0
                SetEntityHeading(previewObject, heading)
            end
        elseif IsDisabledControlPressed(0, 174) and heading >= 5 then
            heading = heading - 1.0
            SetEntityHeading(previewObject, heading)
        end
    end
end)

AddEventHandler("onResourceStop", function()
    for _, signData in pairs(spawnedSigns) do
        if signData.object then
            DeleteEntity(signData.object)
        end
    end
end)