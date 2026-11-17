---@class GpsJammerConfig
---@field item string
---@field jobs table<string, true> job target yang GPS-nya bisa dihancurkan
---@field targetDistance number
---@field maxDistance number jarak maksimal dicek server
---@field duration integer ms progress penghancuran setelah minigame
---@field timeout integer ms batas proses sejak mulai sebelum dianggap batal
---@field cooldown integer ms jeda per pelaku
---@field skillCheck { difficulty: table, inputs: string[] }
---@field anim { dict: string, clip: string }

---@type GpsJammerConfig
return {
    item = 'gps_jmmr',
    jobs = { police = true, government = true, paspampres = true, usmarshal = true, pengadilan = true },
    targetDistance = 1.5,
    maxDistance = 3.0,
    duration = 8000,
    timeout = 60000,
    cooldown = 5000,
    skillCheck = {
        difficulty = { 'easy', 'easy', 'medium' },
        inputs = { 'w', 'a', 's', 'd' },
    },
    anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
}
