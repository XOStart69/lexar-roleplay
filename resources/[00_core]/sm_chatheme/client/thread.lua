local Config = require "config.config"

local CreateThread = CreateThread
local Wait = Wait
local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed
local GetPlayerFromServerId = GetPlayerFromServerId
local GetHudScreenPositionFromWorldPosition = GetHudScreenPositionFromWorldPosition
local mathAbs = math.abs
local tonumber = tonumber
local next = next
local pairs = pairs

local MaxDistance = 10.0
local MoveThreshold = 0.05
local DefaultColor = { r = 255, g = 255, b = 255, a = 255 }
local DrawColors = Config.DefaultSettings.drawtextColors
local RemovePayload = {}

---@param text table
local function HideDUIText(text)
    if text.hidden then return end
    text.hidden = true
    text.oldScreenX = nil
    text.oldScreenY = nil
    RemovePayload.source = text.source
    SendVueMessage("REMOVE_3D_TEXT", RemovePayload)
end

function RPTextsDUIThread()
    if RPTextThread then return end
    RPTextThread = true

    CreateThread(function()
        while #RPTexts >= 1 do
            local playerPedCoords = GetEntityCoords(cache.ped)

            for i = 1, #RPTexts do
                local text = RPTexts[i]
                local playerId = text.source and GetPlayerFromServerId(text.source) or -1

                if playerId == -1 then
                    HideDUIText(text)
                else
                    local targetPedCoords = GetEntityCoords(GetPlayerPed(playerId))

                    if #(playerPedCoords - targetPedCoords) >= MaxDistance then
                        HideDUIText(text)
                    else
                        local offscreen, screenX, screenY = GetHudScreenPositionFromWorldPosition(
                            targetPedCoords.x, targetPedCoords.y, targetPedCoords.z + 1.0
                        )

                        if offscreen then
                            HideDUIText(text)
                        else
                            screenX = screenX * 100
                            screenY = screenY * 100
                            local oldX, oldY = text.oldScreenX, text.oldScreenY

                            if not oldX or mathAbs(oldX - screenX) > MoveThreshold or mathAbs(oldY - screenY) > MoveThreshold then
                                text.hidden = false
                                text.oldScreenX = screenX
                                text.oldScreenY = screenY
                                SendVueMessage('SHOW_3D_TEXT', {
                                    source = text.source,
                                    player = text.fullname,
                                    screenX = screenX,
                                    screenY = screenY,
                                    message = text.message,
                                    category = text.category,
                                    isDice = text.isDice,
                                    isRPS = text.isRPS,
                                    hand = text.hand or false,
                                })
                            end
                        end
                    end
                end
            end
            Wait(0)
        end
        RPTextThread = false
    end)
end

function RPTexts3DThread()
    if RPText3DThread then return end
    RPText3DThread = true

    CreateThread(function()
        while #RPTexts >= 1 do
            local playerPedCoords = GetEntityCoords(cache.ped)

            for i = 1, #RPTexts do
                local text = RPTexts[i]
                local playerId = text.source and GetPlayerFromServerId(text.source) or -1

                if playerId ~= -1 then
                    local targetPedCoords = GetEntityCoords(GetPlayerPed(playerId))

                    if #(playerPedCoords - targetPedCoords) < MaxDistance then
                        DrawText3D(targetPedCoords.x, targetPedCoords.y, targetPedCoords.z, text.message, DrawColors[text.category] or DefaultColor)
                    end
                end
            end
            Wait(0)
        end
        RPText3DThread = false
    end)
end

function FWritingEffect()
    if WritingEffect then return end
    WritingEffect = true

    CreateThread(function()
        while next(WritingPlayers) ~= nil do
            local sleep = 500
            local playerCoords = GetEntityCoords(cache.ped)

            for source in pairs(WritingPlayers) do
                local writerId = GetPlayerFromServerId(tonumber(source))
                if writerId == -1 then
                    WritingPlayers[source] = nil
                else
                    local writerCoords = GetEntityCoords(GetPlayerPed(writerId))
                    if #(playerCoords - writerCoords) <= 6.0 then
                        sleep = 0
                        DrawDots(vec3(writerCoords.x, writerCoords.y, writerCoords.z + 1.0), Dots)
                    end
                end
            end
            Wait(sleep)
        end
        WritingEffect = false
    end)
end
