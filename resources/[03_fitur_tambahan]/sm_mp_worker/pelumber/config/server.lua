return {
    debug = false,
    startCooldownSeconds = 5,
    validation = {
        objectDistance = 10.0,
        startDistance = 10.0,
        vehicleReturnDistance = 25.0,
    },
    vehicle = {
        model = 'tolboru',
        platePrefix = 'PLUMB',
        spawnCoords = {
            vec(-307.0211, -1194.5771, 24.1241, 2.3961),
        }
    },
    reward = {
        moneyType = 'cash',
        moneyPerMember = 30000,
        items = {
            enabled = true,
            mode = 'weightedPool',
            pool = {
                { item = 'satemaranggi', count = 1, chance = 50 },
                { item = 'esjeruk',    count = 1, chance = 30 },
                { item = 'bandage',  count = 1, chance = 100 },
            },
        },
    },
}
