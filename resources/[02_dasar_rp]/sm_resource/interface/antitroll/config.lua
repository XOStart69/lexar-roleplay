local cfg = {}

cfg.AdminCommand = "troll" -- The Name of the Admin Command
cfg.Rang = "admin"         -- The Rang needed for the Admin Command

cfg.HowLong = 4320         -- How Long the Player should have antitroll on
cfg.TimeToSave = 5         -- How often the time should be saved in the Database

-- SETTING FOR PLAYERS WITH ANTITROLL ON
cfg.DisableShooting = true      -- Disables Shooting
cfg.DisablePunching = false       -- Disables hitting for players still in troll protect mode

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

cfg.AllowedSteamIDs = { 
    "steam:110000111be9ce4", -- axon      
    "steam:11000015b1c84a5", -- mr
    "steam:11000010920f95d", -- gokong
    "steam:11000014a6055be", --lopez
    'steam:1100001472e423c', -- 'rhd'
    'steam:11000015a9f7938', -- 'piyoyo'
    'steam:110000144100102', -- 'arva'
}

cfg.offlinePerms = {
    "steam:110000111be9ce4", --axon
    "steam:11000014a6055be", --lopez
    "steam:11000010c31bac7", --matto
    'steam:1100001472e423c', -- 'rhd'
    'steam:11000015a9f7938', -- 'piyoyo'
    'steam:110000144100102', -- 'arva'
}

return cfg