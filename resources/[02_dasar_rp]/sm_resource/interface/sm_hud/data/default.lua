
local DEFAULT_SETTINGS = {
    statusColors = {
        hunger = '#f97316',
        thirst = '#3b82f6',
        stress = '#8b1a3a',
        stamina = '#22c55e',
        swimStamina = '#06b6d4',
        gymLevel = '#a855f7',
    },
    statusShape = 'hexagon',
    statusVisibility = {
        hunger = { mode = 'always', threshold = 95, direction = 'below' },
        thirst = { mode = 'always', threshold = 95, direction = 'below' },
        stress = { mode = 'always', threshold = 5,  direction = 'above' },
        stamina = { mode = 'threshold', threshold = 95, direction = 'below' },
        swimStamina = { mode = 'threshold', threshold = 95, direction = 'below' },
        gymLevel    = { mode = 'threshold', threshold = 5,  direction = 'above' },
    },
    healthColor = '#00ccc9',
    armorColor = '#F0F7FA',
    speedometerColor = '#ffffff',
    cinematicMode = false,
    speedometerType = 'aggressive',
    compassMode = 'inVehicle',
    mapState = 'show',
    minimapPosition = { x = 0.008, y = 0.021 },
    navigator = {
        enabled = false,
        showOnFoot = false,
        missionRoute = true,
        priority = 'waypoint',
        preset = '501',
        color = '#2aa6b9d9',
        missionColor = '#ffd640d9',
        turnHighlight = true,
        turnColor = '#ff8c00e6',
        animated = true,
        width = 1.7,
        spacing = 1.0,
        lift = 0.3,
        distance = 200,
        marker = true,
        autoClear = true,
        panel = true,
    },
}

local DEFAULT_POSITIONS = {
    information = { x = 0, y = 0 },
    status = { x = 0, y = 0 },
    healthArmor = { x = 0, y = 0 },
    speedometer = { x = 0, y = 0 },
    aviation = { x = 0, y = 0 },
    voice = { x = 0, y = 0 },
    compass = { x = 0, y = 0 },
    ammo = { x = 0, y = 0 },
    navigation = { x = 0, y = 0 },
}

local DEFAULT_VISIBILITY = {
    information = true,
    status = true,
    healthArmor = true,
    speedometer = true,
    aviation = true,
    voice = true,
    compass = true,
    ammo = true,
    navigation = true,
}

local WEAPON_AMMO_BY_HASH = {}
for name, data in pairs(require '@ox_inventory/data/weapons'.Weapons) do
    local hash = joaat(name)
    if data.ammoname then
        WEAPON_AMMO_BY_HASH[hash] = data.ammoname
    end
end

return {
    DEFAULT_SETTINGS = DEFAULT_SETTINGS,
    DEFAULT_POSITIONS = DEFAULT_POSITIONS,
    DEFAULT_VISIBILITY = DEFAULT_VISIBILITY,
    WEAPON_AMMO_BY_HASH = WEAPON_AMMO_BY_HASH,
}