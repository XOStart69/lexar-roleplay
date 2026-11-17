local DRAWABLE = {
    head = 0,
    hair = 2,
    masks = 1,
    hands = 3,
    pants = 4,
    bags = 5,
    shoes = 6,
    scarfAndChains = 7,
    shirts = 8,
    bodyArmor = 9,
    decals = 10,
    jackets = 11,
}

local PROPS = {
    hats = 0,
    glasses = 1,
    ear = 2,
    watches = 6,
    bracelets = 7
}

local default = {}

default.ped = {
    'np_f_character_select',
    'np_m_character_select'
}

default.components = {
    male = {
        {texture = 0, drawable = 5, component_id = DRAWABLE.shoes},
        {texture = 0, drawable = 662, component_id = DRAWABLE.pants},
        {texture = 0, drawable = 15, component_id = DRAWABLE.shirts},
        {texture = 0, drawable = 1923, component_id = DRAWABLE.jackets},
        {texture = 0, drawable = 0, component_id = DRAWABLE.hands},
    },
    female = {
        {texture = 0, drawable = 477, component_id = DRAWABLE.shoes},
        {texture = 0, drawable = 207, component_id = DRAWABLE.pants},
        {texture = 0, drawable = 19, component_id = DRAWABLE.shirts},
        {texture = 1, drawable = 2311, component_id = DRAWABLE.jackets},
        {texture = 0, drawable = 14, component_id = DRAWABLE.hands},
    }
}

default.appearance = {
    {
        model = `mp_m_freemode_01`,
        components = default.components.male,
    },
    {
        model = `mp_f_freemode_01`,
        components = default.components.female,
    }
}

return default
