local cfg = {}

cfg.AdminCommand = "troll" -- Nama command admin
cfg.Rang = "admin"         -- Ace yang boleh memakai command (selain AllowedSteamIDs)

cfg.HowLong = 4320         -- Lama proteksi antitroll diberikan (menit). 4320 = 3 hari
cfg.TimeToSave = 5         -- Interval penyimpanan sisa waktu ke database (detik)

-- Pengaturan untuk pemain yang sedang dalam mode proteksi
cfg.DisableShooting = true  -- Matikan tembak-menembak
cfg.DisablePunching = false -- Matikan pukulan

-- Senjata yang tetap boleh dipakai walau proteksi aktif (mis. senjata kerja)
cfg.WhitelistedWeapons = {
    "weapon_machete",
    "weapon_wrench",
    "weapon_crowbar",
    "weapon_sledgehammer",
    "weapon_hatchet",
    "WEAPON_FLASHLIGHT",
    "WEAPON_NIGHTSTICK",
    "WEAPON_STUNGUN",
    "WEAPON_RADARGUN",
}

-- Steam hex yang boleh menjalankan /troll ke pemain ONLINE.
-- Memberi proteksi antitroll + notifikasi durasi ke target.
cfg.AllowedSteamIDs = {
    'steam:11000010d39c66e', -- owner
}

-- Steam hex yang boleh memberi proteksi ke pemain OFFLINE (dicari lewat identifier).
-- Dipakai saat target belum login supaya proteksinya tetap terpasang saat dia masuk.
cfg.offlinePerms = {
    'steam:11000010d39c66e', -- owner
}

return cfg