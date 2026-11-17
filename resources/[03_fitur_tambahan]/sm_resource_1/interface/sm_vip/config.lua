local Config = {}

Config.Webhook = ""

Config.VipNPC = {
    coords = vector4(-269.01, -955.65, 31.22, 216.54),
    model = 'a_m_m_business_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.AdminCommand = 'vipmanager'

Config.AdminGroups = {
    'god',
    'admin'
}

Config.VipTypes = {
    vvip = {
        label = 'VVIP',
        duration = 30 * 24 * 60 * 60 * 1000
    }
}

Config.VipVehicles = {
    enabled = true,
    garage = "Garasi Kota",
    vvip = {
        enabled = true,
        vehicles = {
            {
                model = 'vv1',
                label = 'CHEV COLORADO',
                description = 'Kendaraan exclusive'
            },
            {
                model = 'vv2',
                label = 'LAMB FENOMENO',
                description = 'Kendaraan exclusive'
            },
            {
                model = 'vv3',
                label = 'WMB M3',
                description = 'Kendaraan exclusive'
            }
        }
    }
}

Config.DailyItems = {
    enabled = true,
    vvip = {
        enabled = true,
        items = {
            {
                name = 'satemaranggi',
                amount = 5,
                label = 'Sate Maranggi',
                description = 'Sate khas Indonesia yang lezat'
            },
            {
                name = 'esjeruk',
                amount = 5,
                label = 'Es Jeruk',
                description = 'Minuman segar dari jeruk asli'
            },
            {
                name = 'bandage',
                amount = 10,
                label = 'Bandage',
                description = 'Perban untuk pertolongan pertama'
            }
        }
    }
}

Config.TVRemote = {
    enabled = true,
    vvip = {
        enabled = true,
        item = {
            name = 'tvremote',
            amount = 1,
            label = 'TV Remote',
            description = 'Remote control untuk TV (Hanya bisa di-claim 1x per periode VIP)'
        }
    }
}

return Config
