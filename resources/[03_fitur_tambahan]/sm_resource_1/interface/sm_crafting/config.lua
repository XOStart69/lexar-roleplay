---@class CraftingAnimation
---@field dict string
---@field anim string

---@class CraftingSpawnTable
---@field coords vector4
---@field prop string
---@field skipPlaceObjectOnGroundProperly? boolean

---@class CraftingTable
---@field title string
---@field icon? string
---@field animation? CraftingAnimation
---@field jobs? table<string, integer|integer[]> job => grade minimal, atau daftar grade
---@field publicAccess? boolean semua pemain boleh pakai
---@field locations? vector3[] titik ox_target box zone
---@field spawnTable? CraftingSpawnTable[] prop yang di-spawn lalu di-target

---@class CraftingRecipe
---@field label? string default = label item hasil
---@field category string
---@field toItems table<string, integer|integer[]> item => jumlah, atau { min, max }
---@field toItemsMeta? table<string, table> metadata tetap per item hasil
---@field materials table<string, integer>
---@field craftingTime? integer ms per batch
---@field maxCraft? integer batch maksimal sekali craft
---@field tables string[]
---@field jobs? table<string, integer|integer[]>
---@field package? boolean resep paket: waktu sekali per batch, bahan basi ditolak, isi + label kustom disimpan di box dan keluar lagi saat dibuka
---@field key string diisi otomatis
---@field output? string diisi otomatis, item hasil kalau cuma satu

---@class CraftingCustomMenu
---@field editors table<string, integer[]> job => grade yang boleh ganti nama & gambar menu
---@field labelLength { min: integer, max: integer }
---@field imageHosts string[] host https yang diizinkan untuk gambar menu
---@field imageExtensions string[]
---@field saveCooldown integer ms jeda antar simpan per pemain

---@class CraftingConfig
---@field data string[] nama file di folder data/, satu file per job atau kategori
---@field defaultCraftingTime integer
---@field defaultMaxCraft integer
---@field defaultIcon string
---@field defaultAnimation CraftingAnimation
---@field targetDistance number
---@field zoneSize vector3
---@field interactDistance number jarak maksimal pemain ke meja, dicek server
---@field timeTolerance integer ms toleransi lag saat server cek durasi crafting
---@field customMenu CraftingCustomMenu

---@type CraftingConfig
return {
    data = {
        'burgenkcafe',
        'elektronik',
        'gokudosm',
        'gzcafe',
        'hightable',
        'kkpresto',
        'luxurynightclub',
        'medis',
        'mekanik',
        'mhcafe',
        'narkoba',
        'nightclub',
        'pdcafe',
        'resto',
        'robbery',
        'senjata',
    },

    defaultCraftingTime = 1000,
    defaultMaxCraft = 10,
    defaultIcon = 'fas fa-tools',
    defaultAnimation = { dict = 'anim@amb@business@coc@coc_unpack_cut@', anim = 'fullcut_cycle_v7_cokecutter' },
    targetDistance = 2.0,
    zoneSize = vec3(1.5, 1.5, 1.5),
    interactDistance = 5.0,
    timeTolerance = 1500,

    customMenu = {
        editors = {
            resto = { 3, 4 },
            kkpresto = { 3, 4 },
            gzcafe = { 3, 4 },
            mhcafe = { 3, 4 },
            burgenkcafe = { 4, 5, 6, 7 },
            pdcafe = { 3, 4 },
            admin = { 0 },
            ambulance = { 3, 4, 5, 6, 7, 8, 9, 10, 11 },
            rsroxwood = { 3, 4, 5, 6, 7, 8, 9, 10, 11 },
        },
        labelLength = { min = 3, max = 32 },
        imageHosts = {
            'r2.fivemanage.com',
            'i.fmfile.com',
            'i.imgur.com',
            'media.discordapp.net',
            'cdn.discordapp.com',
        },
        imageExtensions = { 'png', 'jpg', 'jpeg', 'webp', 'gif' },
        saveCooldown = 3000,
    },
}
