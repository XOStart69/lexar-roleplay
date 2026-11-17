local Camera = exports[GetCurrentResourceName()]
local stepIndex = 5
local pointX = nil
local pointY = nil
local pointZ = nil
local currentHeight = nil
local referenceCoords = nil
local stepSizes = {
    0.05,
    0.1,
    0.25,
    0.5,
    1,
    2.5,
    5,
    10,
    25,
    50,
    100
}
local createdPoints = {}
local isCreating = false
local isPrecisionMode = false
local minStepThreshold = stepSizes[1] / 2

local function DrawWallPoly(points)
    DrawPoly(points[1].x, points[1].y, points[1].z, points[2].x, points[2].y, points[2].z, points[3].x, points[3].y, points[3].z, 255, 42, 24, 100)
    DrawPoly(points[2].x, points[2].y, points[2].z, points[1].x, points[1].y, points[1].z, points[3].x, points[3].y, points[3].z, 255, 42, 24, 100)
    DrawPoly(points[1].x, points[1].y, points[1].z, points[4].x, points[4].y, points[4].z, points[3].x, points[3].y, points[3].z, 255, 42, 24, 100)
    DrawPoly(points[4].x, points[4].y, points[4].z, points[1].x, points[1].y, points[1].z, points[3].x, points[3].y, points[3].z, 255, 42, 24, 100)
end

local function DrawAreaLines()
    local heightOffset = vec(0, 0, currentHeight / 2)
    local currentTop = vec(pointX, pointY, pointZ) + heightOffset
    local currentBottom = vec(pointX, pointY, pointZ) - heightOffset

    DrawLine(currentTop.x, currentTop.y, currentTop.z, currentBottom.x, currentBottom.y, currentBottom.z, 255, 42, 24, 225)

    local totalPoints = #createdPoints
    for i = 1, totalPoints do
        createdPoints[i] = vec(createdPoints[i].x, createdPoints[i].y, pointZ)
        local pointTop = createdPoints[i] + heightOffset
        local pointBottom = createdPoints[i] - heightOffset

        local nextPoint = createdPoints[i + 1] and vec(createdPoints[i + 1].x, createdPoints[i + 1].y, pointZ) or createdPoints[1]
        local nextTop = nextPoint + heightOffset
        local nextBottom = nextPoint - heightOffset
        local pointRef = createdPoints[i + 1] and vec(createdPoints[i + 1].x, createdPoints[i + 1].y, pointZ) or createdPoints[1]

        if i == totalPoints then
            DrawLine(pointTop.x, pointTop.y, pointTop.z, pointBottom.x, pointBottom.y, pointBottom.z, 255, 42, 24, 225)
            DrawLine(currentTop.x, currentTop.y, currentTop.z, nextTop.x, nextTop.y, nextTop.z, 255, 42, 24, 225)
            DrawLine(currentBottom.x, currentBottom.y, currentBottom.z, nextBottom.x, nextBottom.y, nextBottom.z, 255, 42, 24, 225)
            DrawLine(pointTop.x, pointTop.y, pointTop.z, currentTop.x, currentTop.y, currentTop.z, 255, 42, 24, 225)
            DrawLine(pointBottom.x, pointBottom.y, pointBottom.z, currentBottom.x, currentBottom.y, currentBottom.z, 255, 42, 24, 225)
            DrawLine(pointX, pointY, pointZ, pointRef.x, pointRef.y, pointRef.z, 255, 42, 24, 225)
            DrawLine(createdPoints[i].x, createdPoints[i].y, createdPoints[i].z, pointX, pointY, pointZ, 255, 42, 24, 225)
        else
            DrawLine(pointTop.x, pointTop.y, pointTop.z, pointBottom.x, pointBottom.y, pointBottom.z, 255, 42, 24, 225)
            DrawLine(pointTop.x, pointTop.y, pointTop.z, nextTop.x, nextTop.y, nextTop.z, 255, 42, 24, 225)
            DrawLine(pointBottom.x, pointBottom.y, pointBottom.z, nextBottom.x, nextBottom.y, nextBottom.z, 255, 42, 24, 225)
            DrawLine(createdPoints[i].x, createdPoints[i].y, createdPoints[i].z, pointRef.x, pointRef.y, pointRef.z, 255, 42, 24, 225)
        end

        if displayMode == 2 or displayMode == 4 then
            if i == totalPoints then
                DrawWallPoly({ pointTop, pointBottom, currentBottom, currentTop })
                DrawWallPoly({ currentTop, currentBottom, nextBottom, nextTop })
            end
        end
    end
end

function updateText(isPrecise)
    if not isPrecise then
        if IsResourceStarted("bcs_hud") then
            exports.bcs_hud:keybind({
                title = locale("polyzone_creation"),
                items = {
                    { description = locale("keybind_cancel"), buttons = { Config.keybinds.area.Cancel.help } },
                    { description = locale("keybind_finish"), buttons = { Config.keybinds.area.Confirm.help } },
                    { description = locale("keybind_change_mode"), buttons = { Config.keybinds.area.PrecisionMode.help } },
                    { description = locale("keybind_add_point"), buttons = { Config.keybinds.area.AddPoint.help } },
                    { description = locale("keybind_noclip"), buttons = { "W", "A", "S", "D" } },
                    { description = locale("keybind_noclip_updown"), buttons = { "Q", "E" } },
                    { description = locale("keybind_noclip_speed"), buttons = { "L Alt", "L Shift" } },
                    { description = locale("keybind_crease_height"), buttons = { "L Shift", "Scroll" } },
                    { description = locale("keybind_z_placement"), buttons = { "L Alt", "Scroll" } }
                }
            })
        else
            displayHelp(locale("prompt_create_mlo", Config.keybinds.area.Cancel.help, Config.keybinds.area.AddPoint.help, Config.keybinds.area.PrecisionMode.help, Config.keybinds.area.shift.help, Config.keybinds.area.scroll.help, Config.keybinds.area.alt.help, Config.keybinds.area.scroll.help, Config.keybinds.area.Confirm.help), "bottom-right")
        end
    else
        if IsResourceStarted("bcs_hud") then
            exports.bcs_hud:keybind({
                title = locale("polyzone_creation"),
                items = {
                    { description = locale("keybind_cancel"), buttons = { Config.keybinds.area.Cancel.help } },
                    { description = locale("keybind_finish"), buttons = { Config.keybinds.area.Confirm.help } },
                    { description = locale("keybind_change_mode"), buttons = { Config.keybinds.area.PrecisionMode.help } },
                    { description = locale("keybind_add_point"), buttons = { Config.keybinds.area.AddPoint.help } },
                    { description = locale("keybind_change_z"), buttons = { ",", "." } },
                    { description = locale("keybind_move_point"), buttons = { "\226\134\144", "\226\134\146", "\226\134\145", "\226\134\147" } },
                    { description = locale("keybind_noclip"), buttons = { "W", "A", "S", "D" } },
                    { description = locale("keybind_noclip_updown"), buttons = { "Q", "E" } },
                    { description = locale("keybind_noclip_speed"), buttons = { "L Alt", "L Shift" } }
                }
            })
        else
            displayHelp(locale("prompt_create_mlo_precise", Config.keybinds.area.Cancel.help, Config.keybinds.area.AddPoint.help, Config.keybinds.area.PrecisionMode.help, Config.keybinds.area.scroll.help, stepSizes[stepIndex], Config.keybinds.area.shift.help, Config.keybinds.area.scroll.help, Config.keybinds.area.alt.help, Config.keybinds.area.scroll.help, Config.keybinds.area.PrecisionMovement.help, Config.keybinds.area.Confirm.help), "bottom-right")
        end
    end
end

function CreatePoints(centerCoords)
    referenceCoords = centerCoords or referenceCoords
    stepIndex = 5
    local playerCoords = GetEntityCoords(cache.ped)
    pointX = round(playerCoords.x) + 0.0
    pointY = round(playerCoords.y) + 0.0
    pointZ = round(playerCoords.z) + 0.0
    currentHeight = 4.0
    createdPoints = {}
    Camera:SetActive(true)
    isCreating = true
    updateText(isPrecisionMode)

    CreateThread(function()
        while isCreating do
            Wait(0)
            if not IsDisabledControlPressed(0, Config.keybinds.area.shift.key) and not IsDisabledControlPressed(0, Config.keybinds.area.alt.key) then
                if not isPrecisionMode then
                    local hit, _, coords = lib.raycast.cam(nil, nil, 50)
                    local roundedX = round(coords.x)
                    local roundedY = round(coords.y)
                    if (roundedX ~= pointX or roundedY ~= pointY) and hit then
                        pointX = roundedX
                        pointY = roundedY
                    end
                end
            end
        end
    end)

    while isCreating do
        DrawAreaLines()

        if IsDisabledControlJustPressed(0, Config.keybinds.area.AddPoint.key) then
            local distance = #(vec2(pointX, pointY) - vec2(referenceCoords.x, referenceCoords.y))
            if distance <= Config.MaxDistance.FrontyardDistance then
                createdPoints[#createdPoints + 1] = vec2(pointX, pointY)
                Notify(locale("housing"), locale("point_added"), "success", 3000)
            else
                Notify(locale("housing"), locale("point_too_far"), "error", 3000)
            end
        elseif IsDisabledControlJustReleased(0, Config.keybinds.area.Confirm.key) then
            if #createdPoints > 2 then
                Camera:SetActive(false)
                isCreating = false
                closeHelp()
                return {
                    points = createdPoints,
                    height = currentHeight
                }
            else
                Notify(locale("housing"), locale("point_too_few"), "error", 3000)
            end
        elseif IsDisabledControlJustPressed(0, Config.keybinds.area.Cancel.key) then
            Camera:SetActive(false)
            isCreating = false
            Notify(locale("housing"), locale("canceled_area"), "success", 3000)
            closeHelp()
            return false
        end

        local step = stepSizes[stepIndex]
        if isPrecisionMode then
            if IsDisabledControlJustReleased(0, Config.keybinds.area.PrecisionMovement.key[1]) then
                local _, forward = Camera:GetMatrix()
                local newPos = vec3(pointX, pointY, pointZ) + forward * -step
                pointX = newPos.x
                pointY = newPos.y
            elseif IsDisabledControlJustReleased(0, Config.keybinds.area.PrecisionMovement.key[2]) then
                local _, forward = Camera:GetMatrix()
                local newPos = vec3(pointX, pointY, pointZ) + forward * step
                pointX = newPos.x
                pointY = newPos.y
            elseif IsDisabledControlJustReleased(0, Config.keybinds.area.PrecisionMovement.key[3]) then
                local right = Camera:GetMatrix()
                local newPos = vec3(pointX, pointY, pointZ) + right * -step
                pointX = newPos.x
                pointY = newPos.y
            elseif IsDisabledControlJustReleased(0, Config.keybinds.area.PrecisionMovement.key[4]) then
                local right = Camera:GetMatrix()
                local newPos = vec3(pointX, pointY, pointZ) + right * step
                pointX = newPos.x
                pointY = newPos.y
            end
        end

        if IsDisabledControlJustReleased(0, Config.keybinds.area.PrecisionMode.key) then
            isPrecisionMode = not isPrecisionMode
            updateText(isPrecisionMode)
            Notify(locale("housing"), locale("mode_changed"), "info", 3000)
        end

        if IsDisabledControlJustReleased(0, Config.keybinds.area.scroll.key[1]) then
            if IsDisabledControlPressed(0, Config.keybinds.area.shift.key) then
                change = true
                currentHeight = currentHeight + step
            elseif IsDisabledControlPressed(0, Config.keybinds.area.alt.key) then
                change = true
                local newZ = pointZ + step
                if math.abs(newZ) < minStepThreshold then
                    newZ = 0.0
                end
                pointZ = newZ
            else
                if stepIndex < 11 then
                    change = true
                    updateText(isPrecisionMode)
                    stepIndex = stepIndex + 1
                end
            end
        elseif IsDisabledControlJustReleased(0, Config.keybinds.area.scroll.key[2]) then
            if IsDisabledControlPressed(0, Config.keybinds.area.shift.key) then
                change = true
                if (currentHeight - step) > step then
                    currentHeight = currentHeight - step
                else
                    if (currentHeight - step) > 0 then
                        currentHeight = step
                    end
                end
            elseif IsDisabledControlPressed(0, Config.keybinds.area.alt.key) then
                change = true
                local newZ = pointZ - step
                if math.abs(newZ) < minStepThreshold then
                    newZ = 0.0
                end
                pointZ = newZ
            else
                if stepIndex > 1 then
                    change = true
                    updateText(isPrecisionMode)
                    stepIndex = stepIndex - 1
                end
            end
        end

        Wait(0)
    end
end

local function MakeAreaRelative(areaData, centerCoords)
    if not areaData or not areaData.points or not centerCoords then
        return nil
    end

    local relativeArea = {
        points = {},
        height = areaData.height
    }

    for i = 1, #areaData.points do
        local point = areaData.points[i]
        relativeArea.points[#relativeArea.points + 1] = {
            x = point.x - centerCoords.x,
            y = point.y - centerCoords.y,
            z = point.z - centerCoords.z
        }
    end

    return relativeArea
end

local function RotatePresetPoints(presetData, heading)
    if not presetData or not presetData.points then
        return presetData
    end

    local rotatedArea = {
        points = {},
        height = presetData.height
    }

    local rad = math.rad(heading)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    for i = 1, #presetData.points do
        local point = presetData.points[i]
        rotatedArea.points[#rotatedArea.points + 1] = {
            x = (point.x * cos) - point.y * sin,
            y = (point.x * sin) + point.y * cos,
            z = point.z
        }
    end

    return rotatedArea
end

local function TranslatePresetPoints(presetData, centerCoords)
    if not presetData or not presetData.points or not centerCoords then
        return nil
    end

    local translatedArea = {
        points = {},
        height = presetData.height
    }

    for i = 1, #presetData.points do
        local point = presetData.points[i]
        translatedArea.points[#translatedArea.points + 1] = {
            x = centerCoords.x + point.x,
            y = centerCoords.y + point.y,
            z = centerCoords.z + point.z
        }
    end

    return translatedArea
end

local function TransformPresetPoints(presetData, centerCoords, heading)
    if not presetData or not presetData.points or not centerCoords then
        return nil
    end

    heading = heading or 0
    local rotatedArea = RotatePresetPoints(presetData, heading)
    return TranslatePresetPoints(rotatedArea, centerCoords)
end

function ApplyAreaPresetMode(preset, centerCoords)
    if not preset or not centerCoords then
        return nil
    end

    local posX = centerCoords.x
    local posY = centerCoords.y
    local posZ = centerCoords.z
    local rotation = 0
    local step = 1.0
    local isApplying = true
    local transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)

    Camera:SetActive(true)

    if IsResourceStarted("bcs_hud") then
        exports.bcs_hud:keybind({
            title = locale("area_preset_application"),
            items = {
                { description = locale("keybind_cancel"), buttons = { Config.keybinds.area.Cancel.help } },
                { description = locale("keybind_apply_preset"), buttons = { Config.keybinds.area.Confirm.help } },
                { description = locale("keybind_rotate_preset"), buttons = { Config.keybinds.area.alt.help, Config.keybinds.area.scroll.help } },
                { description = locale("keybind_adjust_preset_height"), buttons = { Config.keybinds.area.shift.help, Config.keybinds.area.scroll.help } },
                { description = locale("keybind_adjust_center_height"), buttons = { Config.keybinds.area.scroll.help } },
                { description = locale("keybind_move_preset_center"), buttons = { Config.keybinds.area.PrecisionMovement.help } }
            }
        })
    else
        displayHelp(locale("preset_mode_help", Config.keybinds.area.Cancel.help, Config.keybinds.area.Confirm.help, Config.keybinds.area.alt.help, Config.keybinds.area.scroll.help, Config.keybinds.area.shift.help, Config.keybinds.area.scroll.help, Config.keybinds.area.IncreaseDecreaseHeight.help, Config.keybinds.area.PrecisionMovement.help, Config.keybinds.area.ChangeStep.help), "bottom-right")
    end

    CreateThread(function()
        while isApplying do
            Wait(0)
            if transformedArea and transformedArea.points then
                local heightOffset = vec(0, 0, transformedArea.height / 2)
                for i = 1, #transformedArea.points do
                    local point = vec(transformedArea.points[i].x, transformedArea.points[i].y, posZ)
                    local nextPointRaw = transformedArea.points[i + 1] or transformedArea.points[1]
                    local nextPoint = vec(nextPointRaw.x, nextPointRaw.y, posZ)

                    local topA = point + heightOffset
                    local bottomA = point - heightOffset
                    local topB = nextPoint + heightOffset
                    local bottomB = nextPoint - heightOffset

                    DrawLine(topA.x, topA.y, topA.z, bottomA.x, bottomA.y, bottomA.z, 0, 255, 0, 225)
                    DrawLine(topA.x, topA.y, topA.z, topB.x, topB.y, topB.z, 0, 255, 0, 225)
                    DrawLine(bottomA.x, bottomA.y, bottomA.z, bottomB.x, bottomB.y, bottomB.z, 0, 255, 0, 225)
                    DrawLine(point.x, point.y, point.z, nextPoint.x, nextPoint.y, nextPoint.z, 0, 255, 0, 225)
                end

                DrawMarker(1, posX, posY, posZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
            end

            if IsDisabledControlJustPressed(0, Config.keybinds.area.Cancel.key) then
                Camera:SetActive(false)
                closeHelp()
                Notify(locale("housing"), locale("preset_application_cancelled"), "info", 3000)
                transformedArea = false
                isApplying = false
                break
            elseif IsDisabledControlJustPressed(0, Config.keybinds.area.Confirm.key) then
                Camera:SetActive(false)
                closeHelp()
                Notify(locale("housing"), locale("preset_applied_successfully"), "success", 3000)
                isApplying = false
                break
            elseif IsDisabledControlJustReleased(0, Config.keybinds.area.scroll.key[1]) then
                if IsDisabledControlPressed(0, Config.keybinds.area.alt.key) then
                    rotation = (rotation + 15) % 360
                    transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
                    Notify(locale("housing"), locale("preset_rotation", rotation), "info", 1000)
                elseif IsDisabledControlPressed(0, Config.keybinds.area.shift.key) then
                    transformedArea.height = transformedArea.height + step
                    Notify(locale("housing"), locale("preset_height", transformedArea.height), "info", 1000)
                else
                    step = step + 0.1
                    Notify(locale("housing"), locale("preset_step", string.format("%.2f", step)), "info", 1000)
                end
            elseif IsDisabledControlJustReleased(0, Config.keybinds.area.scroll.key[2]) then
                if IsDisabledControlPressed(0, Config.keybinds.area.alt.key) then
                    rotation = (rotation - 15) % 360
                    transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
                    Notify(locale("housing"), locale("preset_rotation", rotation), "info", 1000)
                elseif IsDisabledControlPressed(0, Config.keybinds.area.shift.key) then
                    if (transformedArea.height - step) > step then
                        transformedArea.height = transformedArea.height - step
                    elseif (transformedArea.height - step) > 0 then
                        transformedArea.height = step
                    end
                    Notify(locale("housing"), locale("preset_height", transformedArea.height), "info", 1000)
                else
                    if (step - 0.1) > 0.1 then
                        step = step - 0.1
                    else
                        step = 0.1
                    end
                    Notify(locale("housing"), locale("preset_step", string.format("%.2f", step)), "info", 1000)
                end
            elseif IsDisabledControlJustPressed(0, Config.keybinds.area.IncreaseDecreaseHeight.key[1]) then
                posZ = posZ + step
                transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
                Notify(locale("housing"), locale("preset_center_height", string.format("%.2f", posZ)), "info", 1000)
            elseif IsDisabledControlJustPressed(0, Config.keybinds.area.IncreaseDecreaseHeight.key[2]) then
                posZ = posZ - step
                transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
                Notify(locale("housing"), locale("preset_center_height", string.format("%.2f", posZ)), "info", 1000)
            elseif IsDisabledControlJustPressed(0, Config.keybinds.area.PrecisionMovement.key[1]) then
                local _, forward = Camera:GetMatrix()
                local newPos = vec3(posX, posY, posZ) + forward * step
                posX = newPos.x
                posY = newPos.y
                transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
            elseif IsDisabledControlJustPressed(0, Config.keybinds.area.PrecisionMovement.key[2]) then
                local _, forward = Camera:GetMatrix()
                local newPos = vec3(posX, posY, posZ) + forward * -step
                posX = newPos.x
                posY = newPos.y
                transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
            elseif IsDisabledControlJustPressed(0, Config.keybinds.area.PrecisionMovement.key[3]) then
                local right = Camera:GetMatrix()
                local newPos = vec3(posX, posY, posZ) + right * step
                posX = newPos.x
                posY = newPos.y
                transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
            elseif IsDisabledControlJustPressed(0, Config.keybinds.area.PrecisionMovement.key[4]) then
                local right = Camera:GetMatrix()
                local newPos = vec3(posX, posY, posZ) + right * -step
                posX = newPos.x
                posY = newPos.y
                transformedArea = TransformPresetPoints(preset, vec3(posX, posY, posZ), rotation)
            end
        end
    end)

    while isApplying do
        Wait(100)
    end

    return transformedArea
end

RegisterNetEvent("Housing:client:CreateArea", function(homeData, shouldCreateThumbnail)
    referenceCoords = homeData.entry
    local inputDialog = lib.inputDialog(locale("area_creation_mode"), {
        {
            type = "select",
            label = locale("creation_method"),
            description = locale("creation_method_desc"),
            options = {
                { value = "manual", label = locale("manual_creation") },
                { value = "preset", label = locale("use_area_preset") }
            },
            required = true
        }
    })

    if not inputDialog or not inputDialog[1] then
        Notify(locale("housing"), locale("area_creation_cancelled"), "info", 3000)
        return
    end

    local method = inputDialog[1]
    if method == "manual" then
        homeData.area = CreatePoints()
        if homeData.area then
            if shouldCreateThumbnail then
                homeData.thumbnail = CreateThumbnail()
            end
            TriggerServerEvent("Housing:server:CreateHome", homeData)
        end
    elseif method == "preset" then
        lib.callback("Housing:server:GetAreaPresets", false, function(presets)
            if not presets or #presets == 0 then
                Notify(locale("housing"), locale("no_area_presets"), "error", 5000)
                return
            end

            local presetOptions = {}
            for i = 1, #presets do
                presetOptions[#presetOptions + 1] = {
                    value = i,
                    label = presets[i].name,
                    description = "Points: " .. #presets[i].preset.points .. ", Height: " .. presets[i].preset.height
                }
            end

            local selectionInput = lib.inputDialog(locale("select_area_preset"), {
                {
                    type = "select",
                    label = locale("available_presets"),
                    description = locale("choose_preset_desc"),
                    options = presetOptions,
                    required = true
                }
            })

            if not selectionInput or not selectionInput[1] then
                Notify(locale("housing"), locale("preset_selection_cancelled"), "info", 3000)
                return
            end

            local selectedPreset = presets[selectionInput[1]]
            if selectedPreset then
                Notify(locale("housing"), locale("applying_preset", selectedPreset.name), "info", 3000)
                local appliedArea = ApplyAreaPresetMode(selectedPreset.preset, homeData.entry)
                if appliedArea then
                    homeData.area = appliedArea
                    if shouldCreateThumbnail then
                        homeData.thumbnail = CreateThumbnail()
                    end
                    TriggerServerEvent("Housing:server:CreateHome", homeData)
                end
            end
        end)
    end
end)

RegisterCommand(commands.setarea.name, function()
    local nearestHome = GetNearestHome()
    if nearestHome then
        lib.callback("Housing:server:CheckAllowed", false, function(isAllowed)
            if not isAllowed then
                return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
            end

            local entryCoords = nearestHome.properties.entry
            if nearestHome.properties.complex == "Flat" and nearestHome.properties.data.flat.coords then
                entryCoords = nearestHome.properties.data.flat.coords
            end

            referenceCoords = entryCoords
            local area = CreatePoints()
            if area then
                TriggerServerEvent("Housing:server:AddArea", nearestHome.identifier, area)
            end
        end, "area")
    else
        Notify(locale("housing"), locale("not_near_any_home"), "error", 3000)
    end
end, false)

RegisterCommand(commands.createzonepreset.name, function(_, args)
    lib.callback("Housing:server:CheckAllowed", false, function(isAllowed)
        if not isAllowed then
            return Notify(locale("housing"), locale("not_allowed"), "error", 3000)
        end

        local presetName = args[1]
        if not presetName or presetName == "" then
            TriggerEvent("Housing:notify", locale("housing"), locale("preset_name_required"), "error", 5000)
            return
        end

        local centerCoords = GetCoordsHeading("Center")
        Notify(locale("housing"), locale("creating_area_preset", presetName), "info", 3000)

        local createdArea = CreatePoints(centerCoords)
        if createdArea then
            local relativeArea = MakeAreaRelative(createdArea, centerCoords)
            if relativeArea then
                TriggerServerEvent("Housing:server:SaveAreaPreset", presetName, relativeArea)
                Notify(locale("housing"), locale("area_preset_created", presetName), "success", 5000)
            else
                Notify(locale("housing"), locale("failed_calculate_preset"), "error", 3000)
            end
        else
            Notify(locale("housing"), locale("area_creation_cancelled"), "info", 3000)
        end
    end, "createhome")
end, false)