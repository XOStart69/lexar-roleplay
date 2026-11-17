return {
    NotificationType = "native",

    ReopenRadarAfterLeave = true,

    AutoEnable = true,

    ShowNotification = function(message)
    end,

    AllowedVehicleModels = {
        Enable = true,
        Models = {
            "police",
            "police2",
            "pbike",
            "klxpolice",

            "polbuffalor",
            "polcarar",
            "polcoquetter",
            "polscoutr",
            "polthrust",
            "polbuffalor2",

            "polbikeb",
            "polalamor2",
            "poldmntr",
            "polmesa",
            "poltorencer",
            "npolmm",
            "polgauntletg",

            "smlaren",
            "lspdraiden",
            "poldmntr2",
            "polumkmesa",
            "polgresleyr",
            "h2rmotor",

            "pitbullbb",
            "riot",
            "npolstang",
            "npolchar",
            "npolchal",
            "npolvette",
            "npolexp",
            "npolvic",
            "police3",
            "policet",
            "fbi",
        }
    },

    Keybinds = {
        ToggleRadar = "F6",
        Interact = "F7",
        SaveReading = "J",
        LockRadar = "F9",
        LockSpeed = "N",
        LockPlate = "M",
        ToggleLog = "F10",
        ToggleBolo = "F11",
        ToggleKeybinds = "F12",
        SpeedLockThreshold = nil,
        MoveRadar = nil,
        MoveLog = nil,
        MoveBolo = nil,
    },

    LedGlow = true,
    SpeedUnit = "KMH",
    UpdateInterval = 200,
    MaxDetectionRange = 200.0,
    PlateDetectionRange = 50.0,

    AllowedJobs = {
        Enable = true,
        Jobs = {
            "police"
        }
    },
}