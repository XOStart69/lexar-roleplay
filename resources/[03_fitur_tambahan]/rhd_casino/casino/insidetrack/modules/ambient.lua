local Ambient = {}
local NUMBER_WORDS <const> = { 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX' }
local PLACE_WORDS  <const> = { 'FIRST', 'SECOND', 'THIRD', 'FOURTH', 'FIFTH', 'LAST' }
local state = {
    bankLoaded = false,
    bankRequested = false,
    mainRaceSoundId = -1,
    lastMinAnnounced = -1,
    countdownAnnounced = false,
    podiumThreadActive = false,
}
local config = require 'casino.insidetrack.config'
local function getMainEventCoord()
    return (config.BigScreen and config.BigScreen.coords)
        or vector3(952.17804, 85.37027, 70.032761)
end

local function speechCoord(isMain)
    if isMain then return getMainEventCoord() end
    return GetEntityCoords(cache.ped)
end

function Ambient.loadBank()
    if state.bankLoaded or state.bankRequested then return end
    state.bankRequested = true
    state.bankLoaded = pcall(lib.requestAudioBank, config.AudioBank, 1500)
    state.bankRequested = false
end

function Ambient.releaseBank()
    if state.bankLoaded then
        ReleaseNamedScriptAudioBank(config.AudioBank)
        state.bankLoaded = false
    end
    state.bankRequested = false
end

---@return boolean
function Ambient.isBankLoaded()
    return state.bankLoaded
end

---@param speech string
---@param pos vector3?
function Ambient.playAnnouncer(speech, pos)
    if not speech then return end
    pos = pos or GetEntityCoords(cache.ped)
    PlayAmbientSpeechFromPositionNative(
        speech,
        config.AnnouncerVoice or 'CAS_HORSE_ANNOUNCER',
        pos.x, pos.y, pos.z,
        'SPEECH_PARAMS_FORCE'
    )
end

---@param speech string
---@param isMain boolean?
function Ambient.announceCustom(speech, isMain)
    Ambient.playAnnouncer(speech, speechCoord(isMain))
end

---@param horseId number
---@param isMain  boolean?
function Ambient.announceFinalWinner(horseId, isMain)
    if not horseId then return end
    local nameId = config.HorseSpeechIds and config.HorseSpeechIds[horseId]
    if not nameId then return end
    local prefixes <const> = {
        'MINIGAME_TRACK_FIRST_PLACE_',
        'MINIGAME_TRACK_CLOSE_FINISH_',
        'MINIGAME_TRACK_LEAD_',
    }
    local prefix = prefixes[math.random(1, #prefixes)]
    Ambient.playAnnouncer(prefix .. nameId, speechCoord(isMain))
end

---@param horseId number 1-6
---@param place number 1-6
---@param isFinal boolean?
---@param isMain  boolean?
function Ambient.announcePlace(horseId, place, isFinal, isMain)
    if not horseId or not place then return end
    if horseId < 1 or horseId > 6 then return end
    if place   < 1 or place   > 6 then return end
    local prefix = isFinal and 'MINIGAME_TRACK_FINISH_' or 'MINIGAME_TRACK_'
    local speech = prefix .. PLACE_WORDS[place] .. '_PLACE_' .. NUMBER_WORDS[horseId]
    Ambient.playAnnouncer(speech, speechCoord(isMain))
end

function Ambient.startMainRaceLoop()
    Ambient.stopMainRaceLoop()
    state.mainRaceSoundId = GetSoundId()
    local pos = getMainEventCoord()
    PlaySoundFromCoord(
        state.mainRaceSoundId,
        config.RaceSound or 'race_loop',
        pos.x, pos.y, pos.z,
        config.RaceMainAudioBank or 'dlc_vw_casino_inside_track_betting_main_event_sounds',
        false, 13, false
    )
end

function Ambient.stopMainRaceLoop()
    if state.mainRaceSoundId ~= -1 then
        StopSound(state.mainRaceSoundId)
        ReleaseSoundId(state.mainRaceSoundId)
        state.mainRaceSoundId = -1
    end
end

---@param raceOrder integer[]
---@param isMain boolean?
---@param getActive fun():boolean
function Ambient.spawnRaceAnnouncer(raceOrder, isMain, getActive)
    CreateThread(function()
        local duration = config.RaceDuration or 30000
        local startedAt = GetGameTimer()
        Ambient.announceCustom('MINIGAME_TRACK_RACE_START', isMain)
        local halfwayAt = startedAt + math.floor(duration / 2)
        local nearEndAt = startedAt + math.max(duration - 5000, 0)
        local endAt = startedAt + duration
        local placeAt1 = startedAt + 4000
        local placeAt2 = startedAt + math.floor(duration * 0.65)
        local saidHalf, saidNear = false, false
        local saidPlace1, saidPlace2 = false, false
        while true do
            if getActive and not getActive() then break end
            local now = GetGameTimer()
            if now >= endAt then break end
            if not saidPlace1 and now >= placeAt1 and raceOrder and raceOrder[1] then
                saidPlace1 = true
                Ambient.announcePlace(raceOrder[1], 1, false, isMain)
            elseif not saidHalf and now >= halfwayAt then
                saidHalf = true
                Ambient.announceCustom('MINIGAME_TRACK_HALFWAY', isMain)
            elseif not saidPlace2 and now >= placeAt2 and raceOrder and raceOrder[2] then
                saidPlace2 = true
                Ambient.announcePlace(raceOrder[2], 2, false, isMain)
            elseif not saidNear and now >= nearEndAt then
                saidNear = true
                Ambient.announceCustom('MINIGAME_TRACK_FINISH_NEAR', isMain)
            end
            Wait(500)
        end
    end)
end

---@param raceOrder integer[]
---@param winnerSlot number?
---@param isPhaseOk fun():boolean
function Ambient.spawnPodiumAnnounce(raceOrder, winnerSlot, isPhaseOk)
    if state.podiumThreadActive then return end
    state.podiumThreadActive = true
    CreateThread(function()
        if winnerSlot and raceOrder and raceOrder[1] then
            Ambient.announceFinalWinner(raceOrder[1], true)
        end
        for place = 1, 3 do
            if isPhaseOk and not isPhaseOk() then break end
            local horseId = raceOrder and raceOrder[place]
            if horseId then
                Ambient.announcePlace(horseId, place, true, true)
            end
            Wait(4000)
        end
        state.podiumThreadActive = false
    end)
end

function Ambient.tickCountdown(timer)
    if not timer or timer <= 0 then return end
    local minsLeft = math.floor(timer / 60) + 1
    if minsLeft >= 1 and minsLeft <= 5 and state.lastMinAnnounced ~= minsLeft then
        state.lastMinAnnounced = minsLeft
        Ambient.announceCustom('MINIGAME_TRACK_' .. minsLeft .. 'MIN', true)
    end
    if timer == 10 and not state.countdownAnnounced then
        state.countdownAnnounced = true
        Ambient.announceCustom('MINIGAME_TRACK_COUNTDOWN', true)
    end
end

function Ambient.resetRoundState()
    state.lastMinAnnounced = -1
    state.countdownAnnounced = false
end
return Ambient
