Config = {}

Config.Currency = 'bank'
Config.NotificationTime = 5000
Config.MaxInteractDistance = 3.0

Config.RentalLocations = {
    {
        coords = vector3(-273.5670, -934.6107, 31.2198),
        stashType = 'stash_1',
        label = 'Kota'
    },
    {
        coords = vector3(146.92, 6366.71, 31.53),
        stashType = 'stash_2',
        label = 'Paleto'
    },
    {
        coords = vector3(906.45, 3654.6, 32.8),
        stashType = 'stash_3',
        label = 'Sandy Shores'
    },
    {
        coords = vector3(-2547.921631, 7472.544434, 29.038366),
        stashType = 'stash_4',
        label = 'Roxwood'
    },
}

Config.VipStashLocations = {
    {
        coords = vector3(-269.6, -962.65, 31.05),
        label = 'VIP/VVIP Eksklusif (Kota)'
    },
    {
        coords = vector3(94.497025, 6355.382324, 31.642056),
        label = 'VIP/VVIP Eksklusif (Paleto)'
    },
    {
        coords = vector3(905.799927, 3585.902344, 33.672497),
        label = 'VIP/VVIP Eksklusif (Sandy Shores)'
    }
}

Config.StashTypes = {
    ['stash_1'] = {
        label = 'Gudang Kota',
        weight = 500000,
        slots = 100,
        pricePerDay = 5000,
        minDays = 1,
        maxDays = 30,
        maxTotalDays = 30
    },
    ['stash_2'] = {
        label = 'Gudang Paleto',
        weight = 500000,
        slots = 100,
        pricePerDay = 5000,
        minDays = 1,
        maxDays = 30,
        maxTotalDays = 30
    },
    ['stash_3'] = {
        label = 'Gudang Sandy Shores',
        weight = 500000,
        slots = 100,
        pricePerDay = 5000,
        minDays = 1,
        maxDays = 30,
        maxTotalDays = 30
    },
    ['stash_4'] = {
        label = 'Gudang Roxwood',
        weight = 500000,
        slots = 100,
        pricePerDay = 5000,
        minDays = 1,
        maxDays = 30,
        maxTotalDays = 30
    },
    ['vip_stash'] = {
        label = 'Gudang VVIP1',
        weight = 15000000,
        slots = 100,
        requiresVip = 'vvip'
    },
    ['vvip_stash'] = {
        label = 'Gudang VVIP2',
        weight = 15000000,
        slots = 200,
        requiresVip = 'vvip'
    }
}
