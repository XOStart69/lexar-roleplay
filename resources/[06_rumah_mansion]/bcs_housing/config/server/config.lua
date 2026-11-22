local function CV(k, d) if GetConVar then return GetConVar(k, d) end return d end
-- Konfigurasi khusus server. Dimuat setelah config/*.lua oleh shared_scripts.
Config = Config or {}

Config.Server = {
    ace = 'housing.admin',
    debug = false,
    saveInterval = 300,
    maxHomesPerPlayer = Config.LimitHouses or 0,
    keyItem = Config.KeyAsItem and Config.KeyAsItem.ItemName or 'house_key',
    defaultAccount = Config.DefaultAccount or 'bank',
    lockOnExit = Config.AutoLock == true,
    revokeGraceDays = Config.RevokeOwnerAfterExpiry or 2,
    inactivityDays = Config.RevokeOwnerAfterInactivity or 14,

    upgradeLimits = {
        keys = Config.Upgrades and Config.Upgrades.keys.max or 10,
        storage = Config.Upgrades and Config.Upgrades.storage.max or 20,
        wardrobes = Config.Upgrades and Config.Upgrades.wardrobes.max or 10,
        garages = Config.Upgrades and Config.Upgrades.garages.max or 10,
    },

    tax = {
        enable = Config.tax and Config.tax.enable or false,
        account = Config.tax and Config.tax.account or 'bank',
        society = Config.tax and Config.tax.society or 'government',
        percentage = Config.tax and Config.tax.percentage or 0.1,
    },

    rent = {
        checkTimer = Config.rent and Config.rent.rentCheckTimer or '*/10 * * * *',
        account = Config.rent and Config.rent.paymentAccount or 'bank',
        autoPayment = Config.rent and Config.rent.autoPayment or false,
        autoPaymentAccount = Config.rent and Config.rent.autoPaymentAccount or 'bank',
        deleteAfterAutoRemove = Config.rent and Config.rent.deleteAfterAutoRemove or false,
        allowNegative = Config.rent and Config.rent.allowNegative == true,
    },

    mortgage = {
        checkTimer = Config.mortgage and Config.mortgage.checkTimer or '0 * * * *',
        weeks = Config.mortgage and Config.mortgage.weeks or 7,
        months = Config.mortgage and Config.mortgage.months or 30,
        account = Config.mortgage and Config.mortgage.paymentAccount or 'bank',
        autoPayment = Config.mortgage and Config.mortgage.autoPayment or false,
        autoPaymentAccount = Config.mortgage and Config.mortgage.autoPaymentAccount or 'bank',
        removeAfter = Config.mortgage and Config.mortgage.removeAfter or 7,
        returnMoneyAfterRemoval = Config.mortgage and Config.mortgage.returnMoneyAfterRemoval or false,
        deleteAfterAutoRemove = Config.mortgage and Config.mortgage.deleteAfterAutoRemove or false,
        allowEditOnGoing = Config.mortgage and Config.mortgage.allowEditOnGoing or false,
    },

    log = {
        enabled = true,
        webhook = '',
        events = {
            create = true, delete = true, transfer = true, sell = true,
            buy = true, rent = true, evict = true, lockpick = true,
            enter = false, exit = false, storage = true, upgrade = true,
        },
    },

    screenshot = {
        provider = Config.Screenshot or 'offline',
        folder = 'html/images',
        token = CV('SCREENSHOT_TOKEN', ''),
        webhook = CV('SCREENSHOT_WEBHOOK', ''),
        imageServer = CV('IMAGE_SERVER', ''),
        apiKey = CV('fivehub:apiKey', ''),
    },

    tables = {
        homes = 'housing_homes',
        doors = 'housing_doors',
        garages = 'housing_garages',
        teleports = 'housing_teleports',
        storages = 'housing_storages',
        wardrobes = 'housing_wardrobes',
        furniture = 'housing_furniture',
        keys = 'housing_keys',
        apartments = 'housing_apartments',
        mortgages = 'housing_mortgages',
        logs = 'housing_logs',
        catalogues = 'housing_catalogues',
        bills = 'housing_bills',
        starter = 'housing_starter_apartments',
        presets = 'housing_area_presets',
    },

    permissions = {
        'doorlock', 'garage', 'wardrobe', 'storage',
        'furniture', 'sell', 'transfer', 'moveGarage', 'rename',
    },

    allowedComplex = { Individual = true, Apartment = true, Flat = true, Public = true },
    allowedType = { mlo = true, shell = true, ipl = true, mlo_teleport = true },

    starterApartment = {
        enabled = Config.UseStarterApartment == true,
        deleteOnBuy = Config.DeleteStarterApartment == true,
        identifier = 'starter_apartment',
        name = 'Starter Apartment',
        price = 0,
    },
}

Server = Config.Server

