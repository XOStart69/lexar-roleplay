---@class MenuConfig
---@field default table
---@field newCharacter table
return {
    --- Which sections the editor offers. Shops and commands narrow or widen this per session.
    default = {
        ped = false,
        headBlend = false,
        faceFeatures = false,
        headOverlays = false,
        components = false,
        componentConfig = {
            masks = true,
            upperBody = true,
            lowerBody = true,
            bags = true,
            shoes = true,
            scarfAndChains = true,
            bodyArmor = true,
            shirts = true,
            decals = true,
            jackets = true
        },
        props = false,
        propConfig = {
            hats = true,
            glasses = true,
            ear = true,
            watches = true,
            bracelets = true
        },
        tattoos = false,

        --- Outfits ride along with clothing, so this only has to be set to offer them on their own.
        outfits = false,

        --- Opened with /appearanceadmin, never bundled into a normal or ped menu.
        admin = false,

        enableExit = true,
        hasTracker = false
    },

    newCharacter = {
        --- Hide the player while they build their character. Only granted to someone with nothing saved.
        routingBucket = true,

        --- Time to walk somewhere presentable before the editor opens. Set to 0 to open straight away.
        countdown = 10000,

        --[[
            Merged over the default above, so only the differences belong here. Exit is off so a new
            character cannot be left without an appearance.
        ]]
        menu = {
            ped = true,
            headBlend = true,
            faceFeatures = true,
            headOverlays = true,
            components = true,
            props = true,
            tattoos = true,
            enableExit = false,
            hasTracker = false
        },

        --- What the ped wears before the editor opens.
        clothes = {
            male = {
                model = `mp_m_freemode_01`,
                headOverlays = {
                    beard = {color = 0, style = 0, secondColor = 0, opacity = 1},
                    complexion = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    bodyBlemishes = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    blush = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    lipstick = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    blemishes = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    eyebrows = {color = 0, style = 0, secondColor = 0, opacity = 1},
                    makeUp = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    sunDamage = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    moleAndFreckles = {color = 0, style = 0, secondColor = 0, opacity = 0},
                    chestHair = {color = 0, style = 0, secondColor = 0, opacity = 1},
                    ageing = {color = 0, style = 0, secondColor = 0, opacity = 1},
                },
                components = {
                    {texture = 0, drawable = 0, component_id = 3},
                    {texture = 0, drawable = 15, component_id = 8},
                    {texture = 0, drawable = 1515, component_id = 11},
                    {texture = 0, drawable = 662, component_id = 4},
                    {texture = 0, drawable = 5, component_id = 6}
                },
                props = {
                    {prop_id = 0, drawable = -1, texture = -1},
                    {prop_id = 1, drawable = -1, texture = -1},
                    {prop_id = 2, drawable = -1, texture = -1},
                    {prop_id = 6, drawable = -1, texture = -1},
                    {prop_id = 7, drawable = -1, texture = -1},
                }
            },
            female = {
                model = `mp_f_freemode_01`,
                headBlend = {
                    shapeMix = 0.3,
                    skinFirst = 0,
                    shapeFirst = 31,
                    skinSecond = 0,
                    shapeSecond = 0,
                    skinMix = 0,
                    thirdMix = 0,
                    shapeThird = 0,
                    skinThird = 0,
                },
                hair = {
                    color = 0,
                    style = 15,
                    texture = 0,
                    highlight = 0
                },
                headOverlays = {
                    chestHair = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    bodyBlemishes = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    beard = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    lipstick = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    complexion = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    blemishes = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    moleAndFreckles = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    makeUp = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    ageing = {secondColor = 0, opacity = 1, color = 0, style = 0},
                    eyebrows = {secondColor = 0, opacity = 1, color = 0, style = 0},
                    blush = {secondColor = 0, opacity = 0, color = 0, style = 0},
                    sunDamage = {secondColor = 0, opacity = 0, color = 0, style = 0},
                },
                components = {
                    {prop_id = 0, drawable = -1, texture = -1},
                    {prop_id = 1, drawable = -1, texture = -1},
                    {prop_id = 2, drawable = -1, texture = -1},
                    {prop_id = 6, drawable = -1, texture = -1},
                    {prop_id = 7, drawable = -1, texture = -1},
                },
                props = {
                    {prop_id = 0, drawable = -1, texture = -1},
                    {prop_id = 1, drawable = -1, texture = -1},
                    {prop_id = 2, drawable = -1, texture = -1},
                    {prop_id = 6, drawable = -1, texture = -1},
                    {prop_id = 7, drawable = -1, texture = -1},
                }
            }
        }
    }
}
