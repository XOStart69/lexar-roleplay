local Config = require "config.config"
local DrawTextScale = Config.DefaultSettings.drawtextScale or 0.35

NuiLoaded = false
ConfigLoaded = false
WritingEffect = false
WritingPlayers = {}
ActiveSong = {}
RPTexts = {}
RPTextThread = false
ThreadType = 'native'
Dots = ""

local function GetWebLocales()
    local path = 'locales/' .. Config.Locale .. '.json'
    local file = LoadResourceFile(GetCurrentResourceName(), path)

    if not file then
        file = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
    end

    if not file or file == '' then
        return {}
    end

    local success, content = pcall(json.decode, file)
    if not success or not content or not content['Web'] then
        return {}
    end

    return content['Web']
end

local function CheckNui()
    while not NuiLoaded do
        Wait(100)
    end
end

function SendVueMessage(action, payload)
    CheckNui()
    SendNUIMessage({
        action = action,
        payload = payload
    })
end

local function FetchNui()
    while not NuiLoaded do
        if NetworkIsSessionStarted() then
            SendNUIMessage({ action = "CHECK_NUI" })
        end
        Wait(2000)
    end

    SendVueMessage("SET_CONFIG", {
        Themes = Config.Themes,
        ThemeColors = Config.ThemeColors,
        MessageColors = Config.MessageColors,
        Categories = Config.Categories,
        QuickCommands = Config.QuickCommands,
        AllowedURLs = Config.ImageSettings.allowedURLs,
        Emojis = Config.Emojis,
        Locales = GetWebLocales(),
    })
end

function DrawDots(coords, text)
    local defaultScale = 0.65
    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)
    local scale = 200 / (GetGameplayCamFov() * dist)

    SetTextColour(255, 255, 255, 255)
    SetTextFont(0)
    SetTextScale(0.0, defaultScale * scale)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function DrawText3D(x, y, z, text, color)
    local camCoords = GetGameplayCamCoord()
    local dist = #(vector3(x, y, z) - camCoords)
    local scale = 200 / (GetGameplayCamFov() * dist)

    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextScale(0.0, DrawTextScale * scale)
    SetTextFont(4)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function UpdateRPTexts(source, data)
    for k, v in ipairs(RPTexts) do
        if v.source == source then
            RPTexts[k] = data
            return
        end
    end
    table.insert(RPTexts, data)
end

function CheckMask()
    if not Config.AnonymousWithMask then return false end

    local ped = cache.ped
    local pedModel = GetEntityModel(ped)

    if not Config.MaskIndexs[pedModel] then return false end

    local currentMaskIndex = GetPedDrawableVariation(ped, 1)

    if Config.AnyMask then
        return currentMaskIndex > 0
    end

    return Config.MaskIndexs[pedModel][tostring(currentMaskIndex)] == true
end

RegisterNetEvent('sm_chatheme:client:onPlayerLoaded', function()
    Wait(1500)
    FetchNui()
end)

RegisterNetEvent('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(1500)
        FetchNui()
    end
end)

RegisterKeyMapping("+chat", "Show chat", "KEYBOARD", Config.ShowChatKey or "T")
RegisterCommand("+chat", function()
    TriggerEvent("chat:show")
end, false)

AddEventHandler('sm_chatheme:client:playSound', function(name)
    if type(name) ~= 'string' or not name:match('^[%w_%-]+$') then return end

    SendVueMessage('PLAY_SOUND', { name = name })
end)

RegisterNetEvent('sm_chatheme:client:sendMessage', function(data)
    if not data then return end

    SendVueMessage('SEND_MESSAGE', data)

    local isRPCategory = data.category == 'do' or data.category == 'me' or data.category == 'dice' or data.category == 'rps'
    if not isRPCategory or data.isImage then return end

    UpdateRPTexts(data.source, data)

    if ThreadType == 'dui' then
        RPTextsDUIThread()
    else
        RPTexts3DThread()
    end

    Wait(5000)

    for k, v in ipairs(RPTexts) do
        if v.source == data.source and v.category == data.category and v.message == data.message then
            if ThreadType == 'dui' then
                SendVueMessage("REMOVE_3D_TEXT", { source = v.source })
            end
            table.remove(RPTexts, k)
            break
        end
    end
end)

RegisterNetEvent('sm_chatheme:client:writingText', function(source, isWriting)
    if isWriting then
        WritingPlayers[tostring(source)] = true
        if not WritingEffect then
            FWritingEffect()
        end
    else
        WritingPlayers[tostring(source)] = nil
    end
end)

RegisterNetEvent('sm_chatheme:client:selfCommandSuggestion', function(command, help, params)
    TriggerEvent('chat:addSuggestion', command, help, params)

    SendVueMessage("ADD_CHAT_COMMAND_SUGGESTION", {
        command = string.gsub(command, "/", ""),
        description = help,
        params = params or {}
    })
end)