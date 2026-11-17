return {
    requiredJob = {
        basic = {
            police = 6,
            ems = 4
        },
        blaneCounty = {
            police = 7,
            ems = 4
        },
        pacificBank = {
            police = 10,
            ems = 5
        }
    },
    cooldown = {
        basic = {
            time = 30,
            unit = 'menit',
        },
        blaneCounty = {
            time = 120,
            unit = 'menit',
        },
        pacificBank = {
            time = 720,
            unit = 'menit',
        }
    },
    robberyLimit = {
        basic = {
            max = 2,
            time = 60,
            unit = 'menit',
        },
    },
    rewards = {
        basic = {
            trolley = {
                item = 'black_money',
                amount = 1155950,
                delay = 120000, -- 2 minutes per trolley
            },
            deposit_box = {
                -- Lucky/zonk system: laptop_malware chance, zonk = silver_bar or gold_bar
                lucky = {
                    item = 'laptop_malware',
                    max = 2,
                    chance = 25,
                },
                zonk = {
                    { item = 'silver_bar', amount = 1 },
                    { item = 'goldbar', amount = 1 },
                }
            }
        },
        blaneCounty = {
            trolley = {
                item = 'black_money',
                amount = 1712800
            },
            drill = {
                item = 'goldbar',
                amount = 2
            },
            -- Center table: lucky/zonk
            centerTable = {
                lucky = {
                    item = 'laptop_gold',
                    max = 2,
                    chance = 20, -- sulit
                },
                zonk = {
                    { item = 'diamond', amount = 1 },
                }
            }
        },
        pacificBank = {
            trolley = {
                item = 'black_money',
                amount = 2875000
            },
            -- Center table rewards
            centerTable = {
                rewards = {
                    { item = 'ruby', amount = 1 },
                    { item = 'emerald', amount = 1 },
                }
            }
        }
    }
}