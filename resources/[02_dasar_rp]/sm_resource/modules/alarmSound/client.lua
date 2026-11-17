-- local SOUND_LIST = {
--     'GENERAL_MISSION_ALARM_01',
--     'GENERAL_MISSION_ALARM_02',
--     'GENERAL_MISSION_ALARM_03',
--     'POLICE_STATION_ALARM',
--     'PRISON_ALARM',
--     'FACILITY_ALARM',
--     'PALETO_BAY_SCORE_ALARM',
--     'PALETO_SCORE_ALARM',
--     'JEWEL_STORE_ALARM',
--     'PORT_OF_LS_HEIST_FORT_ZANCUDO_ALARM',
--     'JEWELLERY_ALARM',
--     'ALARM_KLAXON_01',
--     'ALARM_KLAXON_02',
--     'ALARM_KLAXON_03',
--     'KLAXON_01',
-- }

-- local activeAlarms = {}

-- ---@class Alarm: OxClass
-- local Alarm = lib.class('Alarm')

-- function Alarm:constructor(data)
--     self.soundId = GetSoundId()
    
--     if self.soundId == -1 then
--         error('Failed to get sound ID')
--         return
--     end

--     self.name = data.name
--     self.audioRef = data.audioRef or ''
--     self.coords = data.coords
--     self.range = data.range or 100
--     self.duration = data.duration

--     pcall(function ()
--         lib.requestAudioBank(self.name, 1500)
--     end)

--     print(self.name, 'sound name')
--     PlaySoundFromCoord(
--         self.soundId, self.name,
--         self.coords.x, self.coords.y, self.coords.z,
--         self.audioRef, false, self.range, false
--     )

--     activeAlarms[self.soundId] = self

--     if self.duration and self.duration > 0 then
--         self.timeoutId = SetTimeout(self.duration, function()
--             self:stop()
--         end)
--     end
-- end

-- function Alarm:stop()
--     if not self.soundId then return end

--     StopSound(self.soundId)
--     ReleaseSoundId(self.soundId)
    
--     if self.timeoutId then
--         ---@diagnostic disable-next-line: undefined-global
--         ClearTimeout(self.timeoutId)
--     end

--     activeAlarms[self.soundId] = nil
--     self.soundId = nil
-- end

-- return Alarm