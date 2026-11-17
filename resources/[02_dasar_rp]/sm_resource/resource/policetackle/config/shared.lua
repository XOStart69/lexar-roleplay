return {
    key = 'E',
    allowedJobs = {
        ['police'] = true,
        ['usmarshal'] = true,
    },
    cooldown = 5000,       -- ms setelah tackle
    tackleRange = 1.0,      -- jarak deteksi tackle (client)
    maxServerRange = 5.0,   -- jarak max validasi server (anti-cheat)
    ragdollDuration = 10000,
    anim = {
        dict = 'anim@sports@ballgame@handball@',
        tackle = 'ball_rstop_r_slide',
        getup = 'ball_get_up',
    },
}