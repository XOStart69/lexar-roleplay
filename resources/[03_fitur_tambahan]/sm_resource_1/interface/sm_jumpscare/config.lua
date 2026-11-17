---@class JumpscareSound
---@field value string nama file di interact-sound/client/html/sounds tanpa .ogg
---@field label string

---@class JumpscareConfig
---@field command string
---@field jobs table<string, integer|integer[]> job => grade minimal yang boleh pakai command
---@field ace string|false kalau diisi, izin pakai ACE ini dan `jobs` diabaikan
---@field sounds JumpscareSound[]
---@field soundVolume number
---@field displayDuration integer ms gambar tampil
---@field loadTimeout integer ms batas tunggu gambar dimuat
---@field maxDistance number 0 = tanpa batas
---@field cooldown integer detik jeda per pengirim
---@field maxUrlLength integer

---@type JumpscareConfig
return {
    command = 'jumpscare',
    jobs = { admin = 0 },
    ace = false,
    sounds = {
        { value = 'yeet', label = 'Jumpscare Sound 1' },
        { value = 'jumpscare', label = 'Jumpscare Sound 2' },
    },
    soundVolume = 1.0,
    displayDuration = 5000,
    loadTimeout = 5000,
    maxDistance = 0,
    cooldown = 10,
    maxUrlLength = 500,
}
