if not interface.init(false) then return end

local Config = localmodule 'config'

local Wait = Wait
local CreateThread = CreateThread
local GetEntityCoords = GetEntityCoords
local OverrideLodscaleThisFrame = OverrideLodscaleThisFrame
local SetDisableDecalRenderingThisFrame = SetDisableDecalRenderingThisFrame
local DisableControlAction = DisableControlAction
local ClearPedBloodDamage = ClearPedBloodDamage
local ClearAllBrokenGlass = ClearAllBrokenGlass
local RemoveDecalsInRange = RemoveDecalsInRange
local SetRainLevel = SetRainLevel
local SetWindSpeed = SetWindSpeed
local GetTimecycleModifierIndex = GetTimecycleModifierIndex
local mathfloor = math.floor
local mathmax = math.max
local mathmin = math.min
local tonumber = tonumber
local pairs = pairs
local type = type

local defaults = Config.defaults
local presets = Config.presets
local modes = Config.modes
local lightFilters = Config.lightFilters
local KVP_KEY = Config.kvpKey
local DEFAULT_TIMECYCLE = GetTimecycleModifierIndexByName and GetTimecycleModifierIndexByName('default') or -1

local SHADOW_SAMPLES = { low = 'CSM_ST_POINT', medium = 'CSM_ST_BOX3x3' }
local SHADOW_FILTERS = { low = true, medium = true, high = true }
local NUMBER_MIN = { shadowDistance = 0, objectQuality = Config.minObjectQuality }
local BOOL_KEYS = { clearEvents = true, lightReflections = true, rainWind = true, bloodStains = true }
local CAMERA_BLOCKED_CONTROLS = { 24, 25, 68, 69, 70, 91, 92, 114, 140, 141, 142 }
local CAMERA_BLOCKED_COUNT = #CAMERA_BLOCKED_CONTROLS

local settings = {}
local customized = false
local lightsOverridden = false
local weatherOverridden = false
local frameLoopRunning = false
local filterIndex = -1
local filterExtra = false
local suspended = false
local uiOpen = false
local frameMounted = false
local frameReady = false
local cameraFree = false

local function copyDefaults()
    for key, value in pairs(defaults) do
        settings[key] = value
    end
end

---@return boolean
local function loadSettings()
    copyDefaults()
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw or raw == '' then return false end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then return false end

    for key, value in pairs(decoded) do
        local fallback = defaults[key]
        if fallback ~= nil and type(value) == type(fallback) then
            settings[key] = value
        end
    end

    if settings.preset ~= 'none' and not presets[settings.preset] then settings.preset = 'none' end
    if settings.mode ~= 'none' and not modes[settings.mode] then settings.mode = 'none' end
    if not SHADOW_FILTERS[settings.shadowFilter] then settings.shadowFilter = defaults.shadowFilter end
    if not lightFilters[settings.lightFilter] then settings.lightFilter = 'off' end
    for key, minimum in pairs(NUMBER_MIN) do
        settings[key] = mathfloor(mathmax(minimum, mathmin(100, settings[key])) + 0.5)
    end

    return true
end

local function saveSettings()
    customized = true
    SetResourceKvp(KVP_KEY, json.encode(settings))
end

---@param values table
---@return boolean
local function matches(values)
    for key, value in pairs(values) do
        if settings[key] ~= value then return false end
    end
    return true
end

---@param list table
---@return string
local function findMatch(list)
    for key, values in pairs(list) do
        if matches(values) then return key end
    end
    return 'none'
end

local function refreshLabels()
    settings.preset = findMatch(presets)
    settings.mode = findMatch(modes)
end

local function applyShadowDistance()
    local scale = settings.shadowDistance / 100.0
    local dynamic = scale >= 0.15
    CascadeShadowsSetCascadeBoundsScale(scale)
    CascadeShadowsEnableEntityTracker(scale >= 0.3)
    CascadeShadowsSetEntityTrackerScale(scale)
    CascadeShadowsSetAircraftMode(dynamic)
    CascadeShadowsSetDynamicDepthMode(dynamic)
    CascadeShadowsSetDynamicDepthValue(dynamic and scale or 0.0)
end

local function applyShadowFilter()
    local sample = SHADOW_SAMPLES[settings.shadowFilter]
    if sample then
        CascadeShadowsSetShadowSampleType(sample)
    else
        CascadeShadowsClearShadowSampleType()
    end
end

local function needsFrameLoop()
    return settings.objectQuality < 100 or settings.clearEvents
end

local function ensureFrameLoop()
    if frameLoopRunning or not needsFrameLoop() then return end
    frameLoopRunning = true

    CreateThread(function()
        while needsFrameLoop() do
            local quality = settings.objectQuality
            if quality < 100 then
                OverrideLodscaleThisFrame(0.2 + quality * 0.008)
            end
            if settings.clearEvents then
                SetDisableDecalRenderingThisFrame()
            end
            Wait(0)
        end
        frameLoopRunning = false
    end)
end

local function applyObjectQuality()
    ensureFrameLoop()
end

local function applyLights()
    if not settings.lightReflections then
        SetArtificialLightsState(true)
        SetArtificialLightsStateAffectsVehicles(false)
        lightsOverridden = true
    elseif lightsOverridden then
        SetArtificialLightsState(GlobalState.blackOut == true)
        SetArtificialLightsStateAffectsVehicles(true)
        lightsOverridden = false
    end
end

local function applyWeather()
    if not settings.rainWind then
        SetRainLevel(0.0)
        SetWindSpeed(0.0)
        weatherOverridden = true
    elseif weatherOverridden then
        SetRainLevel(-1.0)
        weatherOverridden = false
    end
end

local function applyBlood()
    if not settings.bloodStains then
        ClearPedBloodDamage(cache.ped)
    end
end

local function applyClearEvents()
    if settings.clearEvents then
        ClearAllBrokenGlass()
        RemoveDecalsInRange(GetEntityCoords(cache.ped), 250.0)
    end
    ensureFrameLoop()
end

---@param index integer
---@return boolean
local function isTimecycleFree(index)
    return index == -1 or index == filterIndex or index == DEFAULT_TIMECYCLE
end

local function releaseLightFilter()
    if filterIndex ~= -1 and GetTimecycleModifierIndex() == filterIndex then
        ClearTimecycleModifier()
    end
    if filterExtra then
        ClearExtraTimecycleModifier()
        filterExtra = false
    end
    filterIndex = -1
end

local function applyLightFilter()
    local filter = lightFilters[settings.lightFilter]
    if not filter then return releaseLightFilter() end
    if not isTimecycleFree(GetTimecycleModifierIndex()) then return end

    SetTimecycleModifier(filter.main)
    if filter.extra then
        SetExtraTimecycleModifier(filter.extra)
        filterExtra = true
    elseif filterExtra then
        ClearExtraTimecycleModifier()
        filterExtra = false
    end
    filterIndex = GetTimecycleModifierIndex()
end

local APPLIERS = {
    lightFilter = applyLightFilter,
    shadowDistance = applyShadowDistance,
    shadowFilter = applyShadowFilter,
    objectQuality = applyObjectQuality,
    lightReflections = applyLights,
    rainWind = applyWeather,
    bloodStains = applyBlood,
    clearEvents = applyClearEvents,
}

local function applyAll()
    applyShadowDistance()
    applyShadowFilter()
    applyObjectQuality()
    applyLights()
    applyWeather()
    applyBlood()
    applyClearEvents()
    applyLightFilter()
end

---@param key string
---@param value any
---@return boolean
local function setValue(key, value)
    local minimum = NUMBER_MIN[key]
    if minimum then
        value = tonumber(value)
        if not value then return false end
        settings[key] = mathfloor(mathmax(minimum, mathmin(100, value)) + 0.5)
    elseif BOOL_KEYS[key] then
        if type(value) ~= 'boolean' then return false end
        settings[key] = value
    elseif key == 'shadowFilter' then
        if not SHADOW_FILTERS[value] then return false end
        settings[key] = value
    elseif key == 'lightFilter' then
        if value ~= 'off' and not lightFilters[value] then return false end
        settings[key] = value
    else
        return false
    end
    return true
end

local function stopCamera()
    if not cameraFree then return end
    cameraFree = false
    if uiOpen then interface.focus(true, true, false) end
end

local function startCamera()
    if cameraFree or not uiOpen then return end
    cameraFree = true
    interface.focus(true, true, true)

    CreateThread(function()
        while cameraFree do
            for i = 1, CAMERA_BLOCKED_COUNT do
                DisableControlAction(0, CAMERA_BLOCKED_CONTROLS[i], true)
            end
            Wait(0)
        end
    end)
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    cameraFree = false
    interface.focus(false, false, false)

    if frameMounted then
        interface.hide()
        frameMounted = false
        frameReady = false
    end
end

local function openUI()
    if suspended then
        return lib.notify({
            type = 'error',
            description = 'Lepas sayap terbang dulu untuk mengatur FPS'
        })
    end

    uiOpen = true

    if not frameMounted then
        frameReady = false
        frameMounted = true
        interface.show()
    elseif frameReady then
        interface.send({ action = 'open', data = settings })
        interface.focus(true, true, false)
    end
end

exports('SuspendFps', function()
    if suspended or not customized then return end

    suspended = true

    closeUI()
    copyDefaults()
    applyAll()
end)

exports('RestoreFps', function()
    if not suspended then return end

    suspended = false

    loadSettings()
    applyAll()
end)

interface.callback('ready', function(_, cb)
    frameReady = true
    if uiOpen then
        interface.send({ action = 'open', data = settings })
        interface.focus(true, true, false)
    end
    cb('ok')
end)

interface.callback('exit', function(_, cb)
    closeUI()
    cb('ok')
end)

interface.callback('preset', function(data, cb)
    local key = data and data.key
    local preset = presets[key]
    if not preset then return cb(settings) end

    for field, value in pairs(preset) do
        settings[field] = value
    end
    refreshLabels()
    applyAll()
    saveSettings()
    cb(settings)
end)

interface.callback('mode', function(data, cb)
    local key = data and data.key
    local mode = modes[key]
    if not mode then return cb(settings) end

    for field, value in pairs(mode) do
        settings[field] = value
    end
    refreshLabels()

    applyShadowFilter()
    applyLights()
    applyWeather()
    applyBlood()
    applyClearEvents()
    saveSettings()
    cb(settings)
end)

interface.callback('set', function(data, cb)
    local key = data and data.key
    if not key or not setValue(key, data.value) then return cb(settings) end

    refreshLabels()
    APPLIERS[key]()
    saveSettings()
    cb(settings)
end)

interface.callback('reset', function(_, cb)
    copyDefaults()
    applyAll()
    DeleteResourceKvp(KVP_KEY)
    customized = false
    cb(settings)
end)

interface.callback('camera', function(data, cb)
    if data and data.active then
        startCamera()
    else
        stopCamera()
    end
    cb('ok')
end)

RegisterCommand(Config.command, function()
    if uiOpen then
        closeUI()
    else
        openUI()
    end
end, false)

AddStateBagChangeHandler('blackOut', 'global', function()
    if settings.lightReflections then return end
    SetTimeout(1000, applyLights)
end)

CreateThread(function()
    if not loadSettings() then return end
    customized = true
    Wait(3000)
    applyAll()
end)

CreateThread(function()
    while true do
        Wait(5000)
        if customized then
            if not settings.bloodStains then
                ClearPedBloodDamage(cache.ped)
            end
            if settings.clearEvents then
                ClearAllBrokenGlass()
                RemoveDecalsInRange(GetEntityCoords(cache.ped), 250.0)
            end
            if not settings.rainWind then
                SetRainLevel(0.0)
                SetWindSpeed(0.0)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if settings.lightFilter ~= 'off' then
            local current = GetTimecycleModifierIndex()
            if current ~= filterIndex and isTimecycleFree(current) then
                applyLightFilter()
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    if uiOpen then interface.focus(false, false, false) end
    if not customized then return end
    copyDefaults()
    applyAll()
end)
