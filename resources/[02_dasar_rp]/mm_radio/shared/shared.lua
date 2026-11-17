---@type number
Shared.MaxFrequency = 900.00 -- Max Limit of Radio Channel

---@class Jammer
---@field state boolean
---@field model string
---@field permission string[]
---@field default table
---@field range table

---@type Jammer
Shared.Jammer = {
    state = false, -- to use jammer system or not 
    model = 'sm_prop_smug_jammer', -- prop to spawn for jammer
    permission = {"police"}, -- permission how can setup jammer (job/gang)
    default = {}, -- default jammer setup location 
    range = {
        min = 10.0,
        max = 100.0,
        step = 5.0,
        default = 30.0
    }
}

---@type string[]
Shared.RadioItem = {
    'radio'
}

---@class Battery
---@field state boolean
---@field consume number
---@field depletionTime number

---@type Battery
Shared.Battery = {
    state = false, -- to use battery system or not
    consume = 1, -- battery consume rate
    depletionTime = 1, -- in minute, every 1 minute battery will decrease by consume value
}

---@type [string]: string
Shared.RadioNames = {
    ["1"] = "Radio Gabungan Polisi", -- channel value 1
    ["1.%"] = "SMPD CH#1", -- channel value 1.%%%% string formatter
    ["2"] = "Radio Gabungan EMS",
    ["2.%"] = "EMS CH#2",
    ["3"] = "Radio Gabungan Gov",
    ["3.%"] = "GOV CH#3",
    ["4"] = "Pengadilan CH#4",
    ["4.%"] = "Pengadilan CH#4",
    ["5"] = "Resto CH#5",
    ["5.%"] = "Resto CH#5",
    ["6"] = "Tekno CH#6",
    ["6.%"] = "Tekno CH#6",
    ["8"] = "DOJ-USMS CH#8",
    ["8.%"] = "DOJ-USMS CH#8",
    ["9"] = "Up-n Atom CH#9",
    ["9.%"] = "Up-n Atom CH#9",
    ["10"] = "RS Roxwood CH#10",
    ["10.%"] = "RS Roxwood CH#10",
    ["11"] = "Mercenary CH#11",
    ["11.%"] = "Mercenary CH#11",
    ["13"] = "Satu Media CH#13",
    ["13.%"] = "Satu Media CH#13",
    ["14"] = "Ananta Garage CH#13",
    ["14.%"] = "Ananta Garage CH#13",
    ["104"] = "SMGO Taxi CH#104",
    ["104.%"] = "SMGO Taxi CH#104",
    -- ["7"] = "MRPD CH#7",
    -- ["7.%"] = "MRPD CH#7",
    -- ["8"] = "MRPD CH#8",
    -- ["8.%"] = "MRPD CH#8",
    -- ["9"] = "MRPD CH#9",
    -- ["9.%"] = "MRPD CH#9",
    -- ["10"] = "MRPD CH#10",
    -- ["10.%"] = "MRPD CH#10",
    -- ["420"] = "Ballas CH#1",
    -- ["420.%"] = "Ballas CH#1",
    -- ["421"] = "LostMC CH#1",
    -- ["421.%"] = "LostMC CH#1",
    -- ["422"] = "Vagos CH#1",
    -- ["422.%"] = "Vagos CH#1",
}

Shared.RestrictedChannels = {
    [1] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "police", "ambulance", "puskesmas", "government", "paspampres", "usmarshal", "pengadilan", "mercenarysm"}
    },
    [2] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "police", "ambulance", "puskesmas", "rsroxwood", "banmeskota", "government", "paspampres", "usmarshal", "pengadilan", "mercenarysm"}
    },
    [3] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "police", "ambulance", "puskesmas", "government", "paspampres", "usmarshal", "pengadilan"}
    },
    [4] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "pengadilan",'usmarshal' , "mercenarysm"}
    },
    [5] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "resto"}
    },
    [6] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "mechanic"}
    },
    [7] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "puskesmas", "ambulance"}
    },
    [8] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "government", "paspampres", "usmarshal", "pengadilan", "police", "ambulance", "mercenarysm"}
    },
    [9] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "pdcafe"}
    },
    [10] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "rsroxwood", "ambulance", "puskesmas","pabrik"}
    },
    [11] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "mercenarysm", "paspampres", "usmarshal", "police", "ambulance"}
    },
    [13] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "reporter"}
    },
    -- [14] = { -- channel id
    --     type = 'job', -- job/gang
    --     name = {"mechanicbay"}
    -- },
    [17] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "digitalden"}
    },
    [104] = { -- channel id
        type = 'job', -- job/gang
        name = {"admin", "taxism"}
    },
    -- [7] = { -- channel id
    --     type = 'job', -- job/gang
    --     name = {"police", "ambulance"}
    -- },
    -- [8] = { -- channel id
    --     type = 'job', -- job/gang
    --     name = {"police", "ambulance"}
    -- },
    -- [9] = { -- channel id
    --     type = 'job', -- job/gang
    --     name = {"police", "ambulance"}
    -- },
    -- [10] = { -- channel id
    --     type = 'job', -- job/gang
    --     name = {"police", "ambulance"}
    -- },
    -- [420] = { -- channel id
    --     type = 'gang', -- job/gang
    --     name = {"ballas"}
    -- },
    -- [421] = { -- channel id
    --     type = 'gang', -- job/gang
    --     name = {"lostmc"}
    -- },
    -- [422] = {
    --     type = 'gang', -- job/gang
    --     name = {"vagos"}
    -- },
}

lib.locale()