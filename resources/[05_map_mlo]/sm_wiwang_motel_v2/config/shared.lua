local config = {}

config.doorlock = {
    doorModel = `v_ilev_j2_door`,
    defaultLocked = true,
    interactDistance = 1.5,
    maxSetStateDistance = 2.0,
    scanDistance = 2.0,
}

config.motelJob = 'smmotel'

config.permissions = {
    bossBypass = true,

    ---@type table<string, number|string>
    actions = {
        setRoomPrice = 0,
        forceCheckout = 3,
        manageSelfService = 'boss',
        doorlockBypass = 1,
        storageBypass = 1,
    },
}

config.management = {
    roomBasePrice = 450,
    invoiceTimeout = 60,
    checkoutCron = 4, -- dalam menit
    checkoutHour = 17, -- jam checkout pada tanggal checkout, waktu server (WIB)
    roomsPerFloor = 12,
    billingResource = 'sm_resource_1', -- resource pemilik export sm_billing:createPaidInvoice
    floorPrices = {
        [1] = 450,
        [2] = 650,
        [3] = 850,
        [4] = 750,
        [5] = 750,
        [6] = 750,
        [7] = 750,
        [8] = 750,
        [9] = 750,
        [10] = 950,
        [11] = 950,
        [12] = 950,
        [13] = 950,
        [14] = 950,
        [15] = 1200,
        [16] = 1200,
        [17] = 1200,
        [18] = 1200,
        [19] = 1200,
        [20] = 1200,
    },
    customRoomPrices = {
        -- Override by floor and room number.
        -- [1] = {
        --     [1] = 600,
        --     [2] = 550,
        -- },
    },
}

config.room = {
    interactDistance = 1.5,

    -- Kapasitas stash kamar, berat dalam kilogram. Nilai teratas dipakai
    -- sebagai default, lalu bisa ditimpa per lantai dan per kamar.
    storage = {
        slots = 50,
        weight = 1000,

        floors = {
            [1] = { weight = 1000 },
            [2] = { weight = 2000 },
            [3] = { slots = 100, weight = 3000 },
        },

        -- [floor] = { [roomNumber] = { slots, weight } }
        rooms = {
            -- [1] = {
            --     [1] = { slots = 80, weight = 2500 },
            -- },
        },
    },

    -- Jumlah penghuni kamar, sudah termasuk penyewa utama.
    occupants = {
        max = 2,
        extraPrice = 250, -- per penghuni tambahan per hari

        floors = {
            -- [2] = 3,
        },

        -- [floor] = { [roomNumber] = max }
        rooms = {
            -- [1] = {
            --     [1] = 4,
            -- },
        },
    },
}

config.self_service = {
    dailyPrice = 1500,
    maxRentalDays = 30,
    statusRefreshInterval = 15000,

    ped = {
        model = 'cs_milton',
        coords = vector4(-818.3506, -694.5779, 28.0616, 91.1764),
    }
}

return config
