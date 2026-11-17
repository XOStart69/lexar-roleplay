---@class DeathCause
---@field reason string
---@field all_regions DamageKind?
---@field fallback BodyRegion?

local causes = {
    {
        reason = 'Tertabrak kendaraan',
        weapons = { `WEAPON_RUN_OVER_BY_CAR`, `WEAPON_RAMMED_BY_CAR` },
    },
    {
        reason = 'Gigitan hewan',
        weapons = { `WEAPON_ANIMAL`, `WEAPON_COUGAR` },
    },
    {
        reason = 'Cedera akibat terjatuh',
        weapons = { `WEAPON_FALL` },
    },
    {
        reason = 'Ledakan',
        all_regions = 'burn',
        weapons = {
            `WEAPON_EXPLOSION`,
            `WEAPON_GRENADE`,
            `WEAPON_GRENADELAUNCHER`,
            `WEAPON_GRENADELAUNCHER_SMOKE`,
            `WEAPON_SMOKEGRENADE`,
            `WEAPON_STICKYBOMB`,
            `WEAPON_PIPEBOMB`,
            `WEAPON_PROXMINE`,
            `WEAPON_RPG`,
            `WEAPON_PASSENGER_ROCKET`,
            `WEAPON_AIRSTRIKE_ROCKET`,
            `WEAPON_VEHICLE_ROCKET`,
            `WEAPON_HELI_CRASH`,
            1752584910,
        },
    },
    {
        reason = 'Luka bakar',
        all_regions = 'burn',
        weapons = { `WEAPON_MOLOTOV`, `WEAPON_PETROLCAN`, `WEAPON_FIRE` },
    },
    {
        reason = 'Tenggelam',
        fallback = 'chest',
        weapons = { `WEAPON_DROWNING`, `WEAPON_DROWNING_IN_VEHICLE` },
    },
}

---@type table<integer, DeathCause>
local lookup = {}

for i = 1, #causes do
    local cause = causes[i]
    local weapons = cause.weapons
    cause.weapons = nil

    for j = 1, #weapons do
        lookup[weapons[j]] = cause
    end
end

return lookup
