phoneData = nil
currentPhone = nil
settings = nil
phoneOpen = false
SavedLocations = {}
PhoneOnScreen = false

local playerLoaded
local fetchingPhone
local configReceived
local loadedPhoneNumber
local toggling = false
local focusWaiting = false

local function waitForConfig()
    if configReceived then
        return
    end
    debugprint("waiting for config to be received")
    while not configReceived do
        Wait(0)
    end
    debugprint("config received")
end

function FetchPhone()
    debugprint("FetchPhone triggered")
    if fetchingPhone then
        debugprint("already fetching phone")
        return
    elseif not configReceived then
        debugprint("config has not been received by the UI yet")
        return
    end
    fetchingPhone = true
    while not FrameworkLoaded do
        debugprint("waiting for framework to load")
        Wait(500)
    end
    debugprint("triggering phone:playerLoaded")
    local number
    if playerLoaded and currentPhone then
        number = loadedPhoneNumber
    else
        number = AwaitCallback("playerLoaded")
        loadedPhoneNumber = number
        playerLoaded = true
    end
    debugprint("got number", number)
    if not number then
        debugprint("no number, checking if player has item")
        if HasPhoneItem() then
            debugprint("player has item; triggering phone:generatePhoneNumber")
            number = AwaitCallback("generatePhoneNumber")
            debugprint("got number", number)
        else
            debugprint("player does not have item")
        end
    end
    if not number then
        fetchingPhone = false
        if currentPhone then
            debugprint("no number. using SetPhone")
            SetPhone()
        end
        debugprint("no number, returning")
        return
    end
    local settingsData = json.decode(GetConfigFile("defaultSettings.json"))
    local latestVersion = AwaitCallback("getLatestVersion")
    local version = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
    if not latestVersion then
        latestVersion = version
    end
    settingsData.locale = Config.DefaultLocale
    settingsData.version = version
    settingsData.latestVersion = latestVersion
    debugprint("fetching phone data")
    local phone = AwaitCallback("getPhone", number)
    debugprint("got phone data", json.encode(phone))
    if phone then
        if phone.settings then
            settingsData = phone.settings
        end
        if phone.name then
            settingsData.name = phone.name
        else
            local characterName = AwaitCallback("getCharacterName")
            settingsData.name = L("BACKEND.MISC.X_PHONE", {
                name = characterName.firstname,
                lastname = characterName.lastname,
            })
        end
        settingsData.version = version
        settingsData.latestVersion = latestVersion
        SavedLocations = AwaitCallback("maps:getSavedLocations")
        local isSetup = phone.is_setup or false
        currentPhone = number
        local newPhoneData = {
            isSetup = isSetup,
            phoneNumber = number,
            settings = settingsData,
        }
        newPhoneData.battery = (Config.Battery.Enabled and phone.battery) or 100
        SyncBatteryValue(newPhoneData.battery)
        newPhoneData.serverIdentifier = GetCurrentServerEndpoint()
        phoneData = newPhoneData
        waitForConfig()
        debugprint("triggering phone:setPhoneData")
        SendNUIAction("setPhoneData", phoneData)
        TriggerEvent("lb-phone:numberChanged", number)
        Wait(250)
    end
    if FetchCryptoCoins then
        FetchCryptoCoins()
    end
    settings = settingsData
    fetchingPhone = false
end

function RefreshPhone(noFetch)
    debugprint("RefreshPhone triggered")
    if fetchingPhone then
        debugprint("phone is being fetched, waiting before refreshing")
        while fetchingPhone do
            Wait(0)
        end
    end
    if Config.DynamicWebRTC and Config.DynamicWebRTC.Enabled then
        local credentials = AwaitCallback("getWebRTCCredentials")
        if Config.DynamicWebRTC.RemoveStun and credentials then
            for i = #credentials, 1, -1 do
                if not credentials[i].credential then
                    table.remove(credentials, i)
                end
            end
        end
        if credentials then
            Config.RTCConfig = Config.RTCConfig or {}
            Config.RTCConfig.iceServers = credentials
        end
    end
    configReceived = false
    local config = json.decode(GetConfigFile("config.json"))
    local valet = {}
    valet.enabled = Config.Valet.Enabled and true or false
    valet.price = Config.Valet.Price or 0
    valet.vehicleTypes = Config.Valet.VehicleTypes or { "car" }
    config.valet = valet
    config.locations = Config.Locations
    config.AllowExternal = Config.AllowExternal
    config.ExternalBlacklistedDomains = Config.ExternalBlacklistedDomains
    config.ExternalWhitelistedDomains = Config.ExternalWhitelistedDomains
    config.EmailDomain = Config.EmailDomain
    config.RealTime = Config.RealTime
    config.CurrencyFormat = Config.CurrencyFormat
    config.DeleteMessages = Config.DeleteMessages
    config.Battery = Config.Battery
    config.rtc = Config.RTCConfig
    config.PromoteBirdy = Config.PromoteBirdy
    config.Verified = Config.Verified
    config.LiveTray = Config.LiveTray
    config.SetupScreen = Config.SetupScreen
    config.MaxTransferAmount = Config.MaxTransferAmount
    config.EnableMessagePay = Config.EnableMessagePay
    config.EnableGIFs = Config.EnableGIFs
    config.GIFsFilter = Config.GIFsFilter or "low"
    config.EnableVoiceMessages = Config.EnableVoiceMessages
    config.DefaultLocale = Config.DefaultLocale
    config.DateLocale = Config.DateLocale
    config.Debug = Config.Debug
    config.TikTokTTS = Config.TrendyTTS or { { "English (US) - Female", "en_us_001" } }
    config.recordNearbyVoices = Config.Voice.RecordNearby
    config.frameColor = Config.FrameColor
    config.allowFrameColorChange = Config.AllowFrameColorChange
    config.unlockPhoneKey = Config.KeyBinds.UnlockPhone and Config.KeyBinds.UnlockPhone.Bind or nil
    config.DeleteMail = Config.DeleteMail
    config.ChangePassword = Config.ChangePassword
    config.DeleteAccount = Config.DeleteAccount
    config.CustomCamera = (Config.Camera and Config.Camera.Walkable) or false
    config.UsernameFilter = (Config.UsernameFilter and Config.UsernameFilter.Regex) or "[a-zA-Z0-9]+"
    config.CryptoLimit = (Config.Crypto and Config.Crypto.Limits) or { Buy = 1000000, Sell = 1000000 }
    config.Browser = Config.Browser
    config.CustomMaps = Config.CustomMaps
    config.sound = {
        system = Config.Sound.System,
        ringtones = Config.Sound.Ringtones,
        notifications = Config.Sound.Notifications,
        appNotifications = Config.Sound.AppNotifications,
    }
    config.AppDownloadTime = Config.AppDownloadTime
    config.Pages = Config.Pages
    config.Marketplace = Config.Marketplace
    local numberLength = Config.PhoneNumber.Length or 7
    local prefixLength = 0
    if #Config.PhoneNumber.Prefixes > 0 then
        prefixLength = #Config.PhoneNumber.Prefixes[1]
    end
    config.PhoneNumberLength = numberLength + prefixLength
    config.Format = Config.PhoneNumber.Format
    config.imageOptions = {
        mime = (Config.Image and Config.Image.Mime) or "image/png",
        quality = (Config.Image and Config.Image.Quality) or 1.0,
    }
    config.videoOptions = {
        bitrate = (Config.Video and Config.Video.Bitrate) or 250,
        audioBitrate = (Config.Video and Config.Video.AudioBitrate) or 128,
        variableBitrate = (Config.Video and Config.Video.VariableBitrate) or false,
        size = (Config.Video and Config.Video.MaxSize) or 10,
        duration = (Config.Video and Config.Video.MaxDuration) or 60,
        fps = (Config.Video and Config.Video.FrameRate) or 24,
    }
    config.Companies = table.deep_clone(Config.Companies)
    if config.Companies and config.Companies.Services then
        for i = 1, #config.Companies.Services do
            local service = config.Companies.Services[i]
            if service.onCustomIconClick then
                service.onCustomIconClick = true
            end
        end
    end
    if Config.CustomApps then
        for appId, appData in pairs(Config.CustomApps) do
            config.apps[appId] = FormatCustomAppDataForUI(appData)
        end
    end
    for appId, app in pairs(config.apps) do
        app.access = HasAccessToApp(appId)
    end
    config.defaultSettings = json.decode(GetConfigFile("defaultSettings.json"))

    local function removeDefaultApp(appName)
        local apps = config.defaultSettings.apps
        for i = 1, #apps do
            for j = 1, #apps[i] do
                if apps[i][j] == appName then
                    table.remove(apps[i], j)
                    break
                end
            end
        end
    end

    if "standalone" == Config.Framework then
        if not Config.CustomFramework then
            config.apps.Wallet = nil
            config.apps.Home = nil
            config.apps.Garage = nil
            config.apps.Services = nil
            removeDefaultApp("Wallet")
            removeDefaultApp("Home")
            removeDefaultApp("Garage")
            removeDefaultApp("Services")
        end
    end
    if not Config.HouseScript then
        config.apps.Home = nil
        debugprint("No Config.HouseScript, removed home app")
        removeDefaultApp("Home")
    end
    if not (Config.Crypto and Config.Crypto.Enabled) then
        config.apps.Crypto = nil
        debugprint("Config.Crypto not enabled, removed crypto app")
        removeDefaultApp("Crypto")
    end
    for appId, hidden in pairs(GetHiddenApps()) do
        if config.apps[appId] then
            config.apps[appId].hidden = hidden
        end
    end
    SendNUIAction("setConfig", config)
    waitForConfig()
    if phoneData then
        debugprint("phoneData is defined")
        SendNUIAction("setPhoneData", phoneData)
        return
    end
    if noFetch then
        return
    end
    FetchPhone()
end

RegisterNetEvent("lb-phone:jobUpdated", function(data)
    if not Config.WhitelistApps and not Config.BlacklistApps then
        return
    end
    debugprint("Job updated, refreshing whitelisted & blacklisted apps")
    local access = {}
    for appId in pairs(Config.WhitelistApps) do
        access[appId] = HasAccessToApp(appId, data.job, data.grade)
    end
    for appId in pairs(Config.BlacklistApps) do
        access[appId] = HasAccessToApp(appId, data.job, data.grade)
    end
    for appId in pairs(Config.CustomApps) do
        access[appId] = HasAccessToApp(appId, data.job, data.grade)
    end
    SendNUIAction("app:setHasAccess", access)
end)

RegisterNUICallback("configReceived", function(data, cb)
    debugprint("UI has received the config (configReceived triggered)")
    configReceived = true
    cb("ok")
end)

RegisterNUICallback("getPhoneData", function(data, cb)
    debugprint("getPhoneData triggered")
    while not FrameworkLoaded do
        Wait(500)
    end
    Wait(1000)
    RefreshPhone()
    if not cb then
        return debugprint("cb is not defined in getPhoneData", data)
    end
    cb(true)
end)

local function disableControlsThread()
    local playerId = PlayerId()
    while phoneOpen do
        Wait(0)
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 200, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 69, true)
        DisableControlAction(0, 70, true)
        DisableControlAction(0, 91, true)
        DisableControlAction(0, 92, true)
        DisableControlAction(0, 106, true)
        DisableControlAction(0, 114, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
        DisableControlAction(0, 330, true)
        DisableControlAction(0, 331, true)
        DisablePlayerFiring(playerId, true)
        if IsNuiFocused() then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 245, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 16, true)
            DisableControlAction(0, 17, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 50, true)
            DisableControlAction(0, 99, true)
            DisableControlAction(0, 115, true)
            DisableControlAction(0, 180, true)
            DisableControlAction(0, 181, true)
            DisableControlAction(0, 198, true)
            DisableControlAction(0, 241, true)
            DisableControlAction(0, 242, true)
            DisableControlAction(0, 261, true)
            DisableControlAction(0, 262, true)
            DisableControlAction(0, 85, true)
        end
    end
    while IsDisabledControlPressed(0, 200) do
        DisableControlAction(0, 200, true)
        Wait(0)
    end
    if cameraOpen then
        if IsWalkingCamEnabled() then
            local selfie = IsSelfieCam()
            DisableWalkableCam()
            while not phoneOpen do
                Wait(500)
            end
            if cameraOpen then
                SetPhoneAction("camera")
                EnableWalkableCam(selfie)
            end
        end
    end
end

function ToggleOpen(open, noFocus)
    if toggling then
        return
    end
    if type(open) ~= "boolean" then
        open = not phoneOpen
    end
    open = open == true
    debugprint("ToggleOpen triggered", tostring(open), tostring(noFocus))
    if phoneDisabled and open then
        debugprint("phone is disabled, returning")
        return
    elseif phoneOpen == open then
        debugprint("phoneOpen & open are both the same value, returning")
        return
    elseif not FrameworkLoaded and open then
        infoprint("warning", "Framework not loaded")
        return
    end
    if open then
        if IsPedDeadOrDying(PlayerPedId(), true) then
            debugprint("player ped is dead/dying, returning")
            return
        end
        if CanOpenPhone and not CanOpenPhone() then
            debugprint("CanOpenPhone returned false, returning")
            return
        end
        if not ValidateChecks("openPhone") then
            debugprint("ValidateChecks returned false for openPhone, returning")
            return
        end
        if IsNuiFocused() and Config.DisableOpenNUI then
            infoprint("info", "Not opening the phone as another script has NUI focus. You can disable this behavior by setting Config.DisableOpenNUI to false.")
            return
        end
        if "started" == GetResourceState("lb-tablet") and not Config.DisableTabletOpenPhone then
            local ok, isOpen = pcall(function()
                return exports["lb-tablet"]:IsOpen()
            end)
            if ok and isOpen then
                infoprint("info", "Not opening the phone as the tablet is open. You can disable this behavior by adding Config.DisableTabletOpenPhone = true to the config.")
                return
            end
        end
    end
    if fetchingPhone then
        toggling = true
        while fetchingPhone do
            Wait(0)
        end
        toggling = false
    end
    if open then
        if not currentPhone then
            debugprint("no phone, fetching")
            FetchPhone()
            if not currentPhone then
                debugprint("still no phone after fetching, returning")
                return
            end
        end
    end
    if open then
        if not HasPhoneItem(currentPhone) then
            debugprint("HasPhoneItem returned false. Phone number:", tostring(currentPhone))
            TriggerServerEvent("phone:togglePhone")
            SendNUIAction("closePhone")
            return
        end
    end
    if not open then
        if IsWalkingCamEnabled() and IsSelfieCam() then
            ToggleSelfieCam(false)
        end
    end
    if not open then
        if Config.EndLiveClose then
            local wasWatching = IsWatchingLive()
            EndLive()
            if wasWatching then
                SendNUIAction("instagram:liveEnded", wasWatching)
            end
        end
    end
    phoneOpen = open
    toggling = true
    if open then
        debugprint("should open phone. sending openPhone event to ui")
        SendNUIAction("openPhone")
        if not noFocus then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(Config.KeepInput)
        end
        if Config.KeepInput then
            CreateThread(disableControlsThread)
        end
        if ControllerThread then
            CreateThread(ControllerThread)
        end
        debugprint("setting animation action")
        if IsWalkingCamEnabled() then
            SetPhoneAction("camera")
        elseif IsInCall() then
            SetPhoneAction("call")
        else
            SetPhoneAction("default")
        end
    else
        debugprint("sending closePhone event to ui")
        PlayCloseAnim()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIAction("closePhone")
    end
    TriggerServerEvent("phone:togglePhone", open)
    TriggerEvent("lb-phone:phoneToggled", open)
    toggling = false
end

RegisterNUICallback("toggleInput", function(data, cb)
    cb("ok")
    if not Config.KeepInput then
        return
    end
    local pttActive = (Config.DisableFocusTalking and IsDisabledControlPressed(0, 249)) or IsDisabledControlJustReleased(0, 249)
    if pttActive then
        if data then
            debugprint("PTT is pressed, ignoring toggle focus")
            return
        end
        debugprint("PTT is pressed, waiting before toggling focus")
        while (Config.DisableFocusTalking and IsDisabledControlPressed(0, 249)) or IsDisabledControlJustReleased(0, 249) do
            Wait(100)
        end
    end
    if data then
        Wait(200)
    end
    SetNuiFocusKeepInput(not data)
end)

AddEventHandler("lb-phone:keyPressed", function(key)
    if IsPauseMenuActive() then
        return
    end
    if "Open" == key then
        debugprint("Pressed open keybind")
        ToggleOpen(not phoneOpen)
    elseif "Focus" == key then
        if not (phoneOpen and not focusWaiting) then
            return
        end
        local pttActive = (Config.DisableFocusTalking and IsDisabledControlPressed(0, 249)) or IsDisabledControlJustReleased(0, 249)
        if pttActive then
            debugprint("PTT is pressed, waiting before toggling focus")
            focusWaiting = true
            while IsDisabledControlPressed(0, 249) or IsDisabledControlJustReleased(0, 249) do
                Wait(0)
            end
            focusWaiting = false
        end
        local focused = IsNuiFocused()
        SetNuiFocus(not focused, not focused)
        if not focused then
            SetNuiFocusKeepInput(Config.KeepInput)
        else
            SetNuiFocusKeepInput(false)
        end
    elseif "StopSounds" == key then
        SendNUIAction("stopSounds")
    end
    if "AnswerCall" == key or "DeclineCall" == key then
        if CanOpenPhone then
            if not CanOpenPhone() then
                debugprint("CanOpenPhone returned false, not answering/declining call")
                return
            end
        elseif not ValidateChecks("openPhone") then
            debugprint("ValidateChecks returned false for openPhone, not answering/declining call")
            return
        end
        if "AnswerCall" == key then
            SendNUIAction("usedCommand", "answer")
        elseif "DeclineCall" == key then
            SendNUIAction("usedCommand", "decline")
        end
    end
    if "TakePhoto" == key then
        SendNUIAction("camera:usedCommand", "toggleTaking")
    elseif "ToggleFlash" == key then
        SendNUIAction("camera:usedCommand", "toggleFlash")
    elseif "LeftMode" == key then
        SendNUIAction("camera:usedCommand", "leftMode")
    elseif "RightMode" == key then
        SendNUIAction("camera:usedCommand", "rightMode")
    elseif "FlipCamera" == key then
        SendNUIAction("camera:usedCommand", "toggleFlip")
    end
end)

for action, keybind in pairs(Config.KeyBinds) do
    if keybind.Command then
        keybind.Command = keybind.Command:lower()
        if keybind.Bind then
            keybind.bindData = AddKeyBind({
                name = keybind.Command,
                description = keybind.Description or "no description",
                defaultKey = keybind.Bind,
                defaultMapper = keybind.Mapper,
                secondaryKey = keybind.SecondaryBind,
                secondaryMapper = keybind.SecondaryMapper,
                onPress = function()
                    TriggerEvent("lb-phone:keyPressed", action)
                end,
                onRelease = function(time)
                    TriggerEvent("lb-tablet:keyReleased", action, time)
                end,
            })
        else
            RegisterCommand(keybind.Command, function()
                TriggerEvent("lb-phone:keyPressed", action)
                Wait(0)
                TriggerEvent("lb-phone:keyReleased", action, 0)
            end, false)
        end
    end
end

RegisterNUICallback("finishedSetup", function(data, cb)
    if phoneData then
        phoneData.isSetup = true
    end
    SendNUIAction("setName", data.name)
    TriggerServerEvent("phone:setName", data.name)
    TriggerServerEvent("phone:togglePhone", phoneOpen)
    TriggerServerEvent("phone:finishedSetup", data)
    if Config.AutoBackup then
        TriggerCallback("backup:createBackup")
    end
    cb("ok")
end)

RegisterNUICallback("isAdmin", function(data, cb)
    TriggerCallback("isAdmin", cb)
end)

RegisterNUICallback("setPhoneName", function(data, cb)
    if phoneData and phoneData.isSetup then
        if settings then
            settings.name = data
        end
        TriggerServerEvent("phone:setName", data)
    end
    cb("ok")
end)

RegisterNUICallback("setSettings", function(data, cb)
    debugprint("setSettings triggered")
    cb("ok")
    if not phoneData then
        print("setSettings triggered, but phoneData is nil")
        return
    end
    settings = data
    phoneData.settings = settings
    AwaitCallback("setSettings", settings)
    SetCallVolume(settings and settings.sound and settings.sound.callVolume)
    TriggerEvent("lb-phone:settingsUpdated", data)
    SendNUIAction("customApp:sendMessage", {
        identifier = "any",
        message = {
            type = "settingsUpdated",
            settings = settings,
            action = "settingsUpdated",
            data = data,
        },
    })
end)

RegisterNUICallback("setCursorLocation", function(data, cb)
    local x = data.x
    local y = data.y
    local screenW, screenH = GetActiveScreenResolution()
    SetCursorLocation(x / screenW, y / screenH)
    cb("ok")
end)

RegisterNUICallback("exitFocus", function(data, cb)
    debugprint("exitFocus triggered")
    SetNuiFocus(false, false)
    ToggleOpen(false)
    cb("ok")
end)

RegisterNUICallback("getLocales", function(data, cb)
    cb(Config.Locales or { en = "English" })
end)

RegisterNUICallback("setOnScreen", function(data, cb)
    data = data == true
    if data ~= PhoneOnScreen then
        TriggerEvent("lb-phone:setOnScreen", data)
        PhoneOnScreen = data
    end
    cb("ok")
end)

RegisterNUICallback("restartPhone", function(data, cb)
    cb("ok")
    ToggleOpen(false)
    Wait(1000)
    ToggleOpen(true)
end)

exports("IsPhoneOnScreen", function()
    return PhoneOnScreen
end)

CreateThread(function()
    local lastTime = {}
    debugprint("Waiting for currentPhone to be set before updating time & service")
    while not currentPhone do
        Wait(500)
    end
    SendNUIAction("updateService", GetServiceBars())
    debugprint("currentPhone is set, updating time & service")
    while true do
        if Config.RealTime then
            break
        end
        local time = Config.CustomTime and Config.CustomTime()
        if not time then
            time = {
                hour = GetClockHours(),
                minute = GetClockMinutes(),
            }
        end
        if not (time.hour == lastTime.hour and time.minute == lastTime.minute) then
            lastTime.hour = time.hour
            lastTime.minute = time.minute
            SendNUIAction("updateTime", time)
        end
        Wait(1000)
    end
end)

function GetConfigFile(file)
    return LoadResourceFile(GetCurrentResourceName(), "config/" .. file)
end

RegisterNUICallback("getConfigFile", function(data, cb)
    local content = GetConfigFile(data .. ".json")
    local decoded = content and json.decode(content)
    if not decoded and data:find("^locales/") then
        decoded = json.decode(GetConfigFile("locales/en.json"))
    end
    cb(decoded)
end)

local nearbyPlayers = {}
local lastNearbyCoords = vector3(0.0, 0.0, 0.0)
local lastNearbyUpdate = 0

local function updateNearbyPlayers()
    local coords = GetEntityCoords(PlayerPedId())
    local players = GetActivePlayers()
    local result = {}
    for i = 1, #players do
        local player = players[i]
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local pedCoords = GetEntityCoords(ped)
            if #(coords - pedCoords) <= 50.0 then
                result[#result + 1] = {
                    player = player,
                    source = GetPlayerServerId(player),
                    ped = ped,
                    coords = pedCoords,
                }
            end
        end
    end
    nearbyPlayers = result
end

function GetNearbyPlayers()
    local needsUpdate = GetGameTimer() - lastNearbyUpdate > 5000
    if not needsUpdate then
        needsUpdate = #(GetEntityCoords(PlayerPedId()) - lastNearbyCoords) > 25.0
    end
    if needsUpdate then
        lastNearbyUpdate = GetGameTimer()
        lastNearbyCoords = GetEntityCoords(PlayerPedId())
        updateNearbyPlayers()
    end
    return nearbyPlayers
end

function LogOut()
    debugprint("LogOut triggered")
    while fetchingPhone do
        debugprint("LogOut triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end
    ResetSecurity()
    OnDeath()
    phoneData = nil
    currentPhone = nil
    settings = nil
    TriggerEvent("lb-phone:numberChanged", nil)
    TriggerCallback("setLastPhone")
end

function SetPhone(number, force)
    debugprint("SetPhone triggered", number, force)
    while fetchingPhone do
        debugprint("SetPhone triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end
    OnDeath()
    AwaitCallback("setLastPhone", number)
    ResetSecurity(true)
    ToggleCharging(false)
    phoneData = nil
    currentPhone = nil
    settings = nil
    TriggerEvent("lb-phone:numberChanged", nil)
    if number or force then
        FetchPhone()
    end
    if nil == number and not force then
        local firstNumber = GetFirstNumber()
        if firstNumber then
            SetPhone(firstNumber)
        end
    end
end

function OnDeath()
    debugprint("OnDeath triggered")
    local wasWatching = IsWatchingLive()
    EndLive()
    if wasWatching then
        SendNUIAction("instagram:liveEnded", wasWatching)
    end
    if flashlightEnabled then
        flashlightEnabled = false
        TriggerServerEvent("phone:toggleFlashlight", false)
    end
    EndCall()
    ToggleOpen(false)
end

RegisterNetEvent("phone:toggleOpen", ToggleOpen)

exports("ToggleOpen", ToggleOpen)

exports("IsOpen", function()
    return phoneOpen
end)

exports("IsDisabled", function()
    return phoneDisabled
end)

exports("ToggleDisabled", function(disabled)
    phoneDisabled = disabled == true
    debugprint("ToggleDisabled triggered", phoneDisabled)
    if phoneDisabled and phoneOpen then
        ToggleOpen(false)
    end
end)

exports("GetSettings", function()
    return settings
end)

exports("GetAirplaneMode", function()
    return settings and settings.airplaneMode
end)

exports("GetStreamerMode", function()
    return settings and settings.streamerMode
end)

exports("GetEquippedPhoneNumber", function()
    return currentPhone
end)
