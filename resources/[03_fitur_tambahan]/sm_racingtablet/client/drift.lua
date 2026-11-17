if not ConfigDrift or not ConfigDrift.useDrift then DebugLog('Drift is disabled') return end
DebugLog('^2Drift is enabled^0')

local DriftLocal = {
    countdownActive = {},
    localFinished = false,
    lastSentDrift = 0
}

local Wait = Wait
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetEntitySpeed = GetEntitySpeed
local GetEntityVelocity = GetEntityVelocity
local GetEntityForwardVector = GetEntityForwardVector
local msqrt = math.sqrt
local macos = math.acos
local mdeg = math.deg
local mfloor = math.floor
local mmin = math.min
local mmax = math.max

local scoring = ConfigDrift.scoring
local HOLD_CURRENT_UNTIL_RESET = scoring.holdCurrentUntilReset ~= false
local MULTIPLIER_MAX = scoring.multiplierMax
local MULTIPLIER_TIMER = scoring.multiplierTimer
local DRIFT_THRESHOLD = scoring.driftThreshold
local MIN_DRIFT_SPEED = scoring.minDriftSpeed
local MULTIPLIER_INCREMENT_TIME = scoring.multiplierIncrementTime
local SCORE_INCREMENT = scoring.scoreIncrement
local TICK_INTERVAL = scoring.tickInterval

local systemActive = false
local threadRunning = false
local scoringPaused = false
local totalScore = 0
local latestScore = 0
local multiplier = 1
local drifting = false
local lastAngle = 0
local lastDriftTime = 0
local lastMultiplierIncrement = 0
local multiplierPercent = 0

local uiInfo = {}
local uiDirty = true

---@param vehicle number
---@return number
local function getDriftAngle(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local vx, vy = velocity.x, velocity.y
    local speed = msqrt(vx * vx + vy * vy)
    if speed < 5.0 then return 0 end

    local forward = GetEntityForwardVector(vehicle)
    local dot = mmax(-1.0, mmin(1.0, (forward.x * vx + forward.y * vy) / speed))
    local degrees = mdeg(macos(dot))
    if degrees > 120 then return 0 end
    return mfloor(degrees)
end

local function bankLatestScore()
    if HOLD_CURRENT_UNTIL_RESET then
        totalScore = totalScore + latestScore * multiplier
    end
    latestScore = 0
    multiplier = 1
    multiplierPercent = 0
end

---@param ped number
---@param vehicle number
---@param now number
local function processDriftTick(ped, vehicle, now)
    if scoringPaused then return end

    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        drifting = false
        return
    end

    if GetEntitySpeed(vehicle) * 2.237 <= MIN_DRIFT_SPEED then
        bankLatestScore()
        drifting = false
        return
    end

    local angle = getDriftAngle(vehicle)
    lastAngle = angle

    if angle >= DRIFT_THRESHOLD then
        if not drifting then
            drifting = true
            lastMultiplierIncrement = now
        end

        local scoreToAdd = mfloor(SCORE_INCREMENT * (angle / 90) * (HOLD_CURRENT_UNTIL_RESET and 1 or multiplier))
        if not HOLD_CURRENT_UNTIL_RESET then
            totalScore = totalScore + scoreToAdd
        end
        latestScore = latestScore + scoreToAdd
        lastDriftTime = now

        local sinceIncrement = now - lastMultiplierIncrement
        multiplierPercent = mmin(100, sinceIncrement / MULTIPLIER_INCREMENT_TIME * 100)
        if sinceIncrement >= MULTIPLIER_INCREMENT_TIME and multiplier < MULTIPLIER_MAX then
            multiplier = multiplier + 1
            lastMultiplierIncrement = now
        end
    else
        drifting = false
        multiplierPercent = 0
    end

    if now - lastDriftTime >= MULTIPLIER_TIMER then
        bankLatestScore()
    end
end

local function pushDriftUi()
    if not systemActive then return end
    if not uiDirty
        and uiInfo.score == totalScore
        and uiInfo.multiplier == multiplier
        and uiInfo.latestDriftScore == latestScore
        and uiInfo.isDrifting == drifting
        and uiInfo.driftAngle == lastAngle
        and uiInfo.scoringIsPaused == scoringPaused
        and uiInfo.multiplierPercent == multiplierPercent then
        return
    end
    uiDirty = false
    uiInfo.score = totalScore
    uiInfo.multiplier = multiplier
    uiInfo.latestDriftScore = latestScore
    uiInfo.isDrifting = drifting
    uiInfo.driftAngle = lastAngle
    uiInfo.scoringIsPaused = scoringPaused
    uiInfo.multiplierPercent = multiplierPercent
    UpdateDriftUi(uiInfo)
end

local function startDriftThread()
    if threadRunning then return end
    threadRunning = true
    CreateThread(function()
        while systemActive do
            Wait(TICK_INTERVAL)
            local ped = PlayerPedId()
            processDriftTick(ped, GetVehiclePedIsIn(ped, false), GetGameTimer())
            pushDriftUi()
        end
        threadRunning = false
    end)
end

local function resetDriftSystem()
    totalScore = 0
    latestScore = 0
    multiplier = 1
    multiplierPercent = 0
    drifting = false
    lastDriftTime = 0
    scoringPaused = false
    uiDirty = true
    pushDriftUi()
end

---@param enable boolean
---@return boolean
local function setDriftSystem(enable)
    systemActive = enable
    if enable then
        resetDriftSystem()
        startDriftThread()
    else
        drifting = false
        multiplier = 1
    end
    return systemActive
end

function ForceDriftScore()
    if HOLD_CURRENT_UNTIL_RESET then
        totalScore = totalScore + latestScore * multiplier
    end
end

---@return number
function GetCurrentDriftScore()
    return totalScore
end

---@return boolean
function StartDriftSystem()
    ToggleDriftHud(true)
    return setDriftSystem(true)
end

---@return boolean
function StopDriftSystem()
    ToggleDriftHud(false)
    return setDriftSystem(false)
end

function PauseDriftScoring()
    scoringPaused = true
end

---@return boolean
function DriftIsActive()
    return systemActive
end

---@param score number?
local function setTotalDriftScore(score)
    totalScore = tonumber(score) or 0
    uiDirty = true
end

local function showDriftCountdown(raceId, seconds)
    SendNUIMessage({
        action = "update",
        type = "drift_countdown",
        data = { raceId = raceId, seconds = seconds },
        active = true
    })
end

RegisterNetEvent('sm_racingtablet:client:forceSetDriftScore', function(driftScore)
    DebugLog('^4Received forceSetDriftScore event with score:^0', driftScore)
    setTotalDriftScore(driftScore)
end)

local function finalizeDriftRace(raceId)
        if not DriftLocal.localFinished and CurrentRaceData and CurrentRaceData.RaceId == raceId then
            DriftLocal.localFinished = true
        end
    end
RegisterNetEvent('sm_racingtablet:client:driftFinishCountdown', function(raceId, countdown)
    if not raceId then return end
    if DriftLocal.countdownActive[raceId] then return end
    DriftLocal.countdownActive[raceId] = true
    DriftLocal.localFinished = DriftLocal.localFinished or false

    if not countdown then 
        finalizeDriftRace(raceId)
        return
    end


    showDriftCountdown(raceId, countdown)

    CreateThread(function()
        local t = countdown
        while t > 0 do
            Wait(1000)
            t = t - 1
            showDriftCountdown(raceId, t)
        end

        finalizeDriftRace(raceId)
        
        DriftLocal.countdownActive[raceId] = nil
        showDriftCountdown(raceId, -1)
    end)
end)

RegisterNetEvent('sm_racingtablet:client:driftRaceFinished', function(raceId, results)
    if CurrentRaceData and CurrentRaceData.RaceId == raceId then
        local top = results and results[1] and results[1].RacerName or "?"
        SendNUIMessage({
            action = "update",
            type = "drift_results",
            data = { raceId = raceId, results = results },
            active = true
        })
    end
    DriftLocal.localFinished = false
    DriftLocal.countdownActive[raceId] = nil
end)
