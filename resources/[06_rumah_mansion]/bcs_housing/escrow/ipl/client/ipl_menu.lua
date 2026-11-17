local ignoredActionKeys = {
    Set = true,
    Clear = true,
    Enable = true,
    Color = true,
    Safe = true,
}

local actionMethodNames = {
    "Set",
    "Enable",
    "Clear",
    "SetColor",
    "Open",
    "Close",
}

local multiArgKeys = {
    Furnitures = true,
    Theme = true,
    Pumps = true,
    Color = true,
    Walls = true,
}

local isChangesConfirmed = false

local ignoredIplKeys = {
    interiorId = true,
    Ipl = true,
    currentInteriorId = true,
    currentSafeDoors = true,
    Clear = true,
    controlModelHash = true,
    Banner = true,
}

local customObjectExports = {
    Clubhouse1 = "GetBikerGangObject",
    Clubhouse2 = "GetBikerGangObject",
    ["Office 1 (Arcadius Business Centre)"] = "GetFinanceOrganizationObject",
    ["Office 2 (Maze Bank Building)"] = "GetFinanceOrganizationObject",
    ["Office 3 (Lom Bank)"] = "GetFinanceOrganizationObject",
    ["Office 4 (Maze Bank West)"] = "GetFinanceOrganizationObject",
}

local disablableFeatures = {
    "DryIce",
}

IplMenu = lib.class("IplMenu")

function IplMenu:constructor(entry, prices, iplObject, name, isVisiting)
    self.id = nil
    self.aptId = nil

    for key, value in pairs(iplObject) do
        if key == "Interior" then
            value.LoadDefault = iplObject.LoadDefault
            iplObject = value
            break
        end
    end

    self.isVisiting = isVisiting
    self.entry = entry
    self.prices = prices
    self.iplObject = iplObject
    self.custom = customObjectExports[name] ~= nil
    self.customObject = nil
    self.name = name
    self.cam = nil

    if self.custom then
        self.customObject = exports[Config.exportname.bob74_ipl][customObjectExports[name]]()
    end
end

function IplMenu:LoadDefault()
    for key, LoadDefaultFunc in pairs(self.iplObject) do
        if key == "LoadDefault" then
            LoadDefaultFunc()
            break
        end
    end
end

function IplMenu:Load(id, aptId)
    self.id = id
    self.aptId = aptId
    self:LoadDefault()
    Wait(100)

    local loadedData = {}
    if not self.isVisiting then
        loadedData = lib.callback.await("Housing:server:GetDataCustomizeIPL", false, self.id, self.aptId) or {}
    end

    self.data = loadedData

    for key, value in pairs(self.data) do
        if multiArgKeys[key] then
            self:Set(key, value[1], value[2])
        else
            self:Set(key, value)
        end
    end

    self:CreateMenu()
end

function IplMenu:Set(key, value, secondaryValue)
    local splitKeys = SplitString(key, "%.")
    if self.customObject then
        if splitKeys[1] == "Name" then
            if #value > 1 then
                self.customObject.Name.Set(value[1], value[2], value[3], value[4])
                if self.customObject.Office then
                    self.customObject.Office.Enable(true)
                end
                if self.customObject.Clubhouse then
                    self.customObject.Clubhouse.ClubName.Enable(true)
                end
                return
            end
        elseif splitKeys[1] == "Emblem" then
            self.customObject.Emblem.Set(value, 90.0)
            self.customObject.Clubhouse.Emblem.Enable(true)
            return
        end
    end

    local nestedValue = GetNestedValue(self.iplObject, splitKeys)
    if not nestedValue then
        return
    end

    if secondaryValue then
        if nestedValue.Set then
            nestedValue.Set(value, secondaryValue, true)
        end
        self.data[splitKeys[1]] = { value, secondaryValue }
    else
        if nestedValue.Set then
            nestedValue.Set(value, true)
        elseif nestedValue.Enable then
            nestedValue.Enable(value, true, true)
        elseif nestedValue.SetColor then
            nestedValue.SetColor(value, true)
        end
        self.data[splitKeys[1]] = value
    end

    self:CreateMenu()
end

function IplMenu:CreateMenu()
    local pendingChanges = {}
    local menuOptions = {}

    local function addOption(optionKey, optionData, parentKey)
        local targetMenu = menuOptions
        if parentKey then
            if not menuOptions[parentKey] then
                menuOptions[parentKey] = {}
            end
            targetMenu = menuOptions[parentKey]
        end

        local hasMultiKey, multiKey = TableContainsKey(optionData, { "Theme", "Pumps", "Color" })
        if optionKey == "Safe" then
            local function setSafeDoorPreview(doorName, isOpen)
                local fullKey = parentKey and (parentKey .. "." .. optionKey) or optionKey
                pendingChanges[fullKey] = isOpen
                self:SetCamIPL(fullKey, true)
                local doorIndex = SplitString(doorName, " ")[2]
                if isOpen then
                    self.iplObject.Safe.Open(doorIndex)
                else
                    self.iplObject.Safe.Close(doorIndex)
                end
            end

            for _, door in ipairs({ "left door", "right door" }) do
                table.insert(targetMenu, {
                    label = string.format("Safe %s", door),
                    description = string.format("Open or Close the %s", optionKey),
                    checked = self.data[optionKey] or false,
                    value = string.format("%s %s", optionKey, door),
                    setPreview = setSafeDoorPreview,
                })
            end
        elseif hasMultiKey then
            local selectValues = {}
            for label, val in pairs(optionData[multiKey]) do
                table.insert(selectValues, {
                    label = string.format("%s $%s", label, self.prices[optionKey] or 0),
                    value = val,
                })
            end

            for subKey, subVal in pairs(optionData) do
                if not ignoredActionKeys[subKey] then
                    local defaultVal = self.data[optionKey]
                    if type(defaultVal) == "table" then
                        defaultVal = self.data[optionKey][2] or self.data[optionKey]
                    end

                    table.insert(targetMenu, {
                        label = string.format("%s %s", optionKey, subKey),
                        description = locale("change_option", subKey),
                        close = false,
                        values = selectValues,
                        defaultIndex = GetDefaultValueByData(selectValues, defaultVal),
                        setPreview = function(val)
                            local fullKey = parentKey and (parentKey .. "." .. optionKey) or optionKey
                            self:SetCamIPL(fullKey, true)
                            if multiKey == "Color" and optionKey == "Walls" then
                                pendingChanges[fullKey] = { subVal, val }
                                self:Set(fullKey, subVal, val)
                            else
                                pendingChanges[fullKey] = val
                                self:Set(fullKey, val)
                            end
                            local playerCoords = GetEntityCoords(cache.ped)
                            SetEntityCoords(cache.ped, playerCoords.x, playerCoords.y, playerCoords.z - 1.0)
                        end,
                    })
                end
            end
        elseif optionKey == "LoadDefault" then
            table.insert(targetMenu, {
                label = locale("load_default"),
                description = locale("load_default_desc"),
            })
        elseif type(optionData) ~= "table" or not optionData.__cfx_functionReference then
            local values = GenerateValues(optionData, self.prices[optionKey] or 0)
            for i = 1, #disablableFeatures do
                if optionKey == disablableFeatures[i] then
                    table.insert(values, {
                        label = "Disable",
                        value = false,
                    })
                    break
                end
            end

            if values and #values > 0 then
                table.insert(targetMenu, {
                    label = optionKey,
                    description = locale("change_option", optionKey),
                    values = values,
                    close = false,
                    defaultIndex = self.data[optionKey] and GetDefaultValueByData(values, self.data[optionKey]) or nil,
                    setPreview = function(val)
                        local fullKey = parentKey and (parentKey .. "." .. optionKey) or optionKey
                        self:SetCamIPL(fullKey, true)
                        if optionKey == "Furnitures" then
                            pendingChanges[fullKey] = { val, 3 }
                            self:Set(fullKey, val, 3)
                        else
                            pendingChanges[fullKey] = val
                            self:Set(fullKey, val)
                        end
                    end,
                })
            end
        end
    end

    for key, val in pairs(self.iplObject) do
        if not ignoredIplKeys[key] then
            if key == "Lights" or (type(val) == "table" and not TableContainsKey(val, actionMethodNames) and key ~= "LoadDefault" and key ~= "Colors") then
                for subKey, subVal in pairs(val) do
                    if type(subVal) ~= "string" and not ignoredIplKeys[subKey] then
                        addOption(subKey, subVal, key)
                    end
                end
            elseif key == "Walls" and val.SetColor then
                addOption(key, self.iplObject.Colors)
            else
                addOption(key, val)
            end
        end
    end

    if self.custom then
        local customObj = self.customObject
        if TableContainsKey(customObj, "Name") then
            local nameConfig = customObj.Name
            table.insert(menuOptions, {
                label = locale("set_org_name"),
                description = locale("set_org_name_desc"),
                openDialog = function()
                    local dialogRows = {
                        {
                            type = "input",
                            label = locale("name"),
                            required = true,
                        },
                    }

                    if nameConfig.Style then
                        table.insert(dialogRows, {
                            type = "select",
                            label = locale("style"),
                            options = GenerateValues(nameConfig.Style, 0),
                        })
                    end

                    if nameConfig.Colors and nameConfig.Fonts then
                        table.insert(dialogRows, {
                            type = "select",
                            label = locale("color"),
                            options = GenerateValues(nameConfig.Colors, 0),
                        })
                        table.insert(dialogRows, {
                            type = "select",
                            label = locale("color"),
                            options = GenerateValues(nameConfig.Fonts, 0),
                        })
                    end

                    self:SetCamIPL("Name", true)
                    local input = lib.inputDialog(locale("set_org_name"), dialogRows)
                    if not input then
                        return
                    end

                    local orgName = input[1]
                    local style = tonumber(input[2])
                    local color = tonumber(input[3])
                    local font = tonumber(input[4])
                    local nameData = { orgName, style, color, font }

                    TriggerServerEvent("Housing:server:SetDataCustomizeIPL", self.id, self.aptId, "Name", nameData)
                    self:Set("Name", nameData)
                    self:DestroyCam()
                end,
            })
        end

        if TableContainsKey(customObj, "Emblem") then
            local emblemValues = GenerateValues(customObj.Emblem.Logo, 0)
            table.insert(menuOptions, {
                label = locale("set_emblem"),
                description = locale("set_emblem_desc"),
                values = emblemValues,
                defaultIndex = GetDefaultValueByData(emblemValues, self.data.Emblem),
                setPreview = function(val)
                    pendingChanges.Emblem = val
                    self:SetCamIPL("Emblem", true)
                    self:Set("Emblem", val)
                end,
            })
        end
    end

    table.sort(menuOptions, function(a, b)
        return a.label < b.label
    end)

    table.insert(menuOptions, {
        label = locale("confirm"),
        description = locale("confirm_change"),
    })

    local mainOptions = {}
    for i = 1, #menuOptions do
        table.insert(mainOptions, menuOptions[i])
    end

    for categoryName, categoryOptions in pairs(menuOptions) do
        if type(categoryName) ~= "number" then
            table.insert(mainOptions, {
                label = categoryName,
                description = locale("category"),
                value = "submenu",
            })

            lib.registerMenu({
                id = categoryName .. "_submenu",
                title = categoryName,
                options = categoryOptions,
                onClose = function()
                    lib.showMenu("custom_ipl_menu")
                end,
                onSideScroll = function(selected, scrollIndex)
                    local option = categoryOptions[selected]
                    if option.setPreview then
                        option.setPreview(option.values[scrollIndex].value)
                    end
                end,
            }, function(selected, scrollIndex, args)
                local option = categoryOptions[selected]
                if option.openDialog then
                    option.openDialog()
                    return
                end
            end)
        end
    end

    lib.registerMenu({
        id = "custom_ipl_menu",
        title = locale("customize_ipl"),
        options = mainOptions,
        onSideScroll = function(selected, scrollIndex)
            local option = mainOptions[selected]
            if option.setPreview and option.values[scrollIndex] then
                option.setPreview(option.values[scrollIndex].value)
            end
        end,
        onCheck = function(selected, checked)
            local option = menuOptions[selected]
            if option.setPreview then
                option.setPreview(option.value, checked)
            end
        end,
        onClose = function()
            if not isChangesConfirmed then
                self:Load(self.id, self.aptId)
                local playerCoords = GetEntityCoords(cache.ped)
                SetEntityCoords(cache.ped, playerCoords.x, playerCoords.y, playerCoords.z - 1.0)
                self:DestroyCam()
            end
            isChangesConfirmed = false
        end,
    }, function(selected, scrollIndex, args)
        local option = mainOptions[selected]
        if option.value == "submenu" then
            lib.hideMenu()
            Wait(100)
            lib.showMenu(option.label .. "_submenu")
            return
        end

        if option.openDialog then
            option.openDialog()
            return
        end

        if option.label == "Load Default" then
            local alert = lib.alertDialog({
                header = locale("load_default"),
                content = locale("load_default_confirmation"),
                cancel = true,
                labels = {
                    cancel = locale("no"),
                    confirm = locale("yes"),
                },
            })
            if alert == "confirm" then
                TriggerServerEvent("Housing:server:LoadDefaultCustomizeIPL", self.id, self.aptId)
            end
            return
        end

        if option.label == locale("confirm") then
            local totalPrice = 0
            for changeKey in pairs(pendingChanges) do
                totalPrice = totalPrice + (self.prices[changeKey] or 0)
            end

            local alert = lib.alertDialog({
                header = locale("confirm"),
                content = locale("confirm_changes_total"),
                cancel = true,
                labels = {
                    cancel = locale("no"),
                    confirm = locale("yes"),
                },
            })

            self:DestroyCam()

            if alert == "confirm" then
                isChangesConfirmed = true
                if pendingChanges then
                    for changeKey, changeVal in pairs(pendingChanges) do
                        if TableContainsKey(changeVal, "Color") then
                            TriggerServerEvent("Housing:server:SetDataCustomizeIPL", self.id, self.aptId, changeKey, changeVal[1], changeVal[2])
                        else
                            TriggerServerEvent("Housing:server:SetDataCustomizeIPL", self.id, self.aptId, changeKey, changeVal)
                        end
                    end
                    return
                end
            end

            for changeKey, changeVal in pairs(self.data) do
                if type(changeVal) == "table" then
                    self:Set(changeKey, changeVal[1], changeVal[2])
                else
                    self:Set(changeKey, changeVal)
                end
            end
        end
    end)
end

function IplMenu:ShowMenu()
    lib.showMenu("custom_ipl_menu")
    SetTimeout(500, function()
        self:SetCamIPL()
    end)
end

function IplMenu:SetVisiting(isVisiting)
    self.isVisiting = isVisiting
end

function IplMenu:SetCamIPL(camKey, fade)
    local targetIplConfig = nil
    for i = 1, #CustomizeIPL do
        if CustomizeIPL[i].name == self.name then
            targetIplConfig = CustomizeIPL[i]
            break
        end
    end

    if not targetIplConfig or not targetIplConfig.cams then
        return
    end

    local function applyCamTransform(camCoords, camRotation)
        if fade then
            CreateThread(function()
                DoScreenFadeOut(500)
            end)
        end

        if not camCoords then
            return
        end

        SetCamCoord(self.cam, camCoords.x, camCoords.y, camCoords.z)
        if camRotation then
            SetCamRot(self.cam, camRotation.x, camRotation.y, camRotation.z, 2)
        end

        if fade then
            Wait(500)
            CreateThread(function()
                DoScreenFadeIn(500)
            end)
        end
    end

    local camData = targetIplConfig.cams[camKey] or targetIplConfig.cams.default
    if camData then
        local camOffset = vec3(
            camData[1].x + targetIplConfig.entry.x,
            camData[1].y + targetIplConfig.entry.y,
            camData[1].z + targetIplConfig.entry.z
        )

        if not self.cam then
            self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            RenderScriptCams(true, false, 0, true, false)
            SetCamActive(self.cam, true)
            applyCamTransform(camOffset, camData[2])
        elseif camData then
            applyCamTransform(camOffset, camData[2])
        end
    end
end

function IplMenu:DestroyCam()
    if self.cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(self.cam, false)
        self.cam = nil
    end
end

RegisterCommand("createcamipl", function(source, args)
    local camKey = args[1]
    local iplName = args[2] and table.concat(args, " ", 2) or nil
    local pedCoords = GetEntityCoords(cache.ped)
    local targetIpl = nil

    for i = 1, #CustomizeIPL do
        if not iplName then
            if #(CustomizeIPL[i].entry.xyz - pedCoords) <= 100 then
                targetIpl = CustomizeIPL[i]
                break
            end
        elseif CustomizeIPL[i].name == iplName then
            targetIpl = CustomizeIPL[i]
            break
        end
    end

    if not targetIpl then
        print("IPL not found")
        return
    end

    if #(pedCoords - targetIpl.entry.xyz) <= 100 then
        local heading = GetEntityHeading(cache.ped)
        local camCoords = GetEntityCoords(cache.ped) + vec3(0, 0, 1.5)
        local camRot = vec3(0.0, 0.0, heading)
        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

        RenderScriptCams(true, false, 0, true, false)
        SetCamActive(cam, true)
        SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
        SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 24, true)

        while true do
            Wait(0)
            camCoords = GetCamCoord(cam)
            local currentRot = GetCamRot(cam, 2)
            local radYaw = math.rad(currentRot.z)
            local cosYaw = math.cos(radYaw)
            local sinYaw = math.sin(radYaw)
            local lookX = GetControlNormal(0, 1) * 2.0
            local lookY = GetControlNormal(0, 2) * 2.0

            if lookX ~= 0.0 or lookY ~= 0.0 then
                SetCamRot(cam, currentRot.x - lookY, currentRot.y, currentRot.z - lookX, 2)
            end

            if IsControlJustPressed(0, 174) then
                SetCamCoord(cam, camCoords.x - cosYaw * 0.5, camCoords.y - sinYaw * 0.5, camCoords.z)
            elseif IsControlJustPressed(0, 175) then
                SetCamCoord(cam, camCoords.x + cosYaw * 0.5, camCoords.y + sinYaw * 0.5, camCoords.z)
            elseif IsControlJustPressed(0, 172) then
                SetCamCoord(cam, camCoords.x - sinYaw * 0.5, camCoords.y + cosYaw * 0.5, camCoords.z)
            elseif IsControlJustPressed(0, 173) then
                SetCamCoord(cam, camCoords.x + sinYaw * 0.5, camCoords.y - cosYaw * 0.5, camCoords.z)
            end

            if IsControlJustPressed(0, 18) then
                print(targetIpl.name)
                local formatTemplate = [[
                   ["%s"] = {
                       %s,
                       %s
                   },
                ]]
                local formattedOutput = string.format(
                    formatTemplate,
                    camKey or "default",
                    vec3(camCoords.x, camCoords.y, camCoords.z) - targetIpl.entry.xyz,
                    GetCamRot(cam, 2)
                )
                print(formattedOutput)
                RenderScriptCams(false, false, 0, true, false)
                DestroyCam(cam, false)
                break
            end
        end
    end
end, false)