---@class JobBlipConfig
---@field siren boolean Allow this job to use siren blip override
---@field color number Blip color
---@field shared table<string, boolean> Other jobs that can see this blip
---@field gps? boolean Blip sprite follows movement mode (foot/car/speed/heli/plane/boat), overrides siren sprite

return {
    Settings = {
        updateInterval = 5000,
        maxVisibleMembers = 150,
        showSelfBlip = true,

        gps = {
            sprites = {
                foot = 1,
                car = 56,
                speed = 523,
                heli = 43,
                plane = 307,
                boat = 427
            },
            speedModels = {
                'npolstang',
                'npolchal',
                'npolchar',
                'npolvette'
            }
        },

        siren = {
            enabled = true,
            sprite = 42,
            scale = 0.5,
            color = false,
            checkInterval = 500
        },

        mock = {
            enabled = false,
            instance = '__mock',
            color = 5,
            command = 'jobblip_mock',
            clearCommand = 'jobblip_mock_clear',
            defaultCount = 500,
            spread = 1500.0,
            moving = true,
            moveStep = 8.0,
            sprite = 1
        },

        toggleBlip = {
            items = {
                badgedetective     = { police = true },
                badgeshc           = { police = true },
                badgeiodusms         = { usmarshal = true },
                badgehighcommandusms = { usmarshal = true },
                roxwoodcard        = { gokudosm = true }
            },
            notifications = {
                notAllowed = "Anda tidak dapat menggunakan item ini!",
                deactivated = "Blip duty dinonaktifkan.",
                activated = "Blip duty diaktifkan."
            }
        }
    },

    Jobs = {
        police = {
            siren = true,
            gps = true,
            color = 26,
            updateInterval = 3000,
            shared = {
                usmarshal = true,
            }
        },
        smmotel = {
            siren = false,
            color = 47,
            shared = {}
        },
        bcso = {
            siren = true,
            color = 26,
            shared = {
                police = true,
            }
        },
        ambulance = {
            siren = true,
            color = 1,
            updateInterval = 3000,
            shared = {
                banmeskota = true,
                police = true,
            }
        },
        paud = {
            siren = false,
            color = 8,
            shared = {}
        },
        sksm = {
            siren = false,
            color = 8,
            shared = {}
        },
        taxism = {
            siren = false,
            color = 30,
            shared = {}
        },
        mechanic = {
            siren = false,
            color = 2,
            shared = {}
        },
        kkpgarage = {
            siren = false,
            color = 2,
            shared = {}
        },
        stunberg = {
            siren = false,
            color = 2,
            shared = {}
        },
        mechanic969 = {
            siren = false,
            color = 2,
            shared = {}
        },
        maxspeedgarage = {
            siren = false,
            color = 2,
            shared = {}
        },
        pabrik = {
            siren = false,
            color = 47,
            shared = {}
        },
        resto = {
            siren = false,
            color = 71,
            shared = {}
        },
        gzcafe = {
            siren = false,
            color = 71,
            shared = {}
        },
        mhcafe = {
            siren = false,
            color = 71,
            shared = {}
        },
        mercenarysm = {
            siren = false,
            color = 47,
            shared = {}
        },
        kkpresto = {
            siren = false,
            color = 71,
            shared = {}
        },
        pdcafe = {
            siren = false,
            color = 71,
            shared = {}
        },
        burgenkcafe = {
            siren = false,
            color = 71,
            shared = {}
        },
        luxurynightclub = {
            siren = false,
            color = 10,
            shared = {}
        },
        government = {
            siren = false,
            color = 78,
            updateInterval = 3000,
            shared = {
                paspampres = true,
            }
        },
        paspampres = {
            siren = false,
            color = 78,
            shared = {
                government = true,
            }
        },
        hightable = {
            siren = false,
            color = 78,
            updateInterval = 3000,
            shared = {}
        },
        reporter = {
            siren = false,
            color = 78,
            shared = {}
        },
        pengadilan = {
            siren = false,
            color = 39,
            updateInterval = 3000,
            shared = {
                usmarshal = true,
            }
        },
        usmarshal = {
            siren = false,
            gps = true,
            color = 25,
            updateInterval = 3000,
            shared = {
                pengadilan = true,
                police = true,
            }
        },
        digitalden = {
            siren = false,
            color = 59,
            shared = {}
        },
        wartelsm = {
            siren = false,
            color = 59,
            shared = {}
        },
        nightclub = {
            siren = false,
            color = 10,
            shared = {}
        },
        banmeskota = {
            siren = true,
            color = 1,
            shared = {
                ambulance = true,
                police = true,
            }
        },
        rsroxwood = {
            siren = true,
            color = 1,
            shared = {}
        },
        gokudosm = {
            siren = false,
            color = 40,
            shared = {}
        },
        velvetsm = {
            siren = false,
            color = 3,
            shared = {}
        }
    }
}
