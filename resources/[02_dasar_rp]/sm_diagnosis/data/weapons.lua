-- ox_inventory tidak menyimpan jenis senjata, jadi yang tajam dan yang membakar harus didaftarkan sendiri.
local blades = {
    WEAPON_AXE = true,
    WEAPON_BATTLEAXE = true,
    WEAPON_BOTTLE = true,
    WEAPON_DAGGER = true,
    WEAPON_HATCHET = true,
    WEAPON_KARAMBIT = true,
    WEAPON_KATANA = true,
    WEAPON_KNIFE = true,
    WEAPON_MACHETE = true,
    WEAPON_SHIV = true,
    WEAPON_STONE_HATCHET = true,
    WEAPON_SWITCHBLADE = true,
}

local burns = {
    WEAPON_COMPACTLAUNCHER = true,
    WEAPON_FIREWORK = true,
    WEAPON_FLARE = true,
    WEAPON_FLAREGUN = true,
    WEAPON_GRENADE = true,
    WEAPON_GRENADELAUNCHER = true,
    WEAPON_HOMINGLAUNCHER = true,
    WEAPON_MOLOTOV = true,
    WEAPON_PETROLCAN = true,
    WEAPON_PIPEBOMB = true,
    WEAPON_PROXMINE = true,
    WEAPON_RPG = true,
    WEAPON_STICKYBOMB = true,
}

local ox_weapons = require '@ox_inventory.data.weapons'.Weapons

-- Sumber damage yang bukan item, jadi tidak akan pernah ada di ox_inventory.
---@type table<integer, DamageKind>
local weapons = {
    [`WEAPON_UNARMED`] = 'bruise',
    [`WEAPON_FALL`] = 'bruise',
    [`WEAPON_RUN_OVER_BY_CAR`] = 'bruise',
    [`WEAPON_RAMMED_BY_CAR`] = 'bruise',
    [`WEAPON_HELI_CRASH`] = 'bruise',
    [`WEAPON_ANIMAL`] = 'bruise',
    [`WEAPON_COUGAR`] = 'bruise',
    [`WEAPON_DROWNING`] = 'bruise',
    [`WEAPON_DROWNING_IN_VEHICLE`] = 'bruise',
    [`WEAPON_EXPLOSION`] = 'burn',
    [`WEAPON_FIRE`] = 'burn',
}

for model, data in pairs(ox_weapons) do
    local kind = 'bruise'

    if burns[model] then
        kind = 'burn'
    elseif blades[model] then
        kind = 'cut'
    elseif data.ammoname then
        kind = 'shot'
    end

    weapons[joaat(model)] = kind
end

return weapons
