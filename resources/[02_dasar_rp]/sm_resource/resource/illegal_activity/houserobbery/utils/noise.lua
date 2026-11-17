local noise = {}

local bgColor = { r = 80, g = 80, b = 80, a = 255 }
local fgColor = { r = 240, g = 240, b = 240, a = 255 }

local progressbar = require 'modules.scaleformsUI.timerBars.bars.progressTimerBar'

local noiseBar = progressbar:new("Noise Level", bgColor, fgColor, 0, 0)
noiseBar:setEnabled(false)

function noise.updateLevel(noiseLevel)
    if not noiseBar.enabled then return end
    local percentage = math.min(math.max(noiseLevel / 100.0, 0.0), 1.0)
    noiseBar:setPercentage(percentage)
    if percentage < 0.3 then
        noiseBar:setForegroundColor({ r = 240, g = 240, b = 240, a = 255 })
        noiseBar:setBackgroundColor({ r = 80, g = 80, b = 80, a = 255 })
    elseif percentage < 0.6 then
        noiseBar:setForegroundColor({ r = 224, g = 224, b = 50, a = 255 })
        noiseBar:setBackgroundColor({ r = 112, g = 112, b = 25, a = 255 })
    elseif percentage < 0.8 then
        noiseBar:setForegroundColor({ r = 224, g = 150, b = 50, a = 255 })
        noiseBar:setBackgroundColor({ r = 112, g = 75, b = 25, a = 255 })
    else
        noiseBar:setForegroundColor({ r = 224, g = 50, b = 50, a = 255 })
        noiseBar:setBackgroundColor({ r = 112, g = 25, b = 25, a = 255 })
    end
end

function noise.stop()
    if not noiseBar.enabled then return end
    noiseBar:setPercentage(0)
    noiseBar:setEnabled(false)
    noiseBar:setForegroundColor(fgColor)
    noiseBar:setBackgroundColor(bgColor)
end

function noise.start(testFn)
    if noiseBar.enabled then return end
    noiseBar:setEnabled(true)
    Wait(100)

    CreateThread(function()
        while noiseBar.enabled do
            Wait(5)
            noiseBar:draw(0)
        end
    end)

    local noiseLevel = 0
    CreateThread(function()
        while noiseBar.enabled do
            if noiseLevel > 0 then
                noiseLevel = math.max(noiseLevel - 5, 0)
            end
            noise.updateLevel(noiseLevel)
            if IsPedShooting(cache.ped) then
                noiseLevel = noiseLevel + (IsPedInMeleeCombat(cache.ped) and 20 or 80)
            end
            local speed = GetEntitySpeed(cache.ped)
            if speed > 1.1 and math.random() < 0.4 then
                if speed > 3.0 then
                    noiseLevel = noiseLevel + 20
                elseif speed > 2.5 then
                    noiseLevel = noiseLevel + 15
                end
            end
            noiseLevel = math.min(noiseLevel, 100)
            if testFn and testFn(noiseLevel) then
                noise.stop()
            end
            Wait(100)
        end
    end)
end

return noise