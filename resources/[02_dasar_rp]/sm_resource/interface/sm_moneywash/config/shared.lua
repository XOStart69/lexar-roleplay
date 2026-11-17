---@class MoneyWashExchange
---@field label string
---@field fromItem string
---@field toItem string
---@field rate number

---@class MoneyWashJob
---@field name string
---@field minGrade number

---@class MoneyWashLocation
---@field label string
---@field coords vector3
---@field radius number
---@field distance? number
---@field isPublic? boolean
---@field job? string
---@field minGrade? number
---@field jobs? MoneyWashJob[]
---@field allowedExchanges string[]
---@field rateOverrides? table<string, number>
---@field maxPerWash? number
---@field maxPerPlayer? number
---@field washDuration? number

return {
    DurationPerMillion = 20000,
    MaxWashDuration = 45000,
    MinAmount = 1,
    UseDistance = 5.0,

    Exchanges = {
        blackToRed = {
            label = 'Black Money → Red Money',
            fromItem = 'black_money',
            toItem = 'red_money',
            rate = 1.0,
        },
        redToWhite = {
            label = 'Red Money → Uang Putih',
            fromItem = 'red_money',
            toItem = 'money',
            rate = 0.8,
        },
        whiteToRed = {
            label = 'Uang Putih → Red Money',
            fromItem = 'money',
            toItem = 'red_money',
            rate = 1.2,
        },
    },

    ---@type MoneyWashLocation[]
    Locations = {
        {
            label = 'High Table',
            coords = vector3(891.896545, -3196.350342, -98.039597),
            radius = 2.0,
            job = 'hightable',
            minGrade = 8,
            allowedExchanges = { 'blackToRed', 'redToWhite', 'whiteToRed' },
            rateOverrides = { blackToRed = 1.0, redToWhite = 1.0, whiteToRed = 1.0 },
        },
        {
            label = 'Abyss',
            coords = vector3(1811.539673, -2324.892578, 130.919189),
            radius = 2.0,
            job = 'abyssm',
            minGrade = 2,
            allowedExchanges = { 'blackToRed', 'redToWhite' },
            rateOverrides = { blackToRed = 0.9 },
        },
        {
            label = 'RYC',
            coords = vector3(-1877.39, -309.60, 49.78),
            radius = 2.0,
            job = 'rcsm',
            minGrade = 4,
            allowedExchanges = { 'blackToRed', 'redToWhite' },
            rateOverrides = { blackToRed = 0.9 },
        },
        {
            label = 'Snake Flower',
            coords = vec3(27.442591, 330.454163, 110.818024),
            radius = 2.0,
            job = 'snakeflowersm',
            minGrade = 4,
            allowedExchanges = { 'blackToRed', 'redToWhite' },
            rateOverrides = { blackToRed = 0.9 },
        },
        {
            label = 'Gokudo',
            coords = vec3(-1408.3104, 7694.7319, 2.2508),
            radius = 0.6,
            distance = 1.5,
            job = 'gokudosm',
            minGrade = 5,
            allowedExchanges = { 'blackToRed', 'redToWhite' },
            rateOverrides = { blackToRed = 1.0, redToWhite = 1.0 },
        },
        -- {
        --     label = 'BLF',
        --     coords = vector3(-3690.75, 3771.5, 4.5),
        --     radius = 2.0,
        --     job = 'blfsm',
        --     minGrade = 2,
        --     allowedExchanges = { 'blackToRed', 'redToWhite' },
        --     rateOverrides = { blackToRed = 0.9 },
        -- },
        {
            label = 'Sandy Shores',
            coords = vector3(2484.6985, 3718.7161, 43.4669),
            radius = 2.0,
            isPublic = true,
            allowedExchanges = { 'blackToRed' },
            rateOverrides = { blackToRed = 0.6 },
            maxPerWash = 500000,
            maxPerPlayer = 3000000,
            washDuration = 60000,
        },
    },
}
