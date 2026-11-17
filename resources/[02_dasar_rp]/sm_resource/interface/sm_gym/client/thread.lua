local startTime
local lastTime
local totalTime = 0
local lastGymLevel = nil

local staminaLevel = localmodule 'data.stamina'

CreateThread(function ()

    while true do
        if playerState.isLoggedIn then
            local metadata = QBPlayerData?.metadata

            local gymLevel = metadata?.gym
            if gymLevel and type(gymLevel) == 'number' then
                local gymIndex = math.floor(gymLevel)

                if gymIndex ~= lastGymLevel and staminaLevel[gymIndex] then
                    StatSetInt('MP0_STAMINA', staminaLevel[gymIndex], true)
                    lastGymLevel = gymIndex
                end
            end

            local isRunning = IsPedRunning(cache.ped) or IsPedSprinting(cache.ped)

            if isRunning then
                if not startTime then
                    startTime = GetGameTimer()
                end

                lastTime = GetGameTimer() - startTime

                if totalTime + lastTime >= 20000 then
                    TriggerServerEvent('sm_gym:server:remove')
                    totalTime = 0
                    startTime = GetGameTimer()
                end
            else
                startTime = nil
                totalTime += lastTime or 0
                lastTime = nil

                if totalTime >= 20000 then
                    TriggerServerEvent('sm_gym:server:remove')
                    totalTime = 0
                end
            end
        else
            startTime = nil
            totalTime = 0
            lastGymLevel = nil
        end
        Wait(1500)
    end
end)