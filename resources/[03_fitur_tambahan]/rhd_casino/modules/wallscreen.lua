---@enum VideoType
local VideoType = {
    DIAMONDS = 'CASINO_DIA_PL',
    SKULLS = 'CASINO_HLW_PL',
    SNOW = 'CASINO_SNWFLK_PL',
}

local inArea = false
local showBigWin = false

local function setVideoWallTvChannel()
    SetTvChannelPlaylist(0, VideoType.DIAMONDS, true)
    SetTvAudioFrontend(true)
    SetTvVolume(-100.0)
    SetTvChannel(0)
end

local function setVideoWallTvChannelWin()
    SetTvChannelPlaylist(0, 'CASINO_WIN_PL', true)
    SetTvAudioFrontend(true)
    SetTvVolume(-100.0)
    SetTvChannel(-1)
    SetTvChannel(0)
end

---Registers the render target for the casino video wall and spawns the draw loop thread.
---Must be called after entering the casino interior area.
local function casinoWallThread()

    RequestStreamedTextureDict('Prop_Screen_Vinewood', false)
    local timeout = GetGameTimer() + 10000
    while not HasStreamedTextureDictLoaded('Prop_Screen_Vinewood')
        and GetGameTimer() < timeout
    do
        Wait(100)
    end
    if not HasStreamedTextureDictLoaded('Prop_Screen_Vinewood') then return end

    if not IsNamedRendertargetRegistered('casinoscreen_01') then
        RegisterNamedRendertarget('casinoscreen_01', false)
    end

    if not IsNamedRendertargetLinked(`vw_vwint01_video_overlay`) then
        LinkNamedRendertarget(`vw_vwint01_video_overlay`)
    end

    local videoWallRenderTarget = GetNamedRendertargetRenderId('casinoscreen_01')

    CreateThread(function()
        local lastUpdatedTvChannel = 0
        while inArea do
            Wait(1)
            if videoWallRenderTarget and videoWallRenderTarget ~= 0 then
                local currentTime = GetGameTimer()

                if showBigWin then
                    setVideoWallTvChannelWin()

                    lastUpdatedTvChannel = GetGameTimer() - 33666
                    showBigWin = false
                else
                    if (currentTime - lastUpdatedTvChannel) >= 42666 then
                        setVideoWallTvChannel()

                        lastUpdatedTvChannel = currentTime
                    end
                end

                SetTextRenderId(videoWallRenderTarget)
                SetScriptGfxDrawOrder(4)
                SetScriptGfxDrawBehindPausemenu(true)
                DrawInteractiveSprite('Prop_Screen_Vinewood', 'BG_Wall_Colour_4x4', 0.25, 0.5, 0.5, 1.0, 0.0, 255, 255, 255, 255)
                DrawTvChannel(0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            end
        end

        ReleaseNamedRendertarget('casinoscreen_01')
        showBigWin = false
        videoWallRenderTarget = 0
    end)
end

useAreaHooks(function (state)
    inArea = state

    if inArea then
        casinoWallThread()
    end
end)
