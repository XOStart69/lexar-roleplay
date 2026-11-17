local MINIMAP_WIDTH = 0.1638
local MINIMAP_HEIGHT = 0.183

local radarEnabled = true
local minimapScaleform = nil
local lastX, lastY

local IsPauseMenuActive = IsPauseMenuActive
local IsBigmapActive = IsBigmapActive
local DisplayRadar = DisplayRadar
local SetRadarBigmapEnabled = SetRadarBigmapEnabled
local SetBigmapActive = SetBigmapActive

local screenW, screenH = GetActiveScreenResolution()

interface.callback('previewMinimap', function(data, cb)
    if data then
        SM_HUD.minimapPosition = data
    end
    cb('ok')
end)

exports('GetMinimapPosition', function()
    return SM_HUD.minimapPosition
end)

local function safeZoneMargin()
    SetScriptGfxAlign(76, 84)
    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
    local x, y = GetScriptGfxPosition(0.0, 0.0)
    ResetScriptGfxAlign()
    return x, y
end

local function applyPosition()
    local position = SM_HUD.minimapPosition
    local safeX, safeY = safeZoneMargin()
    local x = math.min(math.max(position.x, 0.0), 1.0 - MINIMAP_WIDTH)
    local y = math.min(math.max(position.y, 0.0), 1.0 - MINIMAP_HEIGHT)
    local offsetX, offsetY = x - safeX, 0.047 - y + safeY

    if offsetX == lastX and offsetY == lastY then return end

    lastX, lastY = offsetX, offsetY

    SetMinimapComponentPosition('minimap', 'L', 'B', 0.0 + offsetX, -0.047 + offsetY, MINIMAP_WIDTH, MINIMAP_HEIGHT)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.0 + offsetX, 0.0 + offsetY, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + offsetX, 0.025 + offsetY, 0.262, 0.300)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
end

local function thread(scaleform)
    local tick = 2000

    if not playerState.isLoggedIn then
        return tick
    end

    tick = 500

    applyPosition()

    local mapState  = 'show'
    local inVehicle = cache.vehicle

    if SM_HUD.mapState then
        mapState = SM_HUD.mapState
    end

    local showRadar = mapState == 'show'
        or (mapState == 'inVehicle' and inVehicle)

    local disabledHUD = IsPauseMenuActive() or playerState.invOpen or playerState.storeOpen or playerState.phoneOpen or playerState.inCinematic or playerState.inCutscene or playerState.inInterior or playerState.inGarage or playerState.inCinematic or playerState.missileControl or playerState.droneControl or playerState.petUiOpen or playerState.pdCameraOpen or playerState.gamemasterOpen

    if disabledHUD and SM_HUD.visible then
        SM_HUD.setVisible(false)
        pcall(function() exports['sm_bodycam']:hideBodycamHud(true) end)
    elseif not disabledHUD and not SM_HUD.visible then
        SM_HUD.setVisible(true)
        pcall(function() exports['sm_bodycam']:hideBodycamHud(false) end)
    end

    if scaleform then
        BeginScaleformMovieMethod(scaleform, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        SetRadarZoom(1100)
    end

    if SM_HUD.visible then
        if not showRadar or SM_HUD.blackBarsActive then
            DisplayRadar(false)
        elseif inVehicle then
            DisplayRadar(true)
        else
            DisplayRadar(radarEnabled)
        end
    else
        DisplayRadar(false)
        return tick
    end

    if IsBigmapActive() then
        SetRadarBigmapEnabled(false, false)
        SetBigmapActive(false, false)
    end

    local sx, sy = screenW, screenH

    interface.send({
        action = 'updateMinimap',
        data = {
            active = showRadar,
            width = math.floor(MINIMAP_WIDTH * sx),
            height = math.floor(MINIMAP_HEIGHT * sy),
        },
    })

    return tick
end

CreateThread(function()
    while not playerState.isLoggedIn do
        DisplayRadar(false)
        Wait(1000)
    end

    Wait(1000)
    if not minimapScaleform then
        minimapScaleform = RequestScaleformMovie("minimap")
        while not HasScaleformMovieLoaded(minimapScaleform) do Wait(0) end
    end

    pcall(lib.requestStreamedTextureDict, 'squaremap')
    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
    SetMinimapClipType(0)
    applyPosition()

    while true do
        Wait(thread(minimapScaleform))
    end
end)
