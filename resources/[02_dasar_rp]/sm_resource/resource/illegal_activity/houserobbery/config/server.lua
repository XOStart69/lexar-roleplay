return {
    -- Police requirements
    requiredJob = {
        police = 3,
        ems = 2
    },
    notEnoughCopsNotify = true,

    -- Lockpick mechanics
    chanceOfBreakingLockpickOnSucess = 20,
    chanceOfSilentAlarmOnSucess = 20,
    chanceOfTriggerAlarmOnFail = 50,

    -- House reset timing
    timeToResetHouse = 1440000,

    --waktu info rumah di robbery
    timeToReserveHouse = 600000,

    -- Experience system
    levels = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    },

    -- Experience gained per house tier
    gainXp = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    },

    -- Loot reward pools
    rewards = {
        -- Pool 1: Black Money
        {
            items = { 'black_money' },
            togive = { min = 1, max = 1 },
            toget = { min = 30000, max = 30000 },
            isGuaranteed = true,
            guaranteedType = 'single'
        },

        -- Pool 2: Gun Handle 5-10
        {
            items = { 'gunhandle' },
            togive = { min = 1, max = 1 },
            toget = { min = 7, max = 20 },
            isGuaranteed = true,
            guaranteedType = 'single'
        },

        -- Pool 3: Rolling Paper 70-100
        {
            items = { 'rolling_paper' },
            togive = { min = 1, max = 1 },
            toget = { min = 70, max = 100 },
            isGuaranteed = false,
            guaranteedType = 'multiple'
        }
    }
}
