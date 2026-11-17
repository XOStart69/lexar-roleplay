local config = localmodule 'config.shared'

local progressBar = config.progressBar
local barColor = progressBar.color
local barLabel = progressBar.label

local DrawRect = DrawRect
local DrawSprite = DrawSprite
local SetTextFont = SetTextFont
local SetTextScale = SetTextScale
local SetTextColour = SetTextColour
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandDisplayText = EndTextCommandDisplayText
local GetSafeZoneSize = GetSafeZoneSize
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim

local BAR_WIDTH = 0.13
local BAR_HEIGHT = 0.038
local BAR_FILL_WIDTH = 0.0516
local BAR_FILL_HEIGHT = 0.0105
local BAR_FILL_OFFSET = 0.03
local TEXTURE_DICT = 'timerbars'

local effects = {}

function effects.playAnim(dict, clip)
    if IsEntityPlayingAnim(cache.ped, dict, clip, 3) then return end

    if not lib.requestAnimDict(dict, 5000) then return end

    TaskPlayAnim(cache.ped, dict, clip, 8.0, -8.0, -1, 51, 0, false, false, false)
end

local function drawText(text, x, y)
    SetTextFont(0)
    SetTextScale(0.32, 0.32)
    SetTextColour(254, 254, 254, 255)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function effects.drawRecoveryBar(progress)
    local safeZone = GetSafeZoneSize()
    local x = safeZone - (BAR_WIDTH / 2)
    local y = safeZone - (BAR_HEIGHT / 2) - (BAR_HEIGHT + 0.005)

    if not HasStreamedTextureDictLoaded(TEXTURE_DICT) then
        RequestStreamedTextureDict(TEXTURE_DICT, true)
    else
        DrawSprite(TEXTURE_DICT, 'all_black_bg', x, y, BAR_WIDTH, BAR_HEIGHT, 0.0, 0, 0, 0, 128)
    end

    drawText(barLabel, safeZone - BAR_WIDTH + 0.01, y - 0.012)

    if progress < 0 then progress = 0 elseif progress > 100 then progress = 100 end

    local filled = (BAR_FILL_WIDTH * progress) / 100
    local fillX = x + BAR_FILL_OFFSET

    DrawRect(fillX, y, BAR_FILL_WIDTH, BAR_FILL_HEIGHT, 155, 155, 155, 200)
    DrawRect(
        fillX - (BAR_FILL_WIDTH / 2) + (filled / 2),
        y,
        filled,
        BAR_FILL_HEIGHT,
        barColor[1], barColor[2], barColor[3], 255
    )
end

function effects.disableControls(grenade)
    local disable = grenade.disable
    if not disable then return end

    if disable.sprint then DisableControlAction(0, 21, true) end
    if disable.vehicle then DisableControlAction(0, 23, true) end
    if disable.jump then DisableControlAction(0, 22, true) end

    if disable.combat then
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 142, true)
        DisablePlayerFiring(cache.ped, true)
    end
end

return effects
